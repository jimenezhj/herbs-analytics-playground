USE AdventureWorks2022;
GO

-- 1. Each product category name and how many products it contains, most first.
--    (4-table chain: Product -> Subcategory -> Category.)

SELECT	pc.name,
		COUNT(p.productid) NumberOfProducts
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name

-- 2. Products that have never been ordered. (Anti-join OR NOT EXISTS — your pick;
--    if you reach for NOT IN, remember the trap from Week 3.)

SELECT	p.name
FROM	Production.Product p
WHERE NOT EXISTS 
				(
				SELECT	1
				FROM	Sales.SalesOrderDetail sod
				WHERE	p.ProductID = sod.ProductID
				)

SELECT TOP 1 * FROM sales.SalesOrderdetail

-- 3. For each subcategory, its single most expensive product (top-1 per group)
--    using a CTE + join-back. (You'll learn the one-line window version this week.)

WITH psc AS 
(
SELECT  ps.ProductSubcategoryID psID,
		ps.name SubcategoryName,
		MAX(p.listprice) MaxPrice
FROM Production.Product p
INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
GROUP BY ps.ProductSubcategoryID, ps.name
)

SELECT	p.name,
		psc.subcategoryname,
		psc.maxprice
FROM	psc
INNER JOIN	Production.Product p ON psc.psID = p.ProductSubcategoryID
	AND		psc.maxprice = p.ListPrice

SELECT COUNT(ProductSubcategoryID)
FROM	Production.Product

-- 4. Total revenue per year (SUM of TotalDue, grouped by YEAR(OrderDate)).

SELECT	YEAR(OrderDate),
		SUM(TotalDue)
FROM	sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)


-- 5. Customers whose total spend exceeds $50,000 — name + total, highest first.

WITH HighSpenders AS
(
SELECT	CustomerID CustomerID,
		SUM(TotalDue) TotalSpend
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) > 50000
)

SELECT	p.firstname,
		p.lastname,
		hs.totalspend TotalSpend
FROM HighSpenders hs
INNER JOIN Sales.Customer c ON hs.customerID = c.CustomerID
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
ORDER BY TotalSpend DESC;

SELECT TOP 1 * FROM sales.customer
SELECT TOP 1 * FROM person.Person


SELECT	productsubcategoryid,
		AVG(listprice) AS avgprice
FROM	Production.Product
WHERE	listprice > 0
GROUP BY ProductSubcategoryID

SELECT	name,
		productsubcategoryid,
		listprice,
		AVG(listprice) OVER (PARTITION BY ProductSubcategoryID) AS AvgInSubCat
FROM	Production.Product
WHERE	listprice > 0

WITH AveragePerCat AS
(
SELECT	productsubcategoryid,
		AVG(listprice) AS avgprice
FROM	Production.Product
WHERE	listprice > 0
GROUP BY ProductSubcategoryID
)

SELECT	p.name,
		p.ProductSubcategoryID,
		p.ListPrice,
		apc.avgprice
FROM	AveragePerCat apc
LEFT JOIN	Production.Product p ON COALESCE(apc.ProductSubcategoryID,0) = COALESCE(p.ProductSubcategoryID,0)
WHERE	listprice > 0;


SELECT	name,
		listprice,
		AVG(listprice) OVER () AS OverallAvg,
		listprice - AVG(listprice) OVER () AS DiffFromOverall
FROM	production.product
WHERE	listprice>0;

SELECT	name,
		productsubcategoryid,
		listprice,
		AVG(listprice) OVER (PARTITION BY productsubcategoryid) AS SubCatAvg
FROM	Production.Product
WHERE	listprice > 0;

SELECT	orderdate,
		totaldue,
		SUM(totaldue) OVER (ORDER BY OrderDate) AS RunningTotal

FROM	sales.SalesOrderHeader
WHERE	YEAR(Orderdate) = 2013
ORDER BY	OrderDate


SELECT  ROW_NUMBER() OVER (ORDER BY Listprice DESC, Name ASC) AS Rank,
		name,
		listprice
FROM	Production.Product
WHERE	listprice > 0

SELECT	productsubcategoryID,
		ROW_NUMBER() OVER (PARTITION BY productsubcategoryID ORDER BY ListPrice DESC) AS Rankinsubcat,
		name,
		listprice
FROM	production.product
WHERE	listprice > 0
ORDER BY	productsubcategoryID, Rankinsubcat



SELECT	productsubcategoryID,
		AVG(listprice) AvgPrice,
		COUNT(*) ProdCount
FROM	production.product
WHERE	listprice > 0
GROUP BY	ProductSubcategoryID

SELECT	p.name,
		p.productsubcategoryID,
		p.listprice,
		(
			SELECT	AVG(p2.listprice)
			FROM	Production.Product p2
			WHERE	p2.ProductSubcategoryID = p.productsubcategoryID
				AND	listprice > 0

		) AS SubcategoryAvg
FROM	Production.product p
WHERE	p.listprice > 0

SELECT	name,
		productsubcategoryid,
		listprice,
		AVG(listprice) OVER (PARTITION BY productsubcategoryid) subcatavg,
		listprice - AVG(listprice) OVER (PARTITION BY productsubcategoryid) difffromavg
FROM	Production.product
WHERE	listprice > 0
ORDER BY	ProductSubcategoryID, listprice DESC;


SELECT	name,
		productsubcategoryid,
		listprice,
		AVG(listprice) OVER () AS Overallavg,
		AVG(listprice) OVER (PARTITION BY productsubcategoryID) AS subcatavg,
		COUNT(*) OVER (PARTITION BY productsubcategoryID) AS #ofprodincat,
		MAX(listprice) OVER (PARTITION BY productsubcategoryID) AS MAXincat
FROM	Production.Product
WHERE	listprice > 0
ORDER BY	ProductSubcategoryID, listprice DESC;

SELECT
    ROW_NUMBER() OVER (ORDER BY TotalDue DESC) AS OverallRank,
    SalesOrderID,
    CustomerID,
    OrderDate,
    TotalDue
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013;

SELECT
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue,
    ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY TotalDue DESC) AS CustomerOrderRank
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013
ORDER BY CustomerID, CustomerOrderRank;


--**🧠 AI-free zone — Self-test (25 min):** No AI:

--1. From `Production.Product`, for each product, show: Name, ListPrice, and the overall average ListPrice (as a column on every row). Filter to ListPrice > 0.

SELECT	name,
		listprice,
		AVG(listprice) OVER () OverallAvg
FROM	Production.Product
WHERE	listprice > 0
ORDER BY ListPrice DESC;


--2. From `Production.Product`, for each product, show: Name, ProductSubcategoryID, ListPrice, the count of products in its subcategory, and the max price in its subcategory.

SELECT	name,
		productsubcategoryID,
		listprice,
		COUNT(productID) OVER (PARTITION BY productsubcategoryID) ProdInCat,
		MAX(listprice) OVER (PARTITION BY productsubcategoryID) MaxPriceInCat
FROM	Production.Product
WHERE	listprice > 0
ORDER BY productsubcategoryID ASC, MaxPriceInCat DESC;

--3. From `Sales.SalesOrderHeader` (2013 only), assign each order a rank from 1 (largest `TotalDue`) downward, across the whole year. Show top 20 by rank.

SELECT	TOP 20
		ROW_NUMBER () OVER (ORDER BY TotalDue DESC) RankId,
		CustomerID,
		TotalDue
FROM	SALES.SalesOrderHeader
WHERE	YEAR(OrderDate) = 2013
ORDER BY	ROW_NUMBER () OVER (ORDER BY TotalDue DESC)
		

--4. From `Sales.SalesOrderHeader` (2013 only), rank each customer's orders from largest to smallest *within each customer*. Show the top 3 orders per customer (ranks 1-3). 
--(Hint: you'll need ROW_NUMBER inside a CTE, then filter where rank <= 3 in the outer query. This "top-N-per-group" pattern is formalized properly tomorrow on Day 2 — today, attempt it from the practice example above; getting it even roughly is the win.)

WITH CustomerRank AS

(
	SELECT	ROW_NUMBER () OVER (PARTITION BY CustomerID ORDER BY TotalDue DESC) RankId,
			CustomerID,
			TotalDue
	FROM	SALES.SalesOrderHeader
	WHERE	YEAR(OrderDate) = 2013
)

SELECT *
FROM	CustomerRank cr
WHERE	cr.RankId <= 3



