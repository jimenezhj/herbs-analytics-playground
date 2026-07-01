--**Problem 1 — Year-over-year revenue and order counts (CTEs + conditional aggregation)**

--Produce one row per year (2011–2014) with columns: `Year`, `OrderCount`, `Revenue`, `AvgOrderValue`. Build it with a CTE that aggregates `Sales.SalesOrderHeader` by `YEAR(OrderDate)`, then a clean final SELECT. 
--*(Note: the prior-year-growth version of this — each year compared to the one before — is genuinely a window-function problem (`LAG`), so it's been moved to Week 4 where it becomes a two-line exercise. Here, focus on the per-year aggregation with this week's tools.)*

WITH RevenuePerYear AS 

(
SELECT	YEAR(Orderdate) [Year],
		COUNT(SalesOrderID) [Order Count],
		SUM(TotalDue) [Revenue],
		AVG(TotalDue) [Average Order Value]
FROM	Sales.SalesOrderHeader
GROUP BY	YEAR(OrderDate)
)

SELECT	*
FROM	RevenuePerYear


--**Problem 2 — Customer cohort analysis (CTEs)**
--For each year a customer first placed an order, count how many customers were in that "cohort" and what their total lifetime spend has been. Output: `FirstOrderYear`, `CohortSize`, `CohortLifetimeRevenue`.

WITH CohortSize AS
(
SELECT  Customerid,
		YEAR(MIN(Orderdate)) FirstOrderYear,
		COUNT(DISTINCT CustomerID) [Cohort Size]
FROM	sales.SalesOrderHeader
GROUP BY	CustomerID
)

SELECT	cs.[FirstOrderYear],
		SUM(cs.[Cohort Size]) [Cohort Size],
		SUM(soh.TotalDue) [Total lifetime Revenue]
FROM	Sales.SalesOrderHeader soh
INNER JOIN	Cohortsize cs ON soh.CustomerID = cs.CustomerId	
GROUP BY	cs.[FirstOrderYear];

SELECT SUM(totaldue) FROM sales.SalesOrderHeader;

--(Hint: Step 1 — find each customer's first order year. Step 2 — group by that year, count customers, sum their lifetime spend.)

--**Problem 3 — Top product per category (correlated subquery or CTE)**
--For each `ProductCategory`, find the highest-priced product. Output: `CategoryName`, `TopProductName`, `TopPrice`.

WITH TopPrice AS
(
SELECT	pc.ProductCategoryID pID,
		MAX(p.listprice) AS TopPrice
FROM	Production.Product p
LEFT JOIN	Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN	Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.ProductCategoryID, pc.Name
)

SELECT	p.name,
		tp.TopPrice,
		pc.name
FROM	Production.Product p
LEFT JOIN	Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN	Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
INNER JOIN TopPrice tp ON pc.ProductCategoryID = tp.pID
WHERE p.ListPrice = tp.TopPrice

--This is the **top-1**-per-group case, and it IS solvable with this week's tools: a CTE that finds `MAX(ListPrice)` per category, then join back to `Production.Product` to recover the product name at that price. 
--(Watch for ties — two products at the same max price both qualify; that's fine to note.) The general **top-N** version — "top 3 per category" — is the one that genuinely needs window functions, and that's Week 4. So this problem is a real, finishable challenge today, not a teaser.

--**Problem 4 — Vendor concentration risk (CTEs + CASE)**

SELECT COUNT(PurchaseOrderID) FROM purchasing.PurchaseOrderHeader 
--For each vendor in `Purchasing.PurchaseOrderHeader` (a new schema you haven't touched — `SELECT TOP 1 *` first to find the vendor-ID and amount columns yourself), compute total spend.
--Bucket each vendor into 'Critical' (>= $1M), 'Major' ($100K-1M), 'Minor' (<$100K). Then output one row per bucket with count of vendors and total spend in that bucket. (The buckets are arbitrary — adjust if the data lands differently.)

WITH vendortotalspend AS 
(
SELECT	poh.vendorID vID,
		SUM(poh.totaldue) totalspend
FROM	Purchasing.PurchaseOrderHeader poh
GROUP BY poh.VendorID
),
SpendBucket AS
(
SELECT	vID,
		totalspend,
		CASE
			WHEN totalspend >= 1000000 THEN 'Critical'
			WHEN totalspend >= 100000 AND totalspend < 1000000 THEN 'Major'
			WHEN totalspend < 100000 THEN 'Minor'
		END AS Bucket
FROM	Vendortotalspend
)

SELECT	Bucket,
		count(vID) TotalVendors,
		sum(totalspend) TotalSpend
FROM	SpendBucket
GROUP BY Bucket


--**Problem 5 — Stale customers (dates + missing rows pattern)**

--Find customers whose most recent order is more than 365 days ago (relative to the max order date in the table, not GETDATE() — since AdventureWorks data is from years ago).

WITH LastOrder AS
(
SELECT	CustomerID cID,
		MAX(OrderDate) LastOrder
FROM	sales.SalesOrderHeader
GROUP BY	CustomerID
)

SELECT	p.firstname,
		p.lastname,
		DATEDIFF(DAY,lo.lastorder,LatestOrderFromTable) AS DaysSinceLastOrder
FROM LastOrder lo

CROSS JOIN

(SELECT	MAX(soh.orderdate) LatestOrderFromTable
FROM	sales.SalesOrderHeader soh) AS X

INNER JOIN Sales.Customer c ON lo.cID = c.CustomerID
INNER JOIN person.person p ON c.PersonID = p.BusinessEntityID
WHERE DATEDIFF(DAY,lo.lastorder,LatestOrderFromTable) > 365
ORDER BY DaysSinceLastOrder DESC;

--Output: customer name + most recent order date + days since last order. Sort by stale-est first.

--(Hint: CTE finding max order date per customer, then filter by `DATEDIFF` against the max order date in the table.)

--**Problem 6 — Architect challenge: Data quality summary**

--Write a query (probably with CTEs) that produces one row per table-of-interest, showing:
--- Table name (hard-coded string)
--- Row count
--- Count of rows with at least one NULL in a critical column
--- Pct of "clean" rows

SELECT COUNT(*) FROM sales.customer

SELECT	'Sales.Customer' AS TableName,
		COUNT(*) AS NumberofRows,
		COUNT(*)-COUNT(PersonID) AS NumberOfNullRows,
		CAST(COUNT(*)-(COUNT(*)-COUNT(PersonID)) AS decimal(38,2))/COUNT(*) AS PctOfCleanRows
FROM	Sales.Customer

UNION

SELECT	'Sales.SalesOrderheader' AS TableName,
		COUNT(*) AS NumberofRows,
		COUNT(*)-COUNT(Shipdate) AS NumberOfNullRows,
		CAST(COUNT(*)-(COUNT(*)-COUNT(ShipDate)) AS decimal(38,2))/COUNT(*) AS PctOfCleanRows
FROM	Sales.SalesOrderHeader

UNION

SELECT	'Production.product' AS TableName,
		COUNT(*) AS NumberofRows,
		COUNT(*)-COUNT(Color) AS NumberOfNullRows,
		CAST(COUNT(*)-(COUNT(*)-COUNT(Color)) AS decimal(38,2))/COUNT(*) AS PctOfCleanRows
FROM	Production.Product


--For three tables:
--- `Sales.Customer` (critical: `PersonID` not null)
--- `Sales.SalesOrderHeader` (critical: `ShipDate` not null)
--- `Production.Product` (critical: `Color` not null)

--Output should be a 3-row table with consistent columns: `TableName`, `TotalRows`, `RowsMissingCritical`, `CleanPct`.

--(This is the kind of "data quality dashboard" query architects write all the time. UNION ALL three queries together.)