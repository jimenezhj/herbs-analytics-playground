--**Problem 1 — Top customers with names (3-table join)**

--Show the top 20 customers by total spend (across all years), including their first and last name. Columns: `CustomerName`, `OrderCount`, `TotalSpend`. Sort by TotalSpend descending.
--*Skills: 3-table join, GROUP BY, aggregates, ORDER BY*
SELECT
	TOP 20
	p.firstname+' '+p.lastname AS Customername,
	SUM(soh.totaldue) AS TotalSpend,
	COUNT(soh.salesorderid) AS Ordercount
FROM Sales.SalesOrderheader AS soh
LEFT JOIN	Sales.Customer AS c	ON soh.CustomerID = c.CustomerID
INNER JOIN	Person.person p	ON c.PersonID = p.BusinessEntityID
GROUP BY p.firstname, p.lastname
ORDER BY TotalSpend DESC;

--**Problem 2 — Product revenue by category (4-table join + GROUP BY)**
--For each product category, show the total revenue (SUM of `SalesOrderDetail.LineTotal`), number of distinct orders, and number of distinct products sold. Sort by revenue descending.
--*Tables: Sales.SalesOrderDetail → Production.Product → Production.ProductSubcategory → Production.ProductCategory*
--*Skills: 4-table join, GROUP BY, COUNT DISTINCT, aggregates*

SELECT
	pc.Name AS ProductCategory,
	COUNT(DISTINCT sod.SalesOrderID) AS distinctorders,
	COUNT(DISTINCT sod.ProductID) AS distinctprodsold,
	SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN	Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN	Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN	Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalRevenue DESC;

--**Problem 3 — Salespeople with zero orders (missing rows pattern)**
--Find every salesperson who has placed *no orders ever*. Show their `BusinessEntityID`, first name, and last name. (Three-table chain: SalesPerson → Person.Person, then LEFT JOIN to SalesOrderHeader.)
--*Skills: LEFT JOIN, missing rows pattern, multi-table*

SELECT	sp.BusinessEntityID,
		p.FirstName,
		p.LastName
FROM Sales.SalesPerson AS sp
INNER JOIN person.person AS p
	ON	sp.BusinessEntityID = p.BusinessEntityID
LEFT JOIN	sales.SalesOrderHeader AS soh
	ON	sp.BusinessEntityID = soh.SalesPersonID 
WHERE soh.SalesPersonID IS NULL

--**Problem 4 — Customers with orders in 2013 but not in 2014 (anti-pattern)**
--Show customer IDs of customers who placed at least one order in 2013 but zero orders in 2014. Their full names too. This is the kind of "churn analysis" question architects get asked all the time.
--*Hint: One approach is a query that finds customers with 2013 orders, then a LEFT JOIN to a subquery of 2014 customers, then WHERE IS NULL. Another approach uses HAVING with conditional aggregation. Try either; we'll formalize subqueries next week.*
--*Skills: stretch problem — it's solvable with current tools but requires creative use of HAVING with CASE expressions:*



SELECT	
	soh.CustomerID,
	SUM(CASE WHEN YEAR(orderdate) = 2013 THEN 1 ELSE 0 END) AS OrdersPlacedin2013,
	SUM(CASE WHEN YEAR(orderdate) = 2014 THEN 1 ELSE 0 END) AS OrdersPlacedin2014
FROM Sales.SalesOrderHeader AS soh
WHERE soh.OrderDate >= '2013-01-01'
	AND soh.OrderDate < '2015-01-01'
GROUP BY soh.CustomerID
HAVING SUM(CASE WHEN YEAR(orderdate) = 2013 THEN 1 ELSE 0 END) >= 1
	AND SUM(CASE WHEN YEAR(orderdate) = 2014 THEN 1 ELSE 0 END) = 0
ORDER BY soh.CustomerID;

--**Problem 5 — Top product subcategories by revenue per region**
--For each `TerritoryID` (from SalesOrderHeader), show the *top-revenue product subcategory*. Show territory ID, subcategory name, and total revenue from that subcategory in that territory.
--*This is a hard one. You'll likely return ALL subcategory revenues per territory and look at the top by hand for now. The proper "top N per group" pattern uses window functions, which we cover in Week 4.*
--*Goal: produce a query that ranks subcategories within each territory. You don't have to filter to just the top one — see how close you can get.*

SELECT		soh.TerritoryID,
			ps.Name AS Subcategoryname,
			SUM(sod.LineTotal) AS totalbeforetaxandfreight
FROM		Sales.SalesorderDetail AS sod
INNER JOIN	sales.salesorderheader AS soh ON sod.SalesOrderID = soh.SalesOrderID
INNER JOIN	Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN	Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID		
GROUP BY soh.TerritoryID, ps.Name
ORDER BY TerritoryID ASC, totalbeforetaxandfreight DESC

--**Problem 6 — Data quality check across joins**

--Write a query that counts:
--- Total rows in `Sales.SalesOrderHeader`
--- Total rows in `Sales.SalesOrderHeader` that have a matching customer in `Sales.Customer`
--- The difference (orders with no matching customer — should be zero, but the check matters)

SELECT		COUNT(*) AS TotalOrders,
			COUNT(c.customerid) AS MatchingCustomers
FROM		sales.SalesOrderHeader AS soh
INNER JOIN	sales.customer AS c ON soh.customerid = c.customerid

