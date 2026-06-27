SELECT
	name,
	listprice,
	CASE	
		WHEN listprice >= 2000 THEN 'premium'
		WHEN listprice >= 500 THEN 'mid-range'
		WHEN listprice > 0 THEN 'budget'
		ELSE 'free'
	END AS Pricetier
FROM Production.Product
ORDER BY ListPrice DESC; 
	
SELECT
	salesorderid,
	orderdate,
	totaldue,
	CASE
		WHEN totaldue > 50000 THEN 'y'
		ELSE 'n'
	END AS Highvalueflag
FROM sales.SalesOrderHeader
WHERE YEAR(orderdate) = 2013
ORDER BY TotalDue DESC;

SELECT	customerid,
		COUNT(*) AS totalorders,
		SUM(CASE WHEN YEAR(orderdate) = 2013 THEN 1 ELSE 0 END) AS orders2013,
		SUM(CASE WHEN YEAR(orderdate) = 2014 THEN 1 ELSE 0 END) AS orders2014,
		SUM(CASE WHEN YEAR(orderdate) = 2015 THEN 1 ELSE 0 END) AS orders2015,
		SUM(CASE WHEN YEAR(orderdate) = 2013 THEN totaldue ELSE 0 END) AS rev2013,
		SUM(CASE WHEN YEAR(orderdate) = 2014 THEN totaldue ELSE 0 END) AS rev2014,
		SUM(CASE WHEN YEAR(orderdate) = 2015 THEN totaldue ELSE 0 END) AS rev2015
FROM	sales.salesorderheader
GROUP BY	customerid
ORDER BY	totalorders DESC;

SELECT		name,
			listprice,
			color,
			CASE
				WHEN listprice >= 2000 THEN
					CASE WHEN color = 'black' THEN 'premium black' ELSE 'premium other' END
					ELSE 'standard'
			END AS category
FROM		Production.Product
WHERE		ListPrice > 0;


WITH category AS
(SELECT		ProductID,
			listprice,
			CASE
				WHEN color = 'black' THEN 'premium black' ELSE 'premium other'
			END AS category
 FROM		Production.Product
 WHERE		listprice >=2000
)

SELECT	p.name,
		p.listprice,
		p.color,
		CASE
			WHEN p.listprice < 2000 THEN 'standard' ELSE c.category
		END AS category
FROM	Production.Product p
LEFT JOIN	category AS c ON p.ProductID = c.ProductID
WHERE	p.listprice > 0;

SELECT
    Color,
    CASE Color
        WHEN 'Red' THEN 'Hot color'
        WHEN 'Blue' THEN 'Cool color'
        WHEN 'Black' THEN 'Neutral'
        ELSE 'Other'
    END AS ColorFamily
FROM Production.Product
WHERE Color IS NOT NULL
GROUP BY Color;


SELECT
    totaldue,
    CASE YEAR(orderdate)
        WHEN 2013 THEN 'Hot color'
        WHEN 2014 THEN 'Cool color'
        ELSE 'Other'
    END AS ColorFamily
FROM Sales.SalesOrderHeader

--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. From `Production.Product`, categorize products by weight: 'Heavy' (>= 100), 'Medium' (10-99.99), 'Light' (< 10), 'Unknown' (NULL). Show name, weight, and category for 30 rows.

SELECT TOP 1 * FROM Production.Product ORDER BY WEIGHT DESC

WITH productweight AS
(SELECT productID,
		CASE 
			WHEN weight >= 100 THEN 'heavy'
			WHEN weight <= 99.99 AND weight >= 10 THEN 'medium'
			WHEN weight < 10 THEN 'light'
			WHEN weight IS NULL THEN 'unknown'
		END AS category
 FROM	Production.product)

SELECT	TOP 30
		p.name,
		p.Weight,
		pw.category

FROM	production.Product P
INNER JOIN	productweight pw ON p.ProductID = pw.ProductID



--2. From `Sales.SalesOrderHeader`, do a conditional aggregation: per `TerritoryID`, show counts of orders in 2013, 2014, and 2015 as three separate columns (pivot-style).

SELECT	territoryID,
		SUM(CASE WHEN YEAR(orderdate) = 2013 THEN 1 ELSE 0 END) AS Ordersin2013,
		SUM(CASE WHEN YEAR(orderdate) = 2014 THEN 1 ELSE 0 END) AS Ordersin2014,
		SUM(CASE WHEN YEAR(orderdate) = 2015 THEN 1 ELSE 0 END) AS Ordersin2015
FROM	sales.SalesOrderHeader
GROUP BY TerritoryID

--3. From `Sales.SalesOrderHeader`, create a single query that returns one row with: TotalOrders, OrdersIn2013, OrdersIn2014, OrdersIn2015, Revenue2013, Revenue2014, Revenue2015 — for the entire portfolio. (Hint: no GROUP BY needed since you want one row total. Use conditional aggregation.)

SELECT	COUNT(salesorderid) AS TotalOrders,
		SUM(CASE WHEN YEAR(orderdate) = 2013 THEN 1 ELSE 0 END) AS Ordersin2013,
		SUM(CASE WHEN YEAR(orderdate) = 2014 THEN 1 ELSE 0 END) AS Ordersin2014,
		SUM(CASE WHEN YEAR(orderdate) = 2015 THEN 1 ELSE 0 END) AS Ordersin2015,
		SUM(CASE WHEN YEAR(orderdate) = 2013 THEN totaldue ELSE 0 END) AS revenuein2013,
		SUM(CASE WHEN YEAR(orderdate) = 2014 THEN totaldue ELSE 0 END) AS revenuein2014,
		SUM(CASE WHEN YEAR(orderdate) = 2015 THEN totaldue ELSE 0 END) AS revenuein2015
		
FROM	sales.SalesOrderHeader




--4. From `Production.Product`, bucket products by `(ListPrice / Weight)` ratio — when Weight is non-null and non-zero. Buckets: 'Cheap-per-unit' (<10), 'Average' (10-100), 'Premium' (>100). Show name, listprice, weight, ratio, bucket.

WITH priceweightratio AS
(SELECT	productID,
		CAST(listprice/weight AS decimal (38,2)) AS ratio
 FROM	Production.product
 WHERE	weight IS NOT NULL
 AND	weight > 0
 AND	listprice > 0)

 SELECT p.name,
		p.listprice,
		p.weight,
		pw.ratio,
		CASE
			WHEN pw.ratio > 100 THEN 'premium'
			WHEN pw.ratio <= 100 AND pw.ratio >= 10 THEN 'average'
			WHEN pw.ratio < 10 THEN 'cheap-per-unit'
		END AS bucket
FROM	Production.Product p
INNER JOIN priceweightratio pw ON p.ProductID = pw.productid;


--5. Architect-flavored: Write a query that flags each row in `Sales.SalesOrderHeader` as one of: 'High-Value' (TotalDue > 50000), 'Mid-Value' (1000-50000), 'Low-Value' (< 1000). 
--Then group by the flag and show count + total revenue per flag. (Hint: CTE with the flag in step 1, GROUP BY the flag in step 2 — *or* CASE in the GROUP BY directly, which is also legal.)


WITH flag AS (
SELECT	salesorderID,
		CASE
			WHEN totaldue > 50000 THEN '1-high-value'
			WHEN totaldue <= 50000 AND totaldue >= 1000 THEN '2-mid-value'
			WHEN totaldue < 1000 THEN '3-low-value'
		END AS category
FROM	sales.salesorderheader
)

SELECT  f.category,
		SUM(soh.totaldue) AS TotalRevenue,
		COUNT(soh.salesorderID) AS TotalOrders
FROM	sales.SalesOrderHeader AS soh
INNER JOIN flag f ON soh.SalesOrderID = f.SalesOrderID
GROUP BY f.category
ORDER BY f.category ASC;