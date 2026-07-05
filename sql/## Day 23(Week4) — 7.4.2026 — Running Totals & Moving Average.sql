SELECT	OrderDate,
		SalesOrderID,
		TotalDue,
		SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID) AS RunningTotal
FROM	sales.SalesOrderHeader
WHERE	YEAR(OrderDate) = 2013
ORDER BY	OrderDate, SalesOrderID;

WITH Monthly AS

(
		SELECT	YEAR(OrderDate) AS Year,
				MONTH(OrderDate) AS Month,
				SUM(totaldue) AS Revenue
		FROM	sales.SalesOrderHeader
		GROUP BY	YEAR(orderdate),
					MONTH(orderdate)
)

SELECT	Year,
		Month,
		Revenue,
		SUM(Revenue) OVER (PARTITION BY Year ORDER BY Month) AS YTD_revenue
FROM	Monthly;


WITH Monthly AS

(
		SELECT	YEAR(OrderDate) AS Year,
				MONTH(OrderDate) AS Month,
				SUM(totaldue) AS Revenue
		FROM	sales.SalesOrderHeader
		GROUP BY	YEAR(orderdate),
					MONTH(orderdate)
)

SELECT	Year,
		Month,
		Revenue,
		SUM(Revenue) OVER (ORDER BY Year, Month) AS YTD_revenue
FROM	Monthly;

SELECT	CustomerId,
		OrderDate,
		SalesOrderId,
		TotalDue,
		SUM(TotalDue) OVER (PARTITION BY CustomerID ORDER BY OrderDate, SalesOrderId) AS CummulativeRev
FROM	sales.SalesOrderHeader
WHERE	CustomerID IN (29825, 29672, 29734)
ORDER BY	CustomerID, OrderDate;

WITH Monthly AS

(
	SELECT	YEAR(OrderDate) AS Year,
			MONTH(OrderDate) AS Month,
			SUM(Totaldue) AS MonthlyRevenue
	FROM	sales.SalesOrderHeader
	GROUP BY	YEAR(OrderDate), MONTH(OrderDate)
)

SELECT	Year,
		Month,
		MonthlyRevenue,
		AVG(MonthlyRevenue) OVER (ORDER BY Year, Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ThreeMonthMovingAvg

FROM	Monthly
ORDER BY Year,Month


WITH Yearly AS

(	
		SELECT	YEAR(OrderDate) AS Year,
				SUM(TotalDue) AS Revenue
		FROM	Sales.SalesOrderHeader
		GROUP BY	YEAR(OrderDate)

)

SELECT	Year,
		Revenue,
		SUM(Revenue) OVER (ORDER BY Year) AS Runningtotal,
		SUM(Revenue) OVER () AS GrandTotal,
		Revenue * 100 / SUM(Revenue) OVER () AS PctOfTotal
FROM	Yearly
ORDER BY	Year

SELECT TOP 30
    OrderDate,
    SalesOrderID,
    TotalDue,
    SUM(TotalDue) OVER (ORDER BY OrderDate) AS Running_RANGE_default,
    SUM(TotalDue) OVER (ORDER BY OrderDate ROWS UNBOUNDED PRECEDING) AS Running_ROWS
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013
ORDER BY OrderDate, SalesOrderID;

--1. From `Sales.SalesOrderHeader`, compute a daily revenue series for 2013 with a running cumulative total. Columns: OrderDate, DailyRevenue, CumulativeRevenue.

WITH dailyrevenue AS

(
	SELECT	SalesOrderID,
			OrderDate,
			Totaldue AS Revenue

	FROM	Sales.SalesOrderHeader
	WHERE	Year(OrderDate) = 2013
)

SELECT	SalesOrderId,
		OrderDate,
		Revenue AS DailyRevenue,
		SUM(Revenue) OVER (ORDER BY OrderDate, SalesOrderID) AS CumulativeRevenue

FROM	dailyrevenue;

--2. Year-to-date revenue by quarter — `Year`, `Quarter`, `QuarterlyRevenue`, `YTDRevenue` (resetting each year).

WITH TotalRevenue AS

(
		SELECT	YEAR(OrderDate) AS Year,
				'Q' + CAST(DATEPART(QUARTER,OrderDate) AS varchar) AS Quarter,
				SUM(TotalDue) AS Revenue
		FROM	Sales.SalesOrderHeader
		GROUP BY	YEAR(OrderDate),'Q' + CAST(DATEPART(QUARTER,OrderDate) AS varchar)
)

SELECT	Year,
		Quarter,
		Revenue AS QuarterlyRevenue,
		SUM(Revenue) OVER (PARTITION BY Year ORDER BY Quarter) AS YTDRevenue
FROM	TotalRevenue

--3. For each customer with 3+ orders, show order-by-order cumulative spend. Show CustomerID, OrderDate, TotalDue, CustomerRunningTotal. Only top 50 rows.

WITH CustomerSpend AS

(
		SELECT	CustomerID,
				COUNT(CustomerID) AS NumberOfOrders
		FROM	Sales.SalesOrderHeader
		GROUP BY	CustomerID
		HAVING	COUNT(CustomerID) >= 3
)

SELECT	TOP 50
		cs.CustomerID,
		soh.OrderDate,
		soh.TotalDue,
		SUM(soh.totaldue) OVER (PARTITION BY cs.CustomerID ORDER BY soh.OrderDate) AS CustomerRunningTotal
FROM	CustomerSpend AS cs
INNER JOIN	Sales.SalesOrderHeader soh ON cs.CustomerID = soh.CustomerID
		


--4. % of category total: For each product, show its `ListPrice` as a percentage of total ListPrice within its `ProductCategory`. (4-table join + window function.)

WITH productcategory AS

(
	SELECT	pc.name AS Category,
			p.name AS Product,
			p.listprice AS Price
	FROM	Production.Product p
	INNER JOIN Production.ProductSubcategory AS ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
	INNER JOIN Production.Productcategory AS pc ON ps.ProductcategoryID = pc.ProductcategoryID
)

SELECT	Category,
		Product,
		Price,
		SUM(Price) OVER (PARTITION BY Category) AS TotalPerCategory,
		CAST(Price*100.00 / SUM(Price) OVER (PARTITION BY Category) AS decimal(38,2)) AS PctOfCat
FROM	productcategory;


--5. 6-month moving average of monthly revenue across the entire timeline (not partitioned by year — one continuous moving average). Show Year, Month, MonthlyRevenue, SixMonthMovingAvg.

WITH totals AS

(
		SELECT	YEAR(OrderDate) AS Year,
				MONTH(OrderDate) AS Month,
				SUM(TotalDue) AS Revenue
		FROM	sales.SalesOrderHeader
		GROUP BY	YEAR(OrderDate), MONTH(OrderDate)
)

SELECT	Year,
		Month,
		Revenue AS MonthlyRevenue,
		SUM(Revenue) OVER (ORDER BY Year, Month) AS Overallrunningtotal,
		AVG(Revenue) OVER (ORDER BY Year, Month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS SixMonthAverage
FROM	totals