--USE AdventureWorks2022;
--GO

--SELECT	SCHEMA_NAME(schema_id) AS SchemaName,
--		name AS ProcName,
--		create_date
--FROM	sys.procedures
--ORDER BY	SchemaName, name;


--SELECT OBJECT_DEFINITION(OBJECT_ID('HumanResources.uspUpdateEmployeePersonalInfo'));

--CREATE PROCEDURE	sales.usp_GetCustomerOrders
--					@CustomerID INT

--AS
--BEGIN
--	SET NOCOUNT ON; --suppress "x rows affeted" messages

--	SELECT	SalesOrderId,
--			OrderDate,
--			TotalDue,
--			Status
--	FROM	Sales.SalesOrderHeader
--	WHERE	CustomerID = @CustomerID
--	ORDER BY	OrderDate DESC;

--END;
--GO

--EXEC Sales.usp_GetCustomerOrders @CustomerID = 29825
--EXEC Sales.usp_GetCustomerOrders @CustomerID = 29672

--CREATE PROCEDURE	Sales.usp_GetTopCustomers
--					@TopN INT = 10,
--					@MinSpend MONEY = 0

--AS
--BEGIN
--	SET NOCOUNT ON;

--	SELECT	TOP (@TopN)
--			c.CustomerId,
--			p.firstname+' '+p.lastname AS FullName,
--			SUM(o.TotalDue) AS LifeTimeSpend
--	FROM	Sales.SalesOrderHeader o
--	INNER JOIN	sales.Customer c ON o.CustomerID = c.CustomerID
--	INNER JOIN	person.person p ON c.PersonID = p.BusinessEntityID
--	GROUP BY	c.CustomerID, p.FirstName, p.LastName
--	HAVING	SUM(o.TotalDue) >= @MinSpend
--	ORDER BY	LifeTimeSpend DESC;
--END;
--GO

--EXEC sales.usp_GetTopCustomers

--EXEC Sales.Usp_GetTopCustomers @TopN = 20;

--EXEC Sales.Usp_GetTopCustomers @TopN = 5, @MinSpend = 100000

--DROP PROCEDURE sales.usp_GetCustomerOrders;
--DROP PROCEDURE sales.usp_GetTopCutomers;



--SELECT OBJECT_DEFINITION(OBJECT_ID('HumanResources.uspUpdateEmployeeHireInfo'));


--Create a procedure `Sales.usp_GetOrdersByDateRange` that takes `@StartDate DATE` and `@EndDate DATE` and returns orders in that range, with columns: SalesOrderID, OrderDate, CustomerID, TotalDue. Sort by OrderDate. Call it with date range '2013-01-01' to '2013-03-31'.
--CREATE PROCEDURE Sales.usp_GetOrdersByDateRange
--@StartDate	Date,
--@EndDate	Date

--AS
--	BEGIN
--	SET NOCOUNT ON;

--	SELECT	SalesOrderId,
--			OrderDate,
--			CustomerId,
--			TotalDue
--	FROM	sales.SalesOrderHeader
--	WHERE	OrderDate >= @StartDate
--		AND	OrderDate < @EndDate
--	ORDER BY	OrderDate
--END;
--GO

--EXEC sales.usp_GetOrdersByDateRange	@StartDate = '2013-01-01', @EndDate = '2013-04-01'

--Create a procedure `Sales.usp_GetCustomerSummary` that takes `@CustomerID INT` and returns a single row with: customer name, lifetime order count, lifetime spend, first order date, most recent order date. (Hint: this is basically yesterday's view, but parameterized to one customer.)

--CREATE PROCEDURE Sales.usp_GetCustomerSummary
--@CustomerID INT

--AS
--	BEGIN
--	SET NOCOUNT ON;

--	SELECT	p.firstname+' '+p.LastName AS CustomerName,
--			COUNT(o.CustomerID) AS LifeTimeOrderCount,
--			SUM(o.totaldue) AS LifeTimeSpend,
--			MIN(o.OrderDate) AS FirstOrderDate,
--			MAX(o.OrderDate) AS MostRecentOrderDate
--	FROM	sales.salesOrderHeader o
--	INNER JOIN	sales.customer c ON o.CustomerID = c.CustomerID
--	INNER JOIN	Person.Person p ON c.PersonID = p.BusinessEntityID
--	WHERE	o.CustomerID = @CustomerID
--	GROUP BY o.CustomerID, p.FirstName, p.LastName;
--END;
--GO

--EXEC sales.usp_GetCustomerSummary @CustomerID = 29826
--Drop the procedures you created.

--DROP PROCEDURE sales.usp_GetOrdersByDateRange
--DROP PROCEDURE sales.usp_GetCustomerSummary