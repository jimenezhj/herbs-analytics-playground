-- 1. Each product's ListPrice AND its subcategory's average ListPrice on the
--    same row. (Compare-row-to-group — one line with the right tool.)

WITH totals AS

(
		SELECT	p.productsubcategoryid,
				ps.name AS SubcategoryName,
				AVG(p.listprice) AS AveragePrice		
		FROM	Production.Product p
		INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
		WHERE p.listprice > 0
		GROUP BY	p.ProductSubcategoryID, ps.Name
)
SELECT	p2.name,
		p2.listprice,
		t.SubcategoryName,
		t.AveragePrice AS CategoryAverage
FROM	Production.Product p2
INNER JOIN totals t ON p2.ProductSubcategoryID = t.ProductSubcategoryID;


-- 2. The 3 most expensive products in EACH subcategory. (Top-N per group.)

WITH totals AS

(	
		SELECT	ps.name AS SubcategoryName,
				p.ProductID,
				p.name AS ProductName,
				p.ListPrice AS ListPrice			
		FROM	Production.Product p 
		INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID

)
,subcategoryrankings AS

(
SELECT	ProductName,
		SubcategoryName,
		ListPrice,
		DENSE_RANK () OVER (PARTITION BY SubcategoryName ORDER BY ListPrice DESC) AS Ranking
FROM	totals
)

SELECT	ProductName,
		SubcategoryName,
		ListPrice,
		Ranking
FROM	subcategoryrankings
WHERE	Ranking <= 3

-- 3. Total revenue per year (SUM of TotalDue by YEAR(OrderDate)), plus each
--    year's change vs. the prior year. (Period-over-period.)

WITH totals AS

(
		SELECT	YEAR(OrderDate) AS YEAR,
				SUM(TotalDue) AS REVENUE
		FROM	Sales.SalesOrderHeader
		GROUP BY	YEAR(OrderDate)
)

SELECT	Year,
		Revenue,
		LAG(REVENUE,1,0) OVER (ORDER BY YEAR) AS PYRevenue,
		REVENUE-LAG(REVENUE,1,0) OVER (ORDER BY YEAR) AS ChangeVsPriorYear
FROM	totals


-- 4. Salespeople with NO orders. (Anti-join or NOT EXISTS — not NOT IN.)

SELECT	BusinessEntityID
FROM	person.person hre
WHERE	NOT EXISTS (
				SELECT  1
				FROM	sales.SalesPerson sp
				WHERE	sp.BusinessEntityID = hre.BusinessEntityID)
		AND hre.PersonType = 'SP'


-- 5. Running cumulative revenue by month for 2013, in month order.
--    (Careful with the frame — what did Week 4 teach about ties?)

WITH revenue AS

(
		SELECT	MONTH(OrderDate) AS Month,
				SUM(TotalDue) AS Revenue
		FROM	sales.SalesOrderHeader
		WHERE	OrderDate >= '2013-01-01'
			AND	OrderDate <	'2014-01-01'
		GROUP BY	MONTH(OrderDate)

)

SELECT	Month,
		Revenue,
		SUM(Revenue) OVER (ORDER BY Month, Revenue ROWS UNBOUNDED PRECEDING) AS CumulativeRevenue
FROM	revenue

