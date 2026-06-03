--## Day 4 — Wednesday — Aggregates: COUNT, SUM, AVG, MIN, MAX

--**Theory:** Aggregate functions collapse many rows into a single value. 
--The five common ones are `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`. They ignore NULL values (except `COUNT(*)`, which counts every row including those with NULLs).

--**In plain English:** Aggregates are the equivalent of using `=COUNT()`, `=SUM()`, or `=AVERAGE()` on an Excel column. They take a range and return one number.

--**Critical NULL behavior:**
--- `COUNT(*)` counts every row (NULLs included)
--- `COUNT(ColumnName)` counts only non-NULL values in that column
--- `SUM`, `AVG`, `MIN`, `MAX` ignore NULLs entirely (they're computed only on non-NULL values)

--**Practice (90 min):**

--```sql
---- Total row count
--SELECT COUNT(*) AS TotalProducts FROM Production.Product;

--SELECT COUNT(*) AS TotalProducts
--FROM Production.Product;

---- Count of non-NULL Colors (some products have NULL Color)
--SELECT COUNT(Color) AS ColoredProducts FROM Production.Product;

--SELECT COUNT(Color) AS ColordProducts
--FROM Production.Product;

---- Difference between the two reveals nulls
--SELECT
--    COUNT(*) AS TotalRows,
--    COUNT(Color) AS NonNullColors,
--    COUNT(*) - COUNT(Color) AS NullColorCount
--FROM Production.Product;

--SELECT
--	COUNT(*) AS ALLROWS,
--	COUNT(Color) AS NONNULLCOLOR,
--	COUNT(*)-COUNT(COLOR) AS NULLCOLORCOUNT

--FROM Production.Product;

---- Average list price (skip the free items)
--SELECT AVG(ListPrice) AS AvgPrice
--FROM Production.Product
--WHERE ListPrice > 0;

--SELECT AVG(listprice) AS avgprice
--FROM Production.Product
--WHERE listprice>0;

---- Min and max in one query
--SELECT
--    MIN(ListPrice) AS Cheapest,
--    MAX(ListPrice) AS MostExpensive
--FROM Production.Product
--WHERE ListPrice > 0;

--SELECT
--	MIN(listprice) AS [Cheapest],
--	MAX(listprice) AS [Most Expensive]
--FROM Production.Product
--WHERE listprice>0;

---- Sum of all order line items (lifetime revenue)
--SELECT SUM(LineTotal) AS LifetimeRevenue
--FROM Sales.SalesOrderDetail;

--SELECT SUM(linetotal) AS lifetimerevenue
--FROM Sales.SalesOrderDetail;

---- Multiple aggregates in one query
--SELECT
--    COUNT(*) AS OrderCount,
--    SUM(TotalDue) AS TotalRevenue,
--    AVG(TotalDue) AS AverageOrderValue,
--    MIN(TotalDue) AS SmallestOrder,
--    MAX(TotalDue) AS LargestOrder
--FROM Sales.SalesOrderHeader;

--SELECT
--	COUNT(*) AS OrderCount,
--	SUM(totaldue) AS totrev,
--	AVG(totaldue) AS avgrev,
--	MIN(totaldue) AS minrev,
--	MAX(totaldue) AS maxrev
--FROM Sales.SalesOrderheader;

--```

--**Self-test (45 min):**

--1. How many DISTINCT products have been sold? Use `COUNT(DISTINCT ProductID)` on `SalesOrderDetail`.

--SELECT	COUNT(DISTINCT ProductID) AS [# of Unique products sold]
--FROM Sales.SalesOrderDetail;

--2. What's the average markup ($) on products where `StandardCost > 0`? (markup = ListPrice - StandardCost)

--SELECT
--	AVG(p.ListPrice-p.StandardCost) AS [Avg Markup]

--FROM Production.Product p;



--3. Total revenue from orders placed in 2014 only.

--SELECT SUM(totaldue)
--FROM Sales.SalesOrderHeader
--WHERE OrderDate BETWEEN '2014-01-01' AND '2014-12-31';

--4. The single most expensive product's `ListPrice` — just the number, no other columns. (Hint: use MAX in SELECT.)

--SELECT MAX(listprice)
--FROM Production.Product p;

--5. How many products have NULL `ProductSubcategoryID`?

--SELECT COUNT(*)
--FROM Production.Product
--WHERE ProductSubcategoryID IS NULL 
