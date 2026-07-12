--SELECT	SCHEMA_NAME(schema_id) AS SchemaName,
--		name AS ViewName,
--		create_date,
--		modify_date
--FROM	sys.views
--ORDER BY	SchemaName, name;

--SELECT OBJECT_DEFINITION(OBJECT_ID('humanresources.vemployee'));

--SELECT	TOP 10 *
--FROM	HumanResources.vEmployee

--CREATE VIEW Sales.vw_CustomerLifetimeSummary AS
--SELECT	c.customerid,
--		p.firstname,
--		p.lastname,
--		p.firstname+' '+p.lastname AS FullName,
--		COUNT(o.SalesOrderID) AS LifetimeOrderCount,
--		ISNULL(SUM(o.totaldue),0) AS LifeTimeSpend,
--		MIN(o.OrderDate) AS FirstOrderDate,
--		MAX(o.OrderDate) AS MostRecentOrderDate
--FROM	sales.customer AS c
--INNER JOIN	person.person AS p ON c.PersonID = p.BusinessEntityID
--LEFT JOIN	sales.salesorderheader AS o ON c.customerID = o.CustomerID
--GROUP BY	c.customerid, p.firstname, p.lastname;
--GO

--SELECT TOP 20 * 
--FROM sales.vw_customerlifetimesummary
--ORDER BY LifeTimeSpend DESC;

--SELECT	FullName,
--		LifeTimeSpend,
--		NTILE(4) OVER (ORDER BY LifeTimeSPend DESC) AS Quartile
--FROM	sales.vw_customerlifetimesummary
--WHERE	lifetimeordercount > 0

--DROP VIEW sales.vw_CustomerLifetimeSummary;

--SELECT * 
--FROM	sales.vSalesPerson

--SELECT OBJECT_DEFINITION(OBJECT_ID('sales.vsalesperson'))

--CREATE VIEW Production.vw_ProductWithCategory AS

--SELECT	p.ProductID,
--		p.name AS ProductName,
--		ps.name AS SubcategoryName,
--		pc.name AS CategoryName,
--		p.listprice AS ListPrice,
--		p.Color AS Color
--FROM	Production.Product p
--INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
--INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID;
--GO

--SELECT	TOP 20 *
--FROM	Production.vw_ProductWithCategory
--ORDER BY	listprice DESC;

--CREATE VIEW Sales.vw_MonthlyRevenue AS

--SELECT	COUNT(salesorderID) AS OrderCount,
--		SUM(TotalDue) AS TotalRevenue,
--		MONTH(OrderDate) AS Month,
--		YEAR(OrderDate) AS Year
--FROM	sales.SalesOrderHeader
--GROUP BY	YEAR(OrderDate), MONTH(OrderDate) 

--SELECT	Month,
--		Year,
--		OrderCount,
--		TotalRevenue,
--		LAG(TotalRevenue,1,0) OVER (ORDER BY Year ASC, Month ASC) AS PYmonthrevenue,
--		TotalRevenue-LAG(TotalRevenue,1,0) OVER (ORDER BY Year ASC, Month ASC) AS MonthOverMonthChange
--FROM	sales.vw_MonthlyRevenue

--DROP VIEW Sales.vw_MonthlyRevenue;
--GO

--DROP VIEW Production.vw_ProductWithCategory;
--GO