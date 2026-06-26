WITH customer_orders AS (
						 SELECT		customerid,
									COUNT(*) AS ordercount
						 FROM		sales.SalesOrderHeader
						 GROUP BY	CustomerID),
portfolio_avg AS		(
						 SELECT		(AVG(CAST(Ordercount AS FLOAT))) AS AvgOrderCount							
						 FROM		customer_orders)

SELECT
	co.CustomerID,
	co.ordercount,
	pa.AvgOrderCount,
	co.ordercount - pa.AvgOrderCount AS diff

FROM	customer_orders AS co
CROSS JOIN	portfolio_avg AS pa
ORDER BY co.ordercount DESC;

WITH yearly_orders AS	(SELECT
								customerid,
								YEAR(orderdate) AS orderyear,
								COUNT(*) AS ordersinyear,
								SUM(totaldue) AS spendinyear
						 FROM
								sales.SalesOrderHeader
						 GROUP BY
								CustomerID, YEAR(orderdate)),
customer_consistency AS	(SELECT
								customerid,
								COUNT(DISTINCT orderyear) AS ActiveYears,
								SUM(spendinyear) AS lifetimespend
						 FROM yearly_orders
						 GROUP BY
								customerid),
loyal_customers AS		(SELECT *
						 FROM customer_consistency
						 WHERE	ActiveYears >= 3
							AND	lifetimespend > 50000)

SELECT
	lc.customerid,
	p.firstname,
	p.lastname,
	lc.activeyears,
	lc.lifetimespend
FROM
	loyal_customers lc
INNER JOIN sales.customer c ON lc.CustomerID = c.CustomerID
INNER JOIN person.Person p ON c.PersonID = p.BusinessEntityID
ORDER BY lc.lifetimespend DESC;
	
WITH customer_spend AS (
	SELECT	customerid,
			SUM(totaldue) AS totalspend
	FROM	sales.SalesOrderHeader
	GROUP BY
			CustomerID),

spend_buckets AS (
	SELECT	customerid,
			totalspend,
			CASE
				WHEN totalspend >= 100000 THEN 'whale'
				WHEN totalspend >= 10000 THEN 'high'
				WHEN totalspend >= 1000 THEN 'mid'
				ELSE 'low'
			END AS bucket
	FROM	customer_spend)

SELECT	bucket,
		COUNT(*) AS customercount,
		SUM(totalspend) AS buckettotal,
		AVG(totalspend) AS bucketavg
FROM	spend_buckets
GROUP BY	bucket
ORDER BY	buckettotal DESC;


--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. The most expensive product per subcategory (top-1 per group). Write a CTE that finds `MAX(ListPrice)` per `ProductSubcategoryID`, 
--then join it back to `Production.Product` to recover the product name at that max price. This top-1 case is fully solvable with CTEs today — it's the *top-N* (e.g., top 3 per subcategory) version that waits for window functions in Week 4.

WITH top1 AS (
	SELECT	MAX(p.listprice) top1,
			p.productsubcategoryID
	FROM	Production.Product p
	GROUP BY	p.productsubcategoryID)

SELECT	p2.name,
		p2.ListPrice,
		t.top1
FROM Production.Product p2
INNER JOIN top1 t ON p2.ProductSubcategoryID = t.ProductSubcategoryID

--2. Write a 2-CTE query: Step 1 — per salesperson, total revenue. Step 2 — filter to salespeople above $5M lifetime revenue, joined to their name in `Person.Person`. Output: salesperson name, lifetime revenue.


WITH step1 AS 
(
	SELECT	BusinessentityID,
			SUM(salesYTD) totalrevenue
	FROM	sales.SalesPerson
	GROUP BY	BusinessEntityID
),

step2 AS
(
	SELECT	*
	FROM	step1
	WHERE	totalrevenue > 500000)

SELECT	p.FirstName,
		p.lastname,
		s2.totalrevenue
	
FROM person.person p
INNER JOIN step1 s ON p.BusinessEntityID = s.BusinessEntityID
INNER JOIN step2 s2 ON s.BusinessEntityID = s2.BusinessEntityID
ORDER BY totalrevenue DESC;



--3. Take any query you wrote in Week 2 that had multi-level logic (Saturday sprint Problems 4 or 5 are good candidates). Rewrite it using CTEs. Notice the readability improvement.
--**Problem 4 — Customers with orders in 2013 but not in 2014 (anti-pattern)**
--Show customer IDs of customers who placed at least one order in 2013 but zero orders in 2014. Their full names too. This is the kind of "churn analysis" question architects get asked all the time.

WITH orderin2013 AS
(
	SELECT	customerid
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(OrderDate) = 2013
	GROUP BY	CustomerID
	HAVING	COUNT(orderdate) >= 1
),

orderin2014 AS
(
	SELECT	customerid
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(OrderDate) = 2014
	GROUP BY	CustomerID
)

SELECT	soh.customerid
FROM	sales.SalesOrderHeader soh
WHERE EXISTS
(
	SELECT 1
	FROM	orderin2013 o
	WHERE	soh.CustomerID = o.CustomerID)

AND	NOT EXISTS
(
	SELECT 1
	FROM	orderin2014 o2
	WHERE	soh.CustomerID = o2.CustomerID)

--write cte: For each `TerritoryID` (from SalesOrderHeader), show the *top-revenue product subcategory*. Show territory ID, subcategory name, and total revenue from that subcategory in that territory.
--*This is a hard one. You'll likely return ALL subcategory revenues per territory and look at the top by hand for now.
WITH soh AS
(
	SELECT	territoryid,
			salesorderid,
			TotalDue
	FROM Sales.SalesOrderHeader

),

sod AS
(
	SELECT	Salesorderid,
			productid
	FROM	sales.SalesOrderDetail
)

SELECT	p.ProductSubcategoryID,
		s2.territoryid,
		SUM(s2.TotalDue) AS Total
FROM	Production.Product p
INNER JOIN	sod s ON p.ProductID = s.productid
INNER JOIN	soh s2 ON s.SalesOrderID = s2.SalesOrderID
GROUP BY p.ProductSubcategoryID, s2.TerritoryID
ORDER BY p.ProductSubcategoryID ASC;



SELECT TOP 1 * FROM Sales.SalesOrderHeader
SELECT TOP 1 * FROM Sales.SalesOrderDetail --'product id'
SELECT TOP 1 * FROM Production.Product --'product id'



--4. Write a 3-CTE chain: Step 1 — orders per customer per year. Step 2 — customers active in 2013, 2014 (2-year consistent). Step 3 — for those consistent customers, their total lifetime spend, joined to their names. Output: customer name + lifetime spend, top 20.

WITH step1 AS
(
	SELECT	customerID,
			YEAR(orderdate) AS orderperyear,
			COUNT(*) AS orders
	FROM	sales.SalesOrderHeader
	GROUP BY	CustomerID, YEAR(orderdate)
),
step2 AS
(
	SELECT	customerid
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(OrderDate) = 2013
	GROUP BY	CustomerID
),

step3 AS
(
	SELECT	customerid
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(OrderDate) = 2014
	GROUP BY	CustomerID
)


SELECT	TOP 20
		p.firstname,
		p.lastname,
		SUM(soh.totaldue) AS totalrevenue
FROM	sales.SalesOrderHeader soh
INNER JOIN sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN person.Person p ON c.PersonID = p.BusinessEntityID
WHERE	EXISTS (
				SELECT 1
				FROM step2 s2 
				WHERE s2.customerid = soh.CustomerID)
AND EXISTS	(
				SELECT 1
				FROM step3 s3 
				WHERE s3.customerid = soh.CustomerID)
GROUP BY p.firstname, p.lastname
ORDER BY SUM(soh.totaldue) DESC;


--SELECT TOP 1 * FROM PERSON.Person
--SELECT TOP 1 * FROM SALES.CUSTOMER 
--exec sp_help 'SALES.CUSTOMER'




--5. Reflection (in comments): For a query at RioCan with 3+ steps of business logic, would you use CTEs or nested subqueries? Why? Write a 2-sentence answer.

