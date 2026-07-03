WITH yearly_revenue AS

(	
SELECT	YEAR(Orderdate) [Year],
			SUM(totaldue) [Revenue]
	FROM	sales.SalesOrderHeader
	GROUP BY	YEAR(orderdate)
)

SELECT	Year,
		Revenue,
		COALESCE(LAG(Revenue) OVER (ORDER BY Year),0) [PY rev],
		COALESCE(Revenue-LAG(Revenue) OVER (ORDER BY Year),0) [YoY],
		COALESCE(CAST (
				(Revenue-LAG(Revenue) OVER (ORDER BY Year))*100 / LAG(Revenue) OVER (ORDER BY Year)
				AS decimal(38,2)
			 ),100) [Growth]
FROM	yearly_revenue
ORDER BY	Year


WITH monthly_revenue AS

(
SELECT	YEAR(orderdate) [Year],
		MONTH(orderdate) [Month],
		SUM(totaldue) [Revenue]
FROM	sales.SalesOrderHeader
GROUP BY	YEAR(orderdate),
			MONTH(orderdate)
)

SELECT	Year,
		Month,
		Revenue,
		LAG(Revenue) OVER (ORDER BY Year, month) [PY Month],
		Revenue - LAG(Revenue) OVER (ORDER BY Year, month) [MOM change]
FROM	monthly_revenue
ORDER BY	year,month;

WITH yearly_territory_revenue AS

(
	SELECT	territoryid,
			YEAR(orderdate) [YEAR],
			SUM(totaldue) [REVENUE]
	FROM	sales.SalesOrderHeader
	GROUP BY	TerritoryID, YEAR(orderdate)

)

SELECT	TerritoryID,
		Year,
		Revenue,
		LAG(Revenue) OVER (PARTITION BY territoryID ORDER BY Year) [PYRev],
		Revenue - LAG(Revenue) OVER (PARTITION BY territoryID ORDER BY Year) [Rev Change]
FROM	yearly_territory_revenue
ORDER BY	TerritoryID, YEAR

SELECT	Year,
		Month,
		Revenue,
		LAG(Revenue,1) OVER (ORDER BY Year, Month) [PY mth],
		LAG(Revenue,12) OVER (ORDER BY Year, Month) [Sameperiodlastyear]

FROM	(
			SELECT	YEAR(OrderDate) [Year],
					MONTH(Orderdate) [Month],
					SUM(totaldue) [Revenue]
			FROM	sales.SalesOrderHeader
			GROUP BY	YEAR(OrderDate),
						MONTH(Orderdate)
		) Monthly
ORDER BY	Year, Month;


SELECT	TOP 50
		CustomerID,
		SalesOrderId,
		OrderDate,
		LEAD (Orderdate) OVER (PARTITION BY CustomerID ORDER BY Orderdate) [NextOrderDate],
		DATEDIFF(DAY, Orderdate,LEAD (Orderdate) OVER (PARTITION BY CustomerID ORDER BY Orderdate)) [DaysToNextOrder]
FROM	sales.SalesOrderHeader
ORDER BY	CustomerID, OrderDate;


WITH yearly_revenue AS

(
	SELECT	YEAR(OrderDate) [Year],
			SUM(totaldue) [Revenue]
	FROM	sales.SalesOrderHeader
	GROUP BY	YEAR(OrderDate)
)

SELECT	Year,
		Revenue,
		LAG(Revenue,1,0) OVER (ORDER BY Year) AS PYRevenue,
		Revenue-LAG(Revenue,1,0) OVER (ORDER BY Year) AS PYChange,
		COALESCE((Revenue-LAG(Revenue,1) OVER (ORDER BY Year))*100 / LAG(Revenue,1) OVER (ORDER BY Year),100) AS PcrtChange
FROM	yearly_revenue


--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. From `Sales.SalesOrderHeader`, build a per-quarter revenue table. Add a column showing prior quarter's revenue, and a column showing the dollar change. (One CTE for the quarterly aggregation, one outer SELECT with `LAG`.)

WITH quarterly_revenue AS 
(
	SELECT	'Q'+CAST(DATEPART(QUARTER,Orderdate) AS VARCHAR) [Quarter],
			YEAR(OrderDate) [Year],
			SUM(totaldue) [Revenue]
	FROM	sales.SalesOrderHeader
	GROUP BY	'Q'+CAST(DATEPART(QUARTER,Orderdate) AS VARCHAR),
				YEAR(OrderDate)
)

SELECT	Quarter,
		Year,
		Revenue,
		LAG(Revenue,1,0) OVER (ORDER BY Year, Quarter) [PY Qtr Rev],
		Revenue-LAG(Revenue,1,0) OVER (ORDER BY Year, Quarter) [Change]
FROM	quarterly_revenue;


--2. For each customer with 2+ orders, show their second order's date and the days since their first order (gap between first and second). (Hint: use `LAG` inside a CTE that ranks each customer's orders by date, then filter to rank 2.)

WITH CustomerOrders AS

(
	SELECT	CustomerID,
			COUNT(CustomerID) AS Orders
	FROM	sales.SalesOrderHeader
	GROUP BY	CustomerID
	HAVING	COUNT(CustomerID) >= 2
),

CustomerOrderDates AS

(

	SELECT	co.CustomerID AS CustomerID,
			RANK() OVER (PARTITION BY co.CustomerID ORDER BY soh.orderdate ASC) AS OrderRank,
			soh.OrderDate AS OrderDates,
			LAG(soh.OrderDate,1,soh.OrderDate) OVER (PARTITION BY co.CustomerID ORDER BY soh.OrderDate) AS FirstOrderDate,
			DATEDIFF(DAY,LAG(soh.OrderDate,1,soh.OrderDate) OVER (PARTITION BY co.CustomerID ORDER BY soh.OrderDate),soh.OrderDate) AS DaysSinceFirstOrder
	FROM	CustomerOrders co
	INNER JOIN Sales.SalesOrderHeader soh ON co.CustomerID = soh.CustomerID
)

SELECT	*
FROM	CustomerOrderDates
WHERE	OrderRank = 2
ORDER BY	CustomerID


--3. Quarterly revenue per `TerritoryID` from 2011-2014, with the same quarter's revenue last year (Q1 2014 → Q1 2013). Hint: `LAG(Revenue, 4)` if ordered by Year, Quarter. Show Territory, Year, Quarter, Revenue, SameQuarterLastYear, YoYChange.

WITH	QtrRevTerrID AS
(
	SELECT	territoryID,
			'Q'+CAST(DATEPART(QUARTER,OrderDate) AS Varchar)  AS Quarter,
			YEAR(OrderDate) AS Year,
			SUM(TotalDue) AS Revenue
	FROM	sales.SalesOrderHeader
	GROUP BY	territoryID,
				'Q'+CAST(DATEPART(QUARTER,OrderDate) AS varchar),
				YEAR(OrderDate)
	
),

SameQtrRev AS

(
	SELECT	TerritoryID,
			Year,
			Quarter,
			Revenue,
			LAG(Revenue,4,0) OVER (PARTITION BY TerritoryID ORDER BY YEAR, QUARTER) AS SameQtrLastYear,
			Revenue - LAG(Revenue,4,0) OVER (PARTITION BY TerritoryID ORDER BY YEAR, QUARTER) AS YoYChange
	FROM	QtrRevTerrID
)

SELECT	st.name AS Territory,
		sqt.Year,
		sqt.Quarter,
		sqt.Revenue,
		sqt.SameQtrLastYear,
		sqt.YoYChange
FROM	SameQtrRev sqt
INNER JOIN	sales.SalesTerritory st ON sqt.TerritoryID = ST.TerritoryID

--4. Find every customer whose latest order was more than 365 days after their previous order (lapsed and returned). Use LAG. Show customer name + the two order dates + gap.

WITH CustomerOrders AS 

(
		SELECT	soh.CustomerID AS 'Customer ID',
				p.FirstName+' '+p.LastName AS 'Customer Name',
				soh.OrderDate 'Order Date'
		FROM	sales.SalesOrderHeader soh
		INNER JOIN sales.customer c ON soh.CustomerID = c.CustomerID
		INNER JOIN person.person p ON c.PersonID = p.BusinessEntityID
),

OrderRank AS
(
SELECT	RANK() OVER (PARTITION BY [Customer ID] ORDER BY [Order Date]) AS 'Order Rank',
		[Customer Name],
		[Order Date],
		LAG([Order Date],1,[Order Date]) OVER (PARTITION BY [Customer ID] ORDER BY [Order Date]) AS 'Last Order',
		DATEDIFF(DAY,LAG([Order Date],1,[Order Date]) OVER (PARTITION BY [Customer ID] ORDER BY [Order Date]),[Order Date]) AS 'Lapsed Since Last Order'
FROM	CustomerOrders
)

SELECT	*
FROM	OrderRank
WHERE	[Order Rank] > 1
	AND	[Lapsed Since Last Order] > 365


--5. Reflection: Why must `LAG`/`LEAD` use `ORDER BY` inside `OVER()`? What happens if you forget it? (Try it and observe — write a 1-sentence answer.)
--Creates an error and wont let you use LAG since it doesnt know what to compare without ORDER BY