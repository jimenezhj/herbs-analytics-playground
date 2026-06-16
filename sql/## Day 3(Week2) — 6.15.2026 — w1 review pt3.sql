USE AdventureWorks2022;
GO

-- 1. The 10 most expensive products — name and list price only.

SELECT		TOP 10 Name,
			listprice
FROM		Production.Product
ORDER BY	listprice DESC;

-- 2. How many products have no color recorded?

SELECT		COUNT(*) AS [Order Count]
FROM		Production.Product
WHERE		Color IS NULL;

-- 3. Per color, the average list price, most expensive color first.
--    (Ignore products with no color.)

SELECT		Color AS [Color],
			AVG(listprice) AS [Avg Listprice]
FROM		Production.Product
WHERE		Color IS NOT NULL
GROUP BY	Color
ORDER BY	[Avg Listprice] DESC;

-- 4. The total number of orders placed in 2013.

SELECT		COUNT(*) AS [Order Count]
FROM		Sales.SalesOrderHeader
WHERE		OrderDate >= '2013-01-01'
	AND		OrderDate <  '2014-01-01';

-- 5. Each TerritoryID and its number of orders, busiest first.

SELECT		TerritoryID,
			COUNT(*) AS [Order Count]
FROM		Sales.SalesOrderHeader
GROUP BY	TerritoryID
ORDER BY	[Order Count] DESC;

-- Without HAVING: show order count per customer

SELECT		CustomerID,
			COUNT(*) AS OrderCount
FROM		Sales.SalesOrderHeader
GROUP BY	CustomerID
ORDER BY	OrderCount DESC;


-- With HAVING: only customers with more than 25 orders
SELECT		CustomerID,
			COUNT(*) AS OrderCount
FROM		Sales.SalesOrderHeader
GROUP BY	CustomerID
HAVING		COUNT(*) > 25
ORDER BY	OrderCount DESC;

-- HAVING on a SUM

SELECT		CustomerID,
			SUM(TotalDue) AS TotalDue
FROM		Sales.SalesOrderHeader
GROUP BY	CustomerID
HAVING		SUM(TotalDue) > 200000
ORDER BY	TotalDue DESC;

-- Combining WHERE and HAVING
-- WHERE filters orders before grouping; HAVING filters customers after grouping

SELECT
	CustomerID,
	COUNT(*) AS OrderCount,
	SUM(Totaldue) AS Totalspend
FROM Sales.SalesOrderHeader
--WHERE OrderDate >= '2013-01-01'
GROUP BY CustomerID
HAVING COUNT(*) > 10
	AND SUM(Totaldue) > 50000
ORDER BY Totalspend DESC;

--1. From `Production.Product`, group by `Color` and show only colors where the average 
--`ListPrice` is over $1000. Show Color, ProductCount, and AvgPrice.

SELECT	Color,
		COUNT(*) AS ProductCount,
		AVG(Listprice) AS AvgPrice
FROM	Production.Product
WHERE	Listprice > 1000
GROUP BY	Color
ORDER BY	AvgPrice DESC;

--2. From `Sales.SalesOrderHeader`, find the years where total revenue exceeded $50 million. 
--Show Year and TotalRevenue. (Hint: `YEAR(OrderDate)`.)

SELECT	YEAR(OrderDate) AS [Year],
		SUM(TotalDue) AS [Total Revenue]
FROM	Sales.SalesOrderHeader
GROUP BY	YEAR(OrderDate)
ORDER BY	Year DESC;

--3. From `Sales.SalesOrderHeader`, find customer IDs where they placed exactly 1 order (one-time customers). 
--Show CustomerID and the single order's TotalDue.

SELECT	CustomerID,
		SUM(TotalDue) AS [Total Revenue]
FROM	Sales.SalesOrderHeader
GROUP BY	CustomerID
HAVING		COUNT(*) = 1
ORDER BY	[Total Revenue] DESC;
		
--4. From `Production.Product`, count products per `ProductLine` and 
--only show product lines with at least 50 products. Sort by count descending.

SELECT	ProductLine,
		COUNT(*) AS [Product Count]
FROM	Production.Product
GROUP BY	ProductLine
HAVING	COUNT(*) >= 50
ORDER BY	[Product Count] DESC;

--5. From `Sales.SalesOrderHeader`, group by `TerritoryID` and show territories where the average order value (`AVG(TotalDue)`) is above $5000. 
--Sort by average descending.

SELECT	TerritoryID,
		AVG(TotalDue) AS AverageOrderValue
FROM	Sales.SalesOrderHeader
GROUP BY	TerritoryID
HAVING	AVG(TotalDue) > 5000
ORDER BY	AverageOrderValue DESC;