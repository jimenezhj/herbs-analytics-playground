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
SELECT	 CustomerID,
		 COUNT(SalesOrderID) AS OrderCount
FROM	 Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING	 COUNT(SalesOrderID) >- 5
ORDER BY OrderCount DESC;

SELECT	 pc.Name			AS Category,
		 AVG(p.ListPrice)	AS AvgListPrice
FROM	 Production.product p
JOIN	 Production.Productsubcategory	psc ON p.ProductSubcategoryID=psc.ProductSubcategoryID
JOIN	 Production.ProductCategory		pc  ON psc.ProductCategoryID=pc.ProductCategoryID
WHERE	 p.listprice > 0
GROUP BY pc.ProductCategoryID, pc.Name
HAVING	 AVG(p.ListPrice) > 500
ORDER BY AvgListPrice;

-- Customers with more than 10 orders (all time)

SELECT		 CustomerID,
			 COUNT(SalesOrderID) AS OrderCount
FROM		 Sales.SalesOrderHeader
GROUP BY	 CustomerID
HAVING		 COUNT(SalesOrderID) > 10
ORDER BY	 OrderCount DESC;

-- High-value individual customers in 2013

SELECT		 soh.CustomerID,
			 CONCAT(p.FirstName,' ',p.LastName)	AS [Customer Name],
			 COUNT(soh.SalesOrderID)			AS [Order Count],
			 SUM(soh.TotalDue)					AS [Total Spent]
FROM		 Sales.SalesOrderHeader soh
JOIN		 Sales.Customer			c	ON soh.CustomerID = c.CustomerID
JOIN		 Person.Person			p	ON c.CustomerID = p.BusinessEntityID
WHERE		 soh.orderdate >= '2013-01-01'
	AND		 soh.orderdate <  '2014-01-01'
	AND		 c.PersonID IS NOT NULL
GROUP BY	 soh.CustomerID, p.FirstName, p.LastName
HAVING		 SUM(soh.totaldue) > 5000
ORDER BY	 [Total Spent] DESC;

-- Product subcategories with high average price and multiple products

SELECT		 psc.Name			AS Subcategory,
			 COUNT(*)			AS ProductCount,
			 AVG(p.listprice)	AS AvgPrice,
			 MAX(p.listprice)   AS MaxPrice
FROM		 Production.Product p
JOIN		 Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
WHERE		 p.ListPrice > 0
GROUP BY	 psc.ProductCategoryID, psc.Name
HAVING		 AVG(p.listPrice) > 800
	AND		 COUNT(*) > 3
ORDER BY	 AvgPrice DESC;

-- Low-lifetime-spend customers (re-engagement candidates)
SELECT		CustomerID,
			COUNT(SalesOrderID) AS OrderCount,
			SUM(TotalDue)		AS Lifetimespend
FROM		Sales.SalesOrderHeader
GROUP BY	CustomerID
HAVING		SUM(TotalDue) < 1000
ORDER BY	Lifetimespend ASC;

-- Territory revenue with compound HAVING
SELECT		st.Name					AS Territory,
			COUNT(soh.SalesOrderID)	AS OrderCount,
			SUM(soh.TotalDue)		AS TotalRevenue,
			AVG(soh.TotalDue)		AS AvgOrderValue
FROM		Sales.SalesOrderHeader	soh
JOIN		Sales.SalesTerritory	st	ON soh.TerritoryID = st.TerritoryID
WHERE		soh.OrderDate >= '2013-01-01'
GROUP BY	st.Name
HAVING		SUM(soh.TotalDue) > 100000
	AND		AVG(soh.TotalDue) > 3000
ORDER BY	TotalRevenue DESC;