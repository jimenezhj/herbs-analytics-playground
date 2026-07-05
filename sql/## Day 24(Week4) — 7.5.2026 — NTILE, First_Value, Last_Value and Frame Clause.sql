WITH customerspend AS

(

		SELECT	CustomerID,
				SUM(Totaldue) AS Totalspend
		FROM	Sales.SalesOrderHeader
		GROUP BY	CustomerID

)

SELECT	CustomerID,
		TotalSpend,
		NTILE(4) OVER (ORDER BY Totalspend DESC) AS Quartile,
		NTILE(10) OVER (ORDER BY Totalspend DESC) AS Decile,
		NTILE(100) OVER (ORDER BY TotalSpend DESC) AS Percentile
FROM	customerspend

WITH Customerspend AS

(
		SELECT	CustomerID,
				SUM(TotalDue) AS TotalSpend
		FROM	sales.SalesOrderHeader
		GROUP BY	CustomerID
),

Quartiled AS

(
		SELECT	Customerid,
				Totalspend,
				NTILE(4) OVER (ORDER BY Totalspend DESC) AS Quartile
		FROM	Customerspend

)
SELECT	Quartile,
		COUNT(*) AS CustomerCount,
		SUM(TotalSpend) AS QuartileRevenue,
		AVG(TotalSpend) AS AvgCustomerSpend,
		MIN(TotalSpend) AS MinInQuartile,
		MAX(TotalSpend) AS MaxInQuartile
FROM	Quartiled
GROUP BY	Quartile
ORDER BY	Quartile;

SELECT	CustomerID,
		OrderDate,
		SalesOrderID,
		TotalDue,
		FIRST_VALUE(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS FirstOrderDate,
		DATEDIFF(DAY, FIRST_VALUE(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate),OrderDate) AS DaysSinceFirstOrder
FROM	Sales.SalesOrderHeader
WHERE	CustomerID IN (29825, 29672, 29734)
ORDER BY	CustomerID, OrderDate;

SELECT	CustomerID,
		OrderDate,
		TotalDue,
		LAST_VALUE(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS MostRecentOrder
FROM	Sales.SalesOrderHeader
WHERE	CustomerID IN (29825, 29672, 29734)
ORDER BY	CustomerID, OrderDate;

SELECT	
		OrderDate,
		TotalDue,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Sum3Recent,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Sum3Recent,
		AVG(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS CenteredAvg,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotaltest,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID) AS RunningTotal
FROM	Sales.SalesOrderHeader
WHERE	YEAR(OrderDate) = 2013
ORDER BY OrderDate,SalesOrderID


SELECT	
		OrderDate,
		TotalDue,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Sum3Recent,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Sum3Recent,
		AVG(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS CenteredAvg,
		SUM(TotalDue) OVER () AS GrandTotal
FROM	Sales.SalesOrderHeader
WHERE	YEAR(OrderDate) = 2013
ORDER BY OrderDate,SalesOrderID

--1. From `Sales.SalesOrderHeader`, bucket all orders into 5 quintiles by `TotalDue`. For each quintile, count orders and sum revenue. Quintile 1 = largest. (Single query with CTE.)

WITH revenue AS 
(
	SELECT	
			SUM(TotalDue) AS TotalRevenue,
			COUNT(CustomerID) AS TotalOrders,
			NTILE(5) OVER (ORDER BY SUM(TotalDue) DESC) AS Quartile
	FROM	Sales.SalesOrderHeader
	GROUP BY SalesOrderID
)
SELECT	Quartile,
		SUM(TotalRevenue) AS RevenueQuartile,
		SUM(TotalOrders) AS QuartileOrders
FROM	revenue
GROUP BY Quartile;

--2. For each customer, show their first order date, last order date, and the days between. Use `FIRST_VALUE` and `LAST_VALUE` (with the correct frame for LAST_VALUE).

WITH CustomerOrders AS
(
	SELECT	sh.CustomerID,
			p.FirstName+' '+p.LastName AS CustomerName,
			sh.OrderDate AS OrderDate
	FROM	Sales.SalesOrderHeader sh
	INNER JOIN Sales.Customer c ON sh.CustomerID = c.CustomerID
	INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
),
FirstandLast AS
(
SELECT	CustomerName,
		OrderDate,
		FIRST_VALUE(Orderdate) OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS FirstOrder,
		LAST_VALUE(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LatestOrder
FROM	CustomerOrders
)

SELECT	CustomerName,
		FirstOrder,
		LatestOrder,
		DATEDIFF(DAY,FirstOrder,LatestOrder) AS DaysBetween
FROM	FirstandLast
WHERE	OrderDate = LatestOrder

--3. From `Production.Product`, divide products into deciles by `ListPrice` (10 buckets). For each decile, show count and average price. (Filter to ListPrice > 0 before bucketing.)

WITH totals AS
(
	SELECT	productID AS ProductID,
			SUM(listprice) AS TotalListPrice
	FROM	Production.product
	WHERE	listprice > 0
	GROUP BY	ProductID
),
deciles AS
(
SELECT	productID,
		TotalListPrice,
		NTILE(10) OVER (ORDER BY TotalListPrice DESC) AS Decile
FROM	totals
)

SELECT	Decile,
		COUNT(ProductID) AS DecileCount,
		AVG(TotalListPrice) AS AvgPrice
FROM	deciles
GROUP BY Decile;

--4. For each customer's order history, show the order's TotalDue alongside the average of the 3 most recent orders (including the current). (Frame clause: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW.)

WITH Customerorders AS
(
		SELECT	sh.CustomerID AS CustomerID,
				sh.OrderDate AS OrderDate,
				sh.TotalDue AS TotalDue
		FROM	sales.SalesOrderHeader sh
)

SELECT	CustomerID,
		OrderDate,
		TotalDue,
		AVG(TotalDue) OVER (PARTITION BY CustomerID ORDER BY OrderDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS MostRecentAvg
FROM	Customerorders

		


--5. Architect-flavored: Pareto analysis. Compute customer quartiles by spend, then a query showing what % of total revenue each quartile contributes. Goal: produce a 4-row report showing Quartile, CustomerCount, QuartileRevenue, PctOfTotalRevenue. (You'll combine NTILE with SUM() OVER ().)

WITH Customerspend AS
(
	SELECT	CustomerID AS CustomerID,
			SUM(TotalDue) AS TotalRevenue
	FROM	Sales.SalesOrderHeader
	GROUP BY	CustomerID
),
quartile AS
(
	SELECT	CustomerID,
			TotalRevenue,
			NTILE(4) OVER (ORDER BY TotalRevenue DESC) AS QuartileRevenue,
			SUM(TotalRevenue) OVER () AS AllTotalRevenue
	FROM	Customerspend
	GROUP BY	CustomerID, TotalRevenue
)

SELECT		QuartileRevenue,
			COUNT(CustomerID) AS CustomerCount,
			SUM(TotalRevenue) AS TotalRevenue,
			CAST((SUM(TotalRevenue)*100.00 / AllTotalRevenue) AS decimal(38,2)) AS PctOfTotalRevenue
FROM		Quartile
GROUP BY	QuartileRevenue, Alltotalrevenue
ORDER BY	QuartileRevenue
