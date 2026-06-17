----NULL Grouping & COALESCE — Online vs. Rep Orders

--SELECT		soh.SalesPersonID	AS [Sales Person],
--			COUNT(*)			AS [Order Count],
--			SUM(soh.TotalDue)	AS [Total Revenue]
--FROM		Sales.SalesOrderHeader soh
--GROUP BY	soh.SalesPersonID
--ORDER BY	[Total Revenue] DESC;

----### Using COALESCE to label the NULL group
--SELECT		COALESCE(CAST(soh.SalesPersonID AS varchar(20)), 'Online')	AS	[Sales Person],
--			COUNT(*)													AS	[Order Count],
--			SUM(soh.TotalDue)											AS	[Total Revenue],
--			AVG(soh.TotalDue)											AS	[Avg Revenue]
--FROM		Sales.SalesOrderHeader soh
--GROUP BY	soh.SalesPersonID
--ORDER BY	[Total Revenue] DESC;

----### NULL inside aggregate functions — the COUNT difference
--SELECT		COUNT(*)	AS	[Total Orders],
--			COUNT(SalesPersonID)	AS	[Rep Driven Orders],
--			COUNT(*) - COUNT(SalesPersonID)	AS	[Online Orders]
--FROM		Sales.SalesOrderHeader;

---- Customers with a MIX of online and rep-driven orders
--SELECT	CustomerId,
--		COUNT(*)	AS	[Total Orders],
--		COUNT(SalesPersonID)	AS	[Rep Order],
--		COUNT(*) - COUNT(SalesPersonID)	AS	[Online Orders]
--FROM	Sales.SalesOrderHeader
--GROUP BY	CustomerID
--HAVING	COUNT(*) > COUNT(SalesPersonID)
--	--AND	COUNT(SalesPersonID) > 0;

----## 8. Alternative: One-Time-Customer Solutions	
----### Solution A — HAVING (direct)
--SELECT   CustomerID,
--         COUNT(*) AS OrderCount
--FROM     Sales.SalesOrderHeader
--GROUP BY CustomerID
--HAVING   COUNT(*) = 1;

----**Pros:** Concise, readable, standard SQL.
----**Cons:** Full scan + aggregation of all 31,465 rows before filtering groups.

----### Solution B — Subquery (NOT IN)
--SELECT	CustomerID
--FROM	Sales.Customer
--WHERE	CustomerID NOT IN (
--			SELECT	CustomerID
--			FROM	Sales.SalesOrderHeader
--			GROUP BY	CustomerID
--			HAVING	COUNT(*) > 1);
--**Pros:** Semantically explicit.
--**Cons:** If the subquery ever returns a `NULL`, `NOT IN` silently returns zero rows.
--`CustomerID` is non-nullable here so it is safe, but the habit is dangerous.
--⚠️ Prefer Solution C in production.


----### Solution C — NOT EXISTS ✅ Recommended for production
--SELECT	c.CustomerID
--FROM	Sales.Customer c
--WHERE	NOT EXISTS	(
--			SELECT	1
--			FROM	Sales.SalesOrderHeader soh
--			WHERE	soh.CustomerID = c.CustomerID
--			GROUP BY	soh.CustomerID
--			HAVING	COUNT(*) > 1);

--**Pros:** NULL-safe. SQL Server short-circuits as soon as one match is found.
--**Cons:** Slightly more verbose.

----### Solution D — CTE + JOIN

--WITH OneTimeCustomers AS (
--		SELECT	CustomerID
--		FROM	Sales.SalesOrderHeader
--		GROUP BY	CustomerID
--		HAVING	COUNT(*) = 1
--		)

--SELECT	c.CustomerID,
--		soh.SalesOrderID,
--		soh.OrderDate,
--		soh.TotalDue
--FROM	Sales.Customer	c
--JOIN	OneTimeCustomers	ot ON c.CustomerID = ot.CustomerID
--JOIN	Sales.SalesOrderHeader soh ON	c.CustomerID = soh.CustomerID
--ORDER BY	soh.TotalDue DESC;

--**Pros:** Highly readable; returns the full order row without an extra join.
--**Cons:** May materialise to `tempdb` on older compatibility levels.



----### Solution E — Window function
--SELECT   CustomerID, SalesOrderID, OrderDate, TotalDue
--FROM     (
--             SELECT   CustomerID,
--                      SalesOrderID,
--                      OrderDate,
--                      TotalDue,
--                      COUNT(*) OVER (PARTITION BY CustomerID) AS TimesOrdered
--             FROM     Sales.SalesOrderHeader
--         ) sub
--WHERE    TimesOrdered = 1
--ORDER BY TotalDue DESC;

--**Pros:** Returns full order row directly; natural when you need order-level columns.
--**Cons:** `COUNT(*) OVER (…)` computed for every row before the outer `WHERE` filters.

--### Exercise 1 — Warm-up (Beginner)

--**Task:** List every sales territory that has **at least 500 customers** assigned to it.
--Include the territory name and customer count. Order by count descending.

--**Tables:** `Sales.Customer`, `Sales.SalesTerritory`
--**Output columns:** `Territory`, `CustomerCount`

--SELECT	t.Name AS [Territory],
--		COUNT(c.CustomerID) AS [Customer Count]
--FROM	Sales.Customer c
--JOIN	Sales.SalesTerritory t ON c.TerritoryID = t.TerritoryID
--GROUP BY	t.TerritoryID, t.Name
--HAVING	COUNT(c.CustomerID) >= 500
--ORDER BY	[Customer Count] DESC;

-----

----### Exercise 2 — Beginner

----**Task:** Find all product subcategories where the **maximum list price exceeds $2,000**.
----Exclude products with a list price of $0. Show subcategory name and maximum price.

----**Tables:** `Production.Product`, `Production.ProductSubcategory`
----**Output columns:** `Subcategory`, `MaxListPrice`

--SELECT		psc.Name AS [Sub Category],
--			MAX(p.listprice) AS [Max Price]
--FROM		Production.product p
--JOIN		Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
--WHERE		p.listprice > 0
--GROUP BY	psc.ProductSubcategoryID, psc.Name
--HAVING		MAX(p.listprice) > 2000
--ORDER BY	[Max Price] DESC;


-----

----### Exercise 3 — Intermediate

----**Task:** Find customers who placed **at least 3 orders** AND whose **total `TotalDue`
----exceeds $15,000**, counting only orders placed between **2013-01-01 and 2014-12-31**
----(inclusive). Return customer ID, full name, and total spent, sorted by total spent
----descending.

--SELECT	soh.CustomerID	AS	[Customer #],
--		CONCAT(p.firstname,' ',p.lastname) AS [Full Name],
--		COUNT(soh.CustomerID)	AS	[Total Customer Order],
--		SUM(soh.TotalDue)	AS	[Total Spent]

--FROM	Sales.SalesOrderHeader soh
--JOIN	Sales.Customer	c	ON	soh.CustomerID	=	c.CustomerID
--JOIN	Person.Person	p	ON	c.CustomerID	=	p.BusinessEntityID
--WHERE	soh.OrderDate	>=	'2013-01-01'
--	AND	soh.OrderDate	<	'2015-01-01'
--GROUP BY	soh.CustomerID, p.FirstName, p.LastName
--HAVING	SUM(soh.TotalDue)	>	15000
--	AND	COUNT(soh.CustomerID)	>=	3
--ORDER BY	[Total Spent]	DESC;

--**Tables:** `Sales.SalesOrderHeader`, `Sales.Customer`, `Person.Person`
--**Output columns:** `CustomerID`, `CustomerName`, `TotalSpent`
--*Hint: Use both `WHERE` (date range) and `HAVING` (aggregates). Filter
--`c.PersonID IS NOT NULL` to safely join to `Person.Person`.*

-----

----### Exercise 4 — Intermediate

----**Task:** For each `SalesPersonID` in `Sales.SalesOrderHeader` — including `NULL`
----(online orders) — show the order count and total revenue. Label the `NULL` group
----as `'Online / No Rep'`. Show only groups where **total revenue exceeds $3,000,000**.
----Order by total revenue descending.

--SELECT	COALESCE(CAST(soh.SalesPersonID AS varchar(20)), 'Online/No Rep')	AS	[Sales REP],
--		COUNT(*)	AS	[Order Count],
--		SUM(soh.TotalDue)	AS	[Total Revenue]
--FROM	Sales.SalesOrderHeader soh
--GROUP BY soh.SalesPersonID
--HAVING	SUM(soh.TotalDue) > 3000000
--ORDER BY	[Total Revenue] DESC;



--**Tables:** `Sales.SalesOrderHeader`
--**Output columns:** `SalesPerson`, `OrderCount`, `TotalRevenue`

-----

--### Exercise 5 — Intermediate

--**Task:** Identify product subcategories where **more than half the products**
--(with `ListPrice > 0`) have a `ListPrice` above **$500**. Return the subcategory name,
--total product count, and count of products priced above $500.

--SELECT		psc.Name AS [Sub Category Name],
--			COUNT(*) AS	[Total Product Count],
--			COUNT(*) * 0.5 AS	[Total Product Count2],
--			SUM(CASE WHEN p.listprice > 500 THEN 1 ELSE 0 END) AS [Total Product Count LP > 500]

--FROM		Production.Product	p
--JOIN		Production.ProductSubcategory	psc	ON	p.ProductSubcategoryID	=	psc.ProductSubcategoryID
--WHERE		p.listprice > 0
--GROUP BY	psc.ProductSubcategoryID, psc.Name
--HAVING		SUM(CASE WHEN p.listprice > 500 THEN 1 ELSE 0 END) > COUNT(*) * 0.5




--**Tables:** `Production.Product`, `Production.ProductSubcategory`
--**Output columns:** `Subcategory`, `TotalProducts`, `PriceyProducts`
--*Hint: Use `HAVING` with two aggregate expressions. Watch out for integer division.*

-----

--### Exercise 6 — Advanced

--**Task:** Find customers who placed orders in **both 2012 and 2013**.
--Return `CustomerID` only.

--SELECT		CustomerID AS	[Customer]
--FROM		Sales.SalesOrderHeader
--WHERE		OrderDate	>=	'2012-01-01'
--	AND		OrderDate	<	'2014-01-01'
--GROUP BY	CustomerID
--HAVING		SUM(CASE WHEN Year(OrderDate) = 2012 THEN 1 END)	>	0
--	AND		SUM(CASE WHEN Year(OrderDate) = 2013 THEN 1 END)	>	0		

--**Tables:** `Sales.SalesOrderHeader`
--*Hint: Count distinct years inside `HAVING`.*	

-----

----### Exercise 7 — Advanced

----**Task:** For each customer with more than one order, calculate the **average number
----of days between consecutive orders**. Return only customers where this average gap
----is **less than 60 days**. Order by average gap ascending.

--WITH ConsecDays AS (
--		SELECT	CustomerID,
--				OrderDate,
--				LAG(OrderDate,1) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS [Last Order]
--		FROM	Sales.SalesOrderHeader
	
--)

--SELECT		soh.CustomerID	AS	[Customer]
--FROM		Sales.SalesOrderHeader soh
--JOIN		Consecdays CD ON soh.CustomerID = CD.customerID
--	AND		soh.OrderDate = cd.OrderDate
--WHERE		cd.[Last Order] IS NOT NULL
--GROUP BY	soh.CustomerID
--HAVING		AVG(DATEDIFF(DAY,soh.OrderDate,cd.[Last Order])) < 60

	


--**Tables:** `Sales.SalesOrderHeader`
--**Output columns:** `CustomerID`, `AvgDaysBetweenOrders`
--*Hint: Use `LAG(OrderDate)` in a CTE. Use `DATEDIFF(DAY, …)` for the gap.
--`CAST` the result to `FLOAT` before `AVG`.*

-----

--## 12. Stretch Problems

--Intentionally open-ended — multiple correct approaches exist.

-----

--### Stretch 1 — The Loyal High-Spender

--Find customers who:
--- Have placed **10 or more** total orders.
--- Have a **lifetime `TotalDue`** of at least **$50,000**.
--- Have placed at least **one order in 2014** (the most recent year in the dataset).

--Write the query **two ways**: once using only `HAVING`, and once using a CTE.
--In SSMS, compare the actual execution plans (`Ctrl+M`). Which produces fewer logical reads?

--HAVING
--SELECT  CustomerID  AS  [Customer #],
--		COUNT(*)	AS	[Total Orders],
--		SUM(Totaldue) AS [Lifetime purchase]

--FROM	Sales.SalesOrderHeader
--GROUP BY	CustomerID
--HAVING	COUNT(*) >= 10
--	AND	SUM(Totaldue) > 50000
--	AND	SUM(CASE WHEN OrderDate >= '2014-01-01' AND OrderDate < '2015-01-01' THEN 1 ELSE 0 END) >= 1
--ORDER BY [Customer #] ASC;
	
----CTE

--WITH x AS (
--		SELECT	DISTINCT CustomerID
--		FROM	Sales.SalesOrderHeader
--		WHERE	OrderDate >= '2014-01-01' AND OrderDate < '2015-01-01'

--)

--SELECT		soh.CustomerID	AS	[Customer Number],
--			COUNT(*)	AS	[Total Orders],
--			SUM(soh.Totaldue) AS [Lifetime purchase]
--FROM		Sales.SalesOrderHeader soh
--JOIN		x ON	soh.CustomerID	=	x.CustomerID
--GROUP BY	soh.CustomerID
--HAVING		COUNT(*) >= 10
--	AND		SUM(TotalDue) > 50000
--ORDER BY [Customer Number] ASC;

-----

--### Stretch 2 — Subcategory Health Report

--Write a **single query** returning, for each product subcategory with at least 3 products
--(`ListPrice > 0`):

--| Column | Definition |
--|--------|-----------|
--| `ProductCount` | Number of qualifying products |
--| `AvgListPrice` | Average list price, rounded to 2 decimal places |
--| `PriceRange` | `MAX(ListPrice) - MIN(ListPrice)` |
--| `PctAboveSubcatAvg` | % of products priced above the **subcategory's own average** |
--| `PriceSegment` | `'Premium'` if avg > $1,500 · `'Mid-range'` if $200–$1,500 · `'Budget'` if < $200 |

--WITH pasba AS (
--		SELECT		ProductsubcategoryID,
--					AVG	(listPrice) AS AveragePrice
--		FROM		Production.product
--		WHERE		listprice > 0
--		GROUP BY	ProductsubcategoryID
--		)


--SELECT		psc.Name AS [Subcategory Name],
--			COUNT(*) AS	[Product Count],
--			CAST(AVG(ListPrice) as decimal(38,2)) AS [AvgListPrice],
--			MAX(ListPrice)-MIN(ListPrice)	AS	[Price Range],
--			CASE 
--					WHEN AVG(ListPrice) >= 1500 THEN 'Premium'
--					WHEN AVG(ListPrice) >= 200 AND AVG(ListPrice) < 1500 THEN 'Mid-Range'
--					ELSE 'Budget'
--			END AS [Price Segment],
--			CAST(SUM((CASE WHEN ListPrice > pas.AveragePrice THEN 1 ELSE 0 END))*1.0  / COUNT(*) AS decimal(38,2)) AS 'PctAboveSubcatAvg'

--FROM		Production.Product p
--JOIN		Production.ProductSubcategory psc	ON	p.ProductSubcategoryID	=	psc.ProductSubcategoryID
--JOIN		pasba pas						ON	p.ProductSubcategoryID	=	pas.ProductSubcategoryID
--WHERE		p.ListPrice > 0
--GROUP BY	psc.Name, PAS.AveragePrice
--HAVING		COUNT(*) >= 3


-----

--### Stretch 3 — Churn Signal

--A customer is **at risk of churning** if they placed at least **2 orders in 2012**
--and **zero orders in 2013**. Return these customers and their 2012 order count.

--Write two approaches (e.g., conditional `HAVING` vs. two CTEs with `NOT EXISTS`)
--and explain the trade-offs in a comment block above each query.
-----

--SELECT		s.CustomerID AS [Customer #],
--			SUM(CASE WHEN OrderDate >= '2012-01-01' AND OrderDate < '2013-01-01' THEN 1 ELSE 0 END) AS [2012 Order Count]
--FROM		Sales.SalesOrderHeader s
--GROUP BY	CustomerID
--HAVING		SUM(CASE WHEN s.OrderDate >= '2012-01-01' AND s.OrderDate < '2013-01-01' THEN 1 ELSE 0 END) >= 2
--	AND		SUM(CASE WHEN s.OrderDate >= '2013-01-01' AND s.OrderDate < '2014-01-01' THEN 1 ELSE 0 END) = 0
--ORDER BY	s.CustomerID;


--WITH		oc2012	AS	(
--			SELECT		CustomerID
--			FROM		Sales.SalesOrderHeader
--			GROUP BY	CustomerID
--			HAVING		SUM(CASE WHEN OrderDate >= '2012-01-01' AND OrderDate < '2013-01-01' THEN 1 ELSE 0 END) >= 2
--			),

--			oc2013	AS	(
--			SELECT		CustomerID
--			FROM		oc2012 h
--			WHERE NOT EXISTS (
--					SELECT 1
--					FROM	Sales.SalesOrderHeader h1
--					WHERE	h.CustomerID = h1.CustomerID
--						AND	OrderDate >= '2013-01-01'
--						AND	OrderDate < '2014-01-01')
--						)

--SELECT		soh.CustomerID AS [Customer #],
--			SUM(CASE WHEN soh.OrderDate >= '2012-01-01' AND OrderDate < '2013-01-01' THEN 1 ELSE 0 END) AS [2012 Order Count]
--FROM		Sales.SalesOrderHeader soh
--JOIN		oc2013	oc2	ON	soh.CustomerID = oc2.CustomerID
--GROUP BY	soh.CustomerID
--ORDER BY	soh.CustomerID;



--### Stretch 4 — The Balanced Salesperson

--A salesperson is "balanced" if no single customer accounts for more than **40% of
--their total revenue** (exclude `NULL` / online orders). Find all balanced salespersons
--and their total revenue.

WITH TotalRev AS (
    SELECT  SalesPersonID,
            SUM(TotalDue) AS TotalRevenue
    FROM    Sales.SalesOrderHeader
    WHERE   SalesPersonID IS NOT NULL
    GROUP BY SalesPersonID
),
CustRev AS (
    SELECT  SalesPersonID,
            CustomerID,
            SUM(TotalDue) AS CustomerRevenue
    FROM    Sales.SalesOrderHeader
    WHERE   SalesPersonID IS NOT NULL
    GROUP BY SalesPersonID, CustomerID
),
Shares AS (
    SELECT  c.SalesPersonID,
            c.CustomerID,
            c.CustomerRevenue * 1.0 / t.TotalRevenue AS Share
    FROM    CustRev c
    JOIN    TotalRev t ON c.SalesPersonID = t.SalesPersonID
)
SELECT  s.SalesPersonID,
        t.TotalRevenue
FROM    Shares s
JOIN    TotalRev t ON s.SalesPersonID = t.SalesPersonID
GROUP BY s.SalesPersonID, t.TotalRevenue
HAVING  MAX(Share) <= 0.40
ORDER BY s.SalesPersonID;




--*Hint: You need a subquery or CTE that calculates each salesperson's maximum
--per-customer revenue, then compares it to their overall total.*

-----

