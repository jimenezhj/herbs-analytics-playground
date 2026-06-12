--**Problem 1 — Top customers by spend**
--From `Sales.SalesOrderHeader`, show the top 20 customers by total spend across all years. 
--Columns: `CustomerID`, `OrderCount`, `TotalSpend`, `AverageOrderValue`. Sort by `TotalSpend` descending.

SELECT TOP 20
	YEAR(Orderdate) AS [Years],
	CustomerID AS [Customer Number],
	COUNT(*) AS [Order Count],
	CAST(SUM(TotalDue) as decimal(38,2)) AS [Total Spend],
	CAST(AVG(TotalDue) as decimal(38,2)) AS [Avg Order Value]
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), CustomerID
ORDER BY [Total Spend] DESC;

--**Problem 2 — Monthly revenue trend**
--Show monthly revenue from `Sales.SalesOrderHeader` for 2013 and 2014. 
--Columns: `Year`, `Month`, `OrderCount`, `MonthlyRevenue`. Sort chronologically.

SELECT
	YEAR(OrderDate) AS [Year],
	DATENAME(MONTH,OrderDate) AS [Month],
	COUNT(*) AS [Order Count],
	CAST(SUM(TotalDue) AS decimal(38,2)) AS [Revenue]
	
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01'
AND OrderDate < '2015-01-01'
GROUP BY
	YEAR(OrderDate),
	DATENAME(MONTH,OrderDate),
	MONTH(orderdate)
ORDER BY
	YEAR(OrderDate),
	MONTH(orderdate);

--**Problem 3 — Product mix by color**
--From `Production.Product`, for each color (excluding null colors and free products), 
--show: `Color`, `ProductCount`, `AvgListPrice`, `MinListPrice`, `MaxListPrice`. Sort by `ProductCount` descending.

SELECT
	Color AS [Product Color],
	COUNT(*) AS [Product Count],
	CAST(AVG(ListPrice) AS decimal(38,2)) AS [Average Price],
	MIN(ListPrice) AS [Cheapest Product],
	MAX(ListPrice) AS [Most Expensive Product]
FROM Production.Product
WHERE Color IS NOT NULL
AND ListPrice > 0
GROUP BY
	Color
ORDER BY [Product Count] DESC;

--**Problem 4 — Distinct cities**
--From `Person.Address`, list all distinct `City` values sorted alphabetically. 
--Then write a second query that counts how many distinct cities there are. (Two separate queries, same result file.)

SELECT DISTINCT
	City AS [Cities]
FROM Person.Address
GROUP BY City
ORDER BY Cities;

SELECT 
	COUNT(DISTINCT City) AS [Cities]
FROM Person.Address;

--**Problem 5 — Order size distribution**
--From `Sales.SalesOrderHeader`, categorize orders into three buckets based on `TotalDue`:
--- "Small" if TotalDue < $1,000
--- "Medium" if TotalDue between $1,000 and $10,000
--- "Large" if TotalDue > $10,000

SELECT
	COUNT(DISTINCT CASE WHEN TotalDue < 1000 THEN SalesOrderID END) AS [Small],
	COUNT(DISTINCT CASE WHEN (TotalDue >= 1000 AND TotalDue < 10000) THEN SalesOrderID END) AS [Medium],
	COUNT(DISTINCT CASE WHEN TotalDue > 10000 THEN SalesOrderID END) AS [Large]
FROM Sales.SalesOrderHeader;

--**Problem 6 — Data quality check (this is real architect work)**
--From `Sales.SalesOrderHeader`, pull `SalesOrderID`, `SubTotal`, `TaxAmt`, `Freight`, and `TotalDue`. 
--Compute a column `Reconciliation = SubTotal + TaxAmt + Freight - TotalDue` and find any rows where it's not exactly zero. 
--Result should be zero rows (the data is clean), 
--but the query pattern is reusable — this is the shape of every data quality check you'll ever write.

SELECT
	SalesOrderID AS [Order ID],
	Subtotal AS [Sub Total],
	TaxAmt AS [Tax Amount],
	Freight AS [Freight],
	TotalDue AS [Total],
	Subtotal+TaxAmt+Freight-TotalDue AS [Reconciliation]

FROM Sales.SalesOrderHeader
WHERE Subtotal+TaxAmt+Freight-TotalDue <> 0;
