
--1.  FRESH 3 (build the self-join chain — parallels the customer/salesperson problem):
-- Sales.SalesOrderHeader has BOTH BillToAddressID and ShipToAddressID,
-- and both point to Person.Address. Join Person.Address TWICE with
-- different aliases (e.g. ba, sa). For 20 orders from 2013, show:
-- SalesOrderID, bill-to City, ship-to City, TotalDue.

SELECT		TOP 20
			soh.SalesOrderID AS [Sales Order ID],
			ba.City AS [Bill to City],
			sa.City AS [Ship to City],
			soh.TotalDue AS [Total Amount Due]
FROM		Sales.SalesOrderHeader AS soh
INNER JOIN	Person.Address ba
	ON		soh.BillToAddressID = ba.AddressID
INNER JOIN	Person.Address sa
	ON		soh.ShipToAddressID = sa.AddressID
WHERE		Orderdate >= '2013-01-01'
	AND		orderdate	< '2014-01-01'
ORDER BY	[Total Amount Due] DESC;



--2.  FRESH 4 (aggregate over the chain — parallels "revenue per salesperson"):
-- Extend the ship-to side one more table to Person.StateProvince for the
-- state name. Total revenue (SUM of TotalDue) per ship-to STATE for 2013,
-- state name + total, sorted descending.
-- (No fan-out here: one ship-to address per order, so SUM is safe.)

SELECT		TOP 20
			st.StateProvinceCode AS [State / Province],
			SUM(soh.TotalDue) AS [Total Amount Due]
FROM		Sales.SalesOrderHeader AS soh
INNER JOIN	Person.Address sa
	ON		soh.ShipToAddressID = sa.AddressID
INNER JOIN	Person.StateProvince st
	ON		sa.StateProvinceID = st.StateProvinceID
WHERE		Orderdate >= '2013-01-01'
	AND		orderdate	< '2014-01-01'
GROUP BY	st.StateProvinceID, st.StateProvinceCode
ORDER BY	[Total Amount Due] DESC;



--3.  FRESH 5 (do this TOMORROW when you start Day 5 — it's a Day-5 concept):
-- Go back to your ORIGINAL Problem 3 query (customer + salesperson).
-- Change the salesperson INNER JOIN to a LEFT JOIN and re-run.
-- Watch the online orders (NULL salesperson) reappear. THAT is what
-- Problem 5 was really asking, and what LEFT JOIN is for.

--ORIGINAL PROBLEM Four-table join: For each order in `Sales.SalesOrderHeader` from 2013, show the customer's full name (`Person.Person` via `Sales.Customer`), the salesperson's last name (`Sales.SalesPerson` via `SalesPersonID`, 
--then `Person.Person` again for the salesperson's name), 
--the order date, and the total due. (Hint: you'll join `Person.Person` *twice* — once for customer, once for salesperson. 
--You'll need different aliases for each instance, like `cp` and `sp`.) Show 20 rows.

SELECT		TOP 20
			cust.firstname,
			cust.LastName,
			COALESCE(sale.LastName, 'Online') AS SalesPerson,
			soh.OrderDate,
			soh.TotalDue
FROM		Sales.SalesOrderHeader AS soh
LEFT JOIN	Sales.Customer AS c
	ON		soh.CustomerID = c.CustomerID
INNER JOIN	Person.Person AS cust
	ON		c.PersonID	= cust.BusinessEntityID
LEFT JOIN	Sales.SalesPerson sp
	ON		soh.SalesPersonID = sp.BusinessEntityID
LEFT JOIN	Person.Person AS sale
	ON		sp.BusinessEntityID = sale.BusinessEntityID
WHERE		SOH.Orderdate >= '2013-01-01'
	AND		SOH.orderdate	< '2014-01-01'
ORDER BY	soh.TotalDue DESC;


-- INNER JOIN: only products that have a subcategory (the matched set)

SELECT
		p.name,
		s.name AS SubcategoryName
FROM	Production.Product p
INNER JOIN	Production.ProductSubcategory s
	ON		p.ProductSubcategoryID = s.ProductSubcategoryID;

-- LEFT JOIN: all products, with subcategory if it exists	
SELECT
		p.name,
		s.name AS SubcategoryName
FROM	Production.Product p
LEFT JOIN	Production.ProductSubcategory s
	ON		p.ProductSubcategoryID = s.ProductSubcategoryID;

-- THE MISSING ROWS PATTERN — products with NO subcategory
SELECT
		p.productid,
		p.name,
		p.listprice
FROM	Production.Product AS p
LEFT JOIN	Production.ProductSubcategory AS s
	ON		p.ProductSubcategoryID = s.ProductSubcategoryID
WHERE	s.ProductSubcategoryID IS NULL;

-- Same pattern, business-relevant question:
-- Which customers have NEVER placed an order?

SELECT
		c.customerid,
		c.accountnumber
FROM	sales.customer AS c
LEFT JOIN	Sales.SalesOrderHeader AS o
	ON		c.CustomerID = o.CustomerID
WHERE	o.SalesOrderID IS NULL;

SELECT
		c.customerid,
		count(*) AS ordercount,
		SUM(o.totaldue) AS revenue
FROM	sales.customer AS c
LEFT JOIN	sales.salesorderheader AS o
	ON		c.customerid = o.customerid
WHERE		c.customerid = 392
GROUP BY	c.customerid
ORDER BY	ordercount DESC;

SELECT
		c.customerid,
		count(o.salesorderid) AS ordercount,
		SUM(o.totaldue) AS revenue
FROM	sales.customer AS c
LEFT JOIN	sales.salesorderheader AS o
	ON		c.customerid = o.customerid
WHERE		c.customerid = 392
GROUP BY	c.customerid
ORDER BY	ordercount DESC;

--**🧠 AI-free zone — Self-test (30 min):** No AI. These are the most important self-test problems of the week:

--1. Find every product in `Production.Product` that has no corresponding row in `Production.ProductInventory` (i.e., products that are not inventoried anywhere). Show ProductID and Name.

SELECT	p.productID,
		p.name
FROM	Production.product p
LEFT JOIN	Production.ProductInventory pi
	ON		p.ProductID = pi.ProductID
WHERE	pi.ProductID IS NULL;


--2. Find every salesperson in `Sales.SalesPerson` who has zero orders in `Sales.SalesOrderHeader`. Show their `BusinessEntityID`. (Hint: the link is `SalesOrderHeader.SalesPersonID = SalesPerson.BusinessEntityID`.)

SELECT	s.BusinessEntityID,
		COUNT(soh.salesorderid) AS TotalORders
FROM	sales.salesperson AS s
LEFT JOIN	Sales.SalesOrderHeader AS soh
	ON		s.BusinessEntityID = soh.SalesPersonID
GROUP BY	s.BusinessEntityID
HAVING		COUNT(soh.salesorderid) = 0
ORDER BY	TotalORders ASC;

--3. From `Sales.Customer` joined LEFT JOIN to `Sales.SalesOrderHeader`, count orders per customer, including customers with zero orders. Use the careful `COUNT(o.SalesOrderID)` pattern. Show only customers with 0 orders.

SELECT	c.customerID
		--COUNT(soh.salesorderid)	AS OrderCount
FROM	sales.SalesOrderHeader AS soh
RIGHT JOIN	sales.customer AS c
	ON		soh.CustomerID = c.CustomerID
GROUP BY	c.CustomerID
HAVING		COUNT(soh.salesorderid)	= 0;

--4. Find products that have a subcategory assigned but where that subcategory has no parent category. Use two LEFT JOINs. (Spoiler: there are none — but write the query that would find them. This is the kind of data-quality check architects write all the time.)

SELECT	p.ProductID, ps.ProductSubcategoryID
FROM	Production.Product AS p
LEFT JOIN	Production.ProductSubcategory ps
	ON		p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN	Production.ProductCategory pc
	ON		ps.ProductCategoryID = pc.ProductCategoryID
WHERE		ps.ProductSubcategoryID IS NOT NULL
	AND		pc.ProductCategoryID IS NULL;

--5. Real architect-flavored question: Write a query that shows, for every salesperson in `Sales.SalesPerson`, 
--the salesperson's name (joined from `Person.Person`) and their total revenue (`SUM(TotalDue)` from `SalesOrderHeader`). Include salespeople with zero revenue. Sort by total revenue descending — zero-revenue salespeople last.

SELECT	p.firstname,
		p.lastname,
		SUM(soh.totaldue) AS TotalRevenue
FROM	Sales.SalesPerson AS sp
LEFT JOIN Person.Person AS p
	ON	sp.BusinessEntityID = p.BusinessEntityID
LEFT JOIN	sales.SalesOrderHeader AS soh
	ON		sp.BusinessEntityID = soh.SalesPersonID
GROUP BY	p.firstname,
			p.lastname
ORDER BY	TotalRevenue DESC;



