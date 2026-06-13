-- Without HAVING: show order count per customer

SELECT
	CustomerID,
	COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY OrderCount DESC;

-- With HAVING: only customers with more than 25 orders
SELECT
	CustomerID,
	COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 25
ORDER BY OrderCount DESC;

-- HAVING on a SUM
SELECT
	CustomerID,
	SUM(TotalDue) AS TotalSpend
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING SUM(TotalDue) > 200000
ORDER BY TotalSpend DESC;

-- Combining WHERE and HAVING
-- WHERE filters orders before grouping; HAVING filters customers after grouping

SELECT 
	CustomerID,
	COUNT(*) AS OrderCount,
	SUM(TotalDue) AS TotalSpend
FROM Sales.SalesOrderHeader
--WHERE OrderDate >= '2013-01-01'
GROUP BY CustomerID
HAVING COUNT(*) > 10
	AND SUM(TotalDue) > 50000
ORDER BY TotalSpend DESC;

--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. From `Production.Product`, group by `Color` and show only colors 
--where the average `ListPrice` is over $1000. Show Color, ProductCount, and AvgPrice.

SELECT 
	Color AS ProductColor,
	COUNT(*) AS OrderCount,
	AVG(ListPrice) AS AvgPrice
FROM Production.Product
WHERE Color IS NOT NULL
GROUP BY Color
HAVING AVG(ListPrice) > 1000;



--2. From `Sales.SalesOrderHeader`, find the years where total revenue exceeded $50 million. 
--Show Year and TotalRevenue. (Hint: `YEAR(OrderDate)`.)

SELECT 
	YEAR(OrderDate) AS OrderYear,
	SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
HAVING SUM(TotalDue) > 50000000;

--3. From `Sales.SalesOrderHeader`, find customer IDs where they placed exactly 1 order (one-time customers). 
--Show CustomerID and the single order's TotalDue.
SELECT
	CustomerID AS CustomerNumber,
	COUNT(*) AS OrderCount,
	SUM(TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) = 1
ORDER BY TotalRevenue DESC;

--4. From `Production.Product`, count products per `ProductLine` and only show product lines with at least 50 products. 
--Sort by count descending.

SELECT
	ProductLine AS ProductLine,
	COUNT(*) AS NumberOfProductLines
FROM Production.Product
GROUP BY ProductLine
HAVING COUNT(*) >= 50
ORDER BY NumberOfProductLines DESC;


--5. From `Sales.SalesOrderHeader`, group by `TerritoryID` and show territories 
--where the average order value (`AVG(TotalDue)`) is above $5000. Sort by average descending.

SELECT
	TerritoryID,
	AVG(Totaldue) AS AVGRevenue
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID
HAVING AVG(Totaldue) > 5000
ORDER BY AVGRevenue DESC;

--additional working samples
SELECT
	CustomerID,
	COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) >=3
ORDER BY OrderCount DESC;

SELECT
	ProductSubcategoryID,
	AVG(ListPrice) AS AVGPrice
FROM Production.Product
GROUP BY ProductSubcategoryID
HAVING AVG(ListPrice) > 50
ORDER BY AVGPrice DESC;
