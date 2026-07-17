USE AdventureWorks2022;
GO


SELECT *
FROM sales.SalesOrderHeader
WHERE SalesOrderID = 43671;

SELECT *
FROM	sales.SalesOrderHeader
WHERE totaldue > 100000;


SELECT	soh.salesorderid,
		soh.orderdate,
		soh.totaldue,
		c.accountnumber
FROM	sales.SalesOrderHeader soh
INNER JOIN sales.customer c ON soh.customerid = c.customerid
--WHERE	YEAR(soh.Orderdate) = 2013;
WHERE OrderDate >= '2013-01-01'
  AND OrderDate < '2014-01-01';

SELECT	soh.salesorderid,
		soh.orderdate,
		soh.totaldue,
		c.accountnumber
FROM	sales.SalesOrderHeader soh
INNER JOIN sales.customer c ON soh.customerid = c.customerid
WHERE	YEAR(soh.Orderdate) = 2013;


SELECT * FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013;


SELECT * FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2013-01-01'
  AND OrderDate < '2014-01-01';

  SELECT
    p.Name,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE LEFT(p.Name, 5) = 'Mount'
GROUP BY p.Name
ORDER BY Revenue DESC;
-- Run with execution plan. Look at the plan. See the operators.

-- Note: LEFT(p.Name, 5) = 'Mount' is non-sargable.
-- Rewrite as sargable:
SELECT
    p.Name,
    SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE p.Name LIKE 'Mount%'  -- sargable for column with index
GROUP BY p.Name
ORDER BY Revenue DESC;
-- Compare plans.

1. With "Include Actual Execution Plan" enabled, run these three queries. For each, identify the most expensive operator and write 1 sentence about why:
   SELECT * FROM Sales.SalesOrderHeader WHERE SalesOrderID < 50000;
   SELECT * FROM Sales.SalesOrderHeader WHERE CustomerID = 29825; 
   SELECT * FROM Sales.SalesOrderHeader WHERE TotalDue BETWEEN 1000 AND 5000; 

2. Run this and observe the plan:
   ```sql
   SELECT
       p.Name,
       COUNT(*) AS OrderLines
   FROM Sales.SalesOrderDetail sod
   INNER JOIN Production.Product p ON sod.ProductID = p.ProductID
   GROUP BY p.Name
   ORDER BY OrderLines DESC;
   ```
   Identify: which table is scanned, which join algorithm is used, where the sort happens.

3. Demonstrate the sargability gotcha. Run these two queries and compare their plans:
   ```sql
   SELECT * FROM Sales.SalesOrderHeader WHERE MONTH(OrderDate) = 3;
   SELECT * FROM Sales.SalesOrderHeader WHERE OrderDate >= '2013-03-01' AND OrderDate < '2013-04-01';
   ```
   In a comment, write what you observe — particularly the operator costs and whether index seek is used.

4. Architect question (in a comment): A vendor's slow query has a plan dominated by a "Key Lookup" operation, called millions of times. What's likely happening, and what's a possible fix? (Hint: covering index.)