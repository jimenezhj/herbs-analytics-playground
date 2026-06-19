-- A four-table join: Product → Subcategory → Category, plus filtering

SELECT
		p.name AS [Product Name],
		s.name AS [Subcategory Name],
		c.Name AS [Category Name],
		p.listprice AS [List Price],
		p.color	AS [Color]

FROM	Production.Product p
JOIN	Production.ProductSubcategory s
	ON	p.ProductSubcategoryID = s.ProductSubcategoryID
JOIN	Production.ProductCategory c
	ON	s.ProductCategoryID = c.ProductCategoryID
WHERE	p.ListPrice > 1000
ORDER BY	c.name,s.name,p.ListPrice DESC;

-- Five-table join — adding customer/person to the order/detail chain

SELECT TOP 30
		p.firstname+' '+p.lastname AS [Customer Name],
		o.orderdate AS [Order Date],
		o.salesorderid AS [Sales Order ID],
		pr.name AS [Product Name],
		d.orderqty AS [Order Qty],
		d.Linetotal AS [Line Total]
FROM	Sales.SalesOrderHeader o
INNER JOIN	Sales.SalesOrderDetail d
	ON		o.SalesOrderID = d.SalesOrderID
INNER JOIN	Production.Product pr
	ON		d.ProductID = pr.ProductID
INNER JOIN	Sales.Customer c
	ON		o.CustomerID = c.CustomerID
INNER JOIN	Person.person p
	ON		c.CustomerID = p.BusinessEntityID
WHERE	O.OrderDate >= '2013-01-01'
ORDER BY O.OrderDate DESC;

-- Aggregating across a join — total spend per product category

SELECT
		c.Name AS [Category Name],
		COUNT(DISTINCT o.SalesOrderID) AS [Unique Orders],
		SUM(d.LineTotal) AS [Total Revenue],
		AVG(d.LineTotal) AS [Average Line Value]

FROM	Sales.SalesOrderHeader AS o
INNER JOIN	Sales.SalesOrderDetail AS d
	ON		o.SalesOrderId = d.SalesOrderId
INNER JOIN	Production.Product AS pr
	ON		d.ProductID = pr.ProductID
INNER JOIN	Production.ProductSubcategory s
	ON		pr.ProductSubcategoryID = s.ProductSubcategoryID
INNER JOIN	Production.ProductCategory c
	ON		s.ProductCategoryID = c.ProductCategoryID
GROUP BY	c.name
ORDER BY	[Total Revenue] DESC;


SELECT	o.CustomerID,
		SUM(o.totalDue) AS TotalRev,
		SUM(x.Total) AS TotalExp
FROM Sales.SalesOrderHeader AS o
INNER JOIN (SELECT 
					SalesOrderID,
					SUM(LineTotal) AS Total
			FROM Sales.SalesOrderDetail
			GROUP BY SalesOrderID) AS x
			ON o.SalesOrderID = x.SalesOrderID
GROUP BY	o.CustomerID

SELECT *
FROM Sales.SalesOrderDetail


--1. Write a 3-table join: `Production.Product` → `Production.ProductInventory` (on `ProductID`) → `Production.Location` (on `LocationID`). 
--Show ProductName, LocationName, and Quantity for 20 rows, sorted by Quantity descending. (You may need to peek at the columns — `SELECT TOP 1 *` on each.)

SELECT		p.name AS [Product Name],
			l.name AS [Location Name],
			SUM(pi.quantity) AS [Quantity]
FROM		Production.Product p
INNER JOIN	Production.ProductInventory pi
	ON		p.ProductID = pi.ProductID
INNER JOIN	Production.Location l
	ON		pi.LocationID = l.LocationID
GROUP BY	p.name,l.name
ORDER BY	Quantity DESC;

--2. Build on question 1: total inventory quantity per `Location.Name` (group by location name). Sort by total quantity descending.

SELECT		l.name AS [Location Name],
			SUM(pi.quantity) AS [Quantity]
FROM		Production.Product p
INNER JOIN	Production.ProductInventory pi
	ON		p.ProductID = pi.ProductID
INNER JOIN	Production.Location l
	ON		pi.LocationID = l.LocationID
GROUP BY	l.name
ORDER BY	Quantity DESC;

--3. Four-table join: For each order in `Sales.SalesOrderHeader` from 2013, show the customer's full name (`Person.Person` via `Sales.Customer`), 
--the salesperson's last name (`Sales.SalesPerson` via `SalesPersonID`, then `Person.Person` again for the salesperson's name), the order date, and the total due. (Hint: you'll join `Person.Person` *twice* — once for customer, once for salesperson. 
--You'll need different aliases for each instance, like `cp` and `sp`.) Show 20 rows.

SELECT		--TOP 20
			cp.firstname+' '+cp.lastname AS [Customer Name],
			sp.LastName AS [Sales Person],
			o.orderdate AS [Order Date],
			o.totaldue AS [Revenue]
FROM		Sales.SalesOrderHeader o
INNER JOIN	Sales.Customer c
	ON		o.CustomerID = c.CustomerID
INNER JOIN	Person.Person cp
	ON		c.PersonID = cp.BusinessEntityID
INNER JOIN	Sales.Salesperson s
	ON		o.SalesPersonID = s.BusinessEntityID
INNER JOIN	Person.Person sp
	ON		s.BusinessEntityID = sp.BusinessEntityID
WHERE		OrderDate	>=	'2013-01-01'
	AND		OrderDate	<	'2014-01-01'
ORDER BY	Revenue DESC;


--4. From the same chain as question 3, compute total revenue per salesperson for 2013. Show salesperson's name and total revenue, sorted descending.

SELECT		TOP 20
			cp.firstname+' '+cp.lastname AS [Customer Name],
			sp.firstname+' '+sp.LastName AS [Sales Person],
			o.orderdate AS [Order Date],
			SUM(o.totaldue) AS [Revenue]
FROM		Sales.SalesOrderHeader o
INNER JOIN	Sales.Customer c
	ON		o.CustomerID = c.CustomerID
INNER JOIN	Person.Person cp
	ON		c.PersonID = cp.BusinessEntityID
INNER JOIN	Sales.Salesperson s
	ON		o.SalesPersonID = s.BusinessEntityID
INNER JOIN	Person.Person sp
	ON		s.BusinessEntityID = sp.BusinessEntityID
WHERE		OrderDate	>=	'2013-01-01'
	AND		OrderDate	<	'2014-01-01'
GROUP BY	sp.firstname,sp.LastName
ORDER BY	Revenue DESC;

--5. Predict: in question 3, will every order have a non-null salesperson? Run it. What do you find? (You may need to do this after Day 5 if INNER JOIN drops orders without salespeople.)

SELECT		COUNT(*)
FROM		Sales.SalesOrderHeader o
WHERE		OrderDate	>=	'2013-01-01'
	AND		OrderDate	<	'2014-01-01'

SELECT		COUNT(*)
FROM		Sales.SalesOrderHeader o
WHERE		SalesPersonID IS NULL
	AND		OrderDate	>=	'2013-01-01'
	AND		OrderDate	<	'2014-01-01'