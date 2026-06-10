--Examples

--**The mental model:**

--```
--SELECT
--    GroupingColumn,             ← what you're grouping by
--    SUM(ValueColumn) AS Total   ← aggregate per group
--FROM TableName
--WHERE filter_conditions          ← filter rows BEFORE grouping
--GROUP BY GroupingColumn          ← collapse rows by this column
--ORDER BY Total DESC;             ← sort the grouped result
--```

--The order of operations the database actually runs is:

--1. `FROM` — get the table
--2. `WHERE` — filter rows (before grouping)
--3. `GROUP BY` — collapse into groups
--4. `SELECT` — choose columns / compute aggregates
--5. `ORDER BY` — sort the final output

--Understanding this order matters because it explains why you can't filter on an aggregate in `WHERE` — 
--the aggregate hasn't been computed yet. (You'd use `HAVING` for that, which we'll cover in Week 2.)


-- Group products by color, count how many per color

SELECT
	Color,
	Count(*) AS [Color Count]
FROM Production.Product
GROUP BY Color
ORDER BY [Color Count] DESC;

-- Same, but with multiple aggregates per group
SELECT
	Color,
	Count(*) AS [Color Count],
	SUM(listprice) AS [Price per color],
	AVG(listprice) AS [Avg price per color],
	MIN(listprice) AS [Cheapest product by color],
	MAX(listprice) AS [Most Expensive product by color]
FROM Production.Product
WHERE listprice > 0
GROUP BY Color
ORDER BY [Color Count] DESC;


-- Group by multiple columns
SELECT
	Color,
	Size,
	Count(*) AS ProductCount
FROM Production.product
WHERE listprice > 0
GROUP BY
	Color,
	Size
ORDER BY ProductCount DESC;

-- Group by a date part (year of order)
SELECT
	YEAR(orderdate) AS [Year],
	COUNT(*) AS [Count],
	SUM(totaldue) AS [Total Revenue]
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(orderdate)
ORDER BY [Count];


-- Group by year-month
SELECT
	YEAR(orderdate) AS [Year],
	MONTH(orderdate) AS [Month],
	COUNT(*) AS [Orders]
FROM Sales.SalesOrderHeader
GROUP BY
	YEAR(orderdate),
	MONTH(orderdate)

ORDER BY YEAR(orderdate) DESC, MONTH(orderdate) DESC;

--practice

--1. From `Sales.SalesOrderHeader`, for each `CustomerID`, show the customer ID and the total amount they've spent (`SUM(TotalDue)`). 
--Show only the top 20 by total spend.

SELECT TOP 20
	CustomerID,
	SUM(TotalDue) AS [Total Revenue]
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY [Total Revenue] DESC;

--2. From `Production.Product`, count products per color, but only consider products where `ListPrice > 100`. Sort by count descending.

SELECT
	Color,
	COUNT(*) AS [Product Count]
FROM Production.product
WHERE listprice > 100
GROUP BY Color
ORDER BY [Product Count] DESC;

--3. From `Sales.SalesOrderHeader`, show order count and total revenue per month for the year 2013. (Year/month combination.)

SELECT
	MONTH(orderdate) AS [Month],
	YEAR(orderdate) AS [Year],
	COUNT(*) AS [Product Count],
	SUM(totaldue) AS [Total Revenue]
FROM Sales.SalesOrderHeader
WHERE orderdate >='2013-01-01'
AND orderdate < '2014-01-01'
GROUP BY
	MONTH(orderdate),
	YEAR(orderdate)
ORDER BY MONTH(orderdate), YEAR(orderdate);

--4. From `Production.Product`, what's the average list price grouped by `ProductLine`? Exclude products where `ListPrice = 0`.
SELECT
	Productline,
	AVG(listprice) AS [Average Price]
FROM Production.product
WHERE listprice > 0
GROUP BY ProductLine
ORDER BY [Average Price];

--5. From `Sales.SalesOrderHeader`, how many orders were placed by each `TerritoryID`? Show territory ID and order count, sorted by count descending.

SELECT 
	Territoryid,
	COUNT(*) AS [Order Count]
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID
ORDER BY [Order Count] DESC;