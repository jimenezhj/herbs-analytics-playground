-- The orders table (note: it has CustomerID but not customer details)

SELECT	TOP 20
		p.FirstName+' '+p.LastName AS FullName,
		o.SalesOrderID,
		o.OrderDate,
		o.TotalDue,
		c.AccountNumber,
		c.TerritoryID
FROM	Sales.SalesOrderHeader o
JOIN	Sales.Customer	c 
	ON	o.CustomerID = c.CustomerID
JOIN	Person.Person	p
	ON	c.CustomerID = p.BusinessEntityID
ORDER BY	OrderDate DESC;

-- Top customers by total spend in 2013, with names
SELECT	p.Firstname,
		p.lastname,
		COUNT(*) AS Ordercount,
		SUM(o.totaldue) AS Totalspend

FROM	Sales.SalesOrderHeader o
--JOIN	Sales.Customer c
--	ON	o.CustomerID = c.CustomerID
JOIN	Person.Person p
	ON	o.CustomerID = p.BusinessEntityID
WHERE	Year(Orderdate) = 2013
GROUP BY	p.firstname, p.lastname
HAVING	SUM(o.totaldue) > 5000
ORDER BY	Totalspend DESC;

--1. Write an INNER JOIN between `Production.Product` (`p`) and `Production.ProductSubcategory` (`s`) on the matching `ProductSubcategoryID`. 
--Show ProductName, SubcategoryName, and ListPrice for 10 rows. (You may need to explore the column names; `SELECT TOP 1 * FROM Production.ProductSubcategory` will show you.)

SELECT	p.name AS productname,
		s.name AS subcategoryname,
		p.listprice
FROM	Production.Product p
JOIN	Production.ProductSubcategory s
	ON	p.ProductSubcategoryID = s.ProductSubcategoryID
ORDER BY	p.ListPrice DESC;


--2. Extend question 1 to also join `Production.ProductCategory` (`c`) to get the category name. 
--The link: `ProductSubcategory.ProductCategoryID = ProductCategory.ProductCategoryID`. Show ProductName, SubcategoryName, CategoryName, ListPrice.

SELECT	p.name AS [Product Name],
		c.name AS [Category Name],
		s.name AS [Subcategory Name],
		p.listprice AS [Price]
FROM	Production.Product p
JOIN	Production.ProductSubcategory s
	ON	p.ProductSubcategoryID = s.ProductSubcategoryID
JOIN	Production.ProductCategory c
	ON	s.ProductCategoryID = c.ProductCategoryID
ORDER BY ListPrice DESC;

--3. From `Sales.SalesOrderHeader` joined to `Sales.SalesOrderDetail` (on `SalesOrderID`), 
--show 20 rows with OrderDate, ProductID, OrderQty, and LineTotal. (`SalesOrderDetail` has the line-item data; `SalesOrderHeader` has the per-order data.)


SELECT	TOP 20 p.OrderDate AS [Order Date],
		d.ProductID AS [Product Code],
		d.orderqty	AS [Order Qty],
		d.linetotal AS [Total price]
FROM	Sales.SalesOrderHeader p
JOIN	Sales.SalesOrderDetail d
	ON	p.SalesOrderID = d.SalesOrderID
ORDER BY	[Total price] DESC;


--4. Show top 10 customers by total spend across all years. Include their first and last names.
--(Three-table join, group by name, order by SUM(TotalDue) descending.)

SELECT	TOP 10 p.Firstname,
		p.lastname,
		YEAR(o.orderdate) AS [Year],
		SUM(o.totaldue) AS [Total Spend]
FROM	Sales.SalesOrderheader o
JOIN	Sales.Customer c
	ON	o.CustomerID = c.CustomerID
JOIN	Person.Person p
	ON	c.CustomerID = P.BusinessEntityID
GROUP BY p.FirstName, p.LastName, YEAR(o.orderdate)
ORDER BY [Total Spend] DESC;



--5. Predict: if you join `Sales.SalesOrderHeader` to `Sales.Customer` and there are customers in the Customer table who have never placed an order, 
--will those customers appear in your INNER JOIN result? Why or why not? Write a 1-sentence answer in a comment. 
-- it will not show, because sales order header only shows you customers that actually placed an order so any one who never placed an order will not match from the customer table.