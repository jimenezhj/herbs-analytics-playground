WITH product_price AS
(
	SELECT	TOP 20
			name,
			listprice
	FROM	Production.Product
	WHERE	listprice > 0
	ORDER BY	listprice DESC
)

SELECT	name,
		listprice,
		ROW_NUMBER() OVER(ORDER BY listprice DESC) AS RowNumber,
		RANK() OVER(ORDER BY listprice DESC) AS RankNumber,
		DENSE_RANK() OVER(ORDER BY listprice DESC) AS DenseRankNumber

FROM	product_price;

WITH ranked_product AS
(
	SELECT	name,
			productsubcategoryID,
			listprice,
			ROW_NUMBER() OVER(PARTITION BY productsubcategoryID ORDER BY listprice DESC) AS rankincat
	FROM	Production.Product
	WHERE	listprice > 0
)

SELECT	rankincat,
		productsubcategoryid,
		name,
		listprice
FROM	ranked_product
WHERE	rankincat <= 3
ORDER BY	ProductSubcategoryID, rankincat;


--top 5 customers by revenue per territory in 2013

WITH Customer_territory_revenue AS
(
	SELECT	Customerid,
			territoryID,
			SUM(totaldue) TotalRevenue
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(orderdate) = 2013
	GROUP BY	CustomerID,
				TerritoryID
),

ranked AS
(
	SELECT	territoryid,
			customerid,
			totalrevenue,
			ROW_NUMBER () OVER (PARTITION BY territoryid ORDER BY totalrevenue DESC) ranking
	FROM	Customer_territory_revenue
)

SELECT	r.TerritoryID,
		r.ranking,
		r.CustomerID,
		p.firstname+' '+p.lastname CustomerName,
		r.TotalRevenue
FROM	ranked r
INNER JOIN	sales.customer c ON r.CustomerID = c.CustomerID
INNER JOIN	person.Person p ON c.PersonID = p.BusinessEntityID
WHERE	ranking <= 5
ORDER BY	r.TerritoryID, r.ranking;


--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. From `Sales.SalesOrderHeader`, for each customer, find their largest single order. Show CustomerID, the SalesOrderID of their biggest order, OrderDate, and TotalDue. (This is the "top 1 per group" pattern — use `ROW_NUMBER` + WHERE rank = 1.)

WITH customerrank AS
(
SELECT	CustomerID,
		SalesOrderID,
		Orderdate,
		TotalDue,
		ROW_NUMBER () OVER (PARTITION BY CustomerID ORDER BY TotalDue DESC) PurchaseRank
FROM	sales.SalesOrderHeader
)

SELECT	CustomerID,
		SalesOrderID,
		OrderDate,
		TotalDue
FROM	CustomerRank
WHERE	PurchaseRank = 1;
	


--2. From `Sales.SalesOrderHeader` (2013-2014), rank salespeople by total revenue across both years. Use `RANK()`. Show all salespeople in rank order.

WITH totalrevenuebysalesperson AS
(
	SELECT	COALESCE(SalesPersonID, 999) salespersonid,
			SUM(totaldue) revenue
	FROM	sales.SalesOrderHeader
	WHERE	YEAR(orderdate) IN (2013,2014)
	GROUP BY	SalesPersonID
)


	SELECT	RANK() OVER (ORDER BY revenue DESC),
			salespersonid,
			revenue
	FROM	totalrevenuebysalesperson


--3. Top 3 most-expensive products per category (not subcategory — `ProductCategory`). Show CategoryName, Rank, ProductName, ListPrice. (Hint: 4-table join inside CTE, then rank, then filter.)

WITH productcategory AS
(
	SELECT	p.name productname,
			p.listprice productprice,
			pc.Name categoryname
	FROM	Production.Product p
	INNER JOIN	Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
	INNER JOIN	Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
)
,productcategoryrank AS
(
	SELECT	DENSE_RANK() OVER (PARTITION BY categoryname ORDER BY productprice DESC) rankbycategory,
			categoryname,
			productname,
			productprice
	FROM	productcategory
)
SELECT	*
FROM	productcategoryrank pcr
WHERE	pcr.rankbycategory <= 3

--4. Find each customer's most recent order (top 1 per customer ordered by `OrderDate DESC`). Show customer name + most recent order date + that order's TotalDue.
WITH ranking AS
(
	SELECT	RANK() OVER (PARTITION BY soh.CustomerID ORDER BY soh.OrderDate DESC) mostrecentorder,
			soh.orderdate,
			soh.customerid,
			soh.totaldue
	FROM	sales.SalesOrderHeader soh
)

SELECT	p.firstname+' '+p.lastname customername,
		r.OrderDate,
		r.totaldue
FROM	ranking r
INNER JOIN	sales.customer c ON r.CustomerID = c.CustomerID
INNER JOIN	person.person p ON c.PersonID = p.BusinessEntityID
WHERE	r.mostrecentorder = 1


--5. Stretch: Find the second-largest order amount for each customer (rank = 2). Some customers will have only one order — they shouldn't appear. 
WITH ranking AS 
(
	SELECT	RANK() OVER (PARTITION BY soh.CustomerID ORDER BY soh.Totaldue DESC) secondlargestorder,
			soh.orderdate,
			soh.customerid,
			soh.totaldue
	FROM	sales.SalesOrderHeader soh
)


SELECT	p.firstname+' '+p.lastname customername,
		r.OrderDate,
		r.totaldue
FROM	ranking r
INNER JOIN	sales.customer c ON r.CustomerID = c.CustomerID
INNER JOIN	person.person p ON c.PersonID = p.BusinessEntityID
WHERE	r.secondlargestorder = 2

--**Daily commit:** `week-04/day-02.sql`.

--**You Win Today If:** "Top N per group" is now reflex, not struggle. You can write the pattern (CTE with ranking → filter in outer query) without notes. You understand when `RANK` differs from `ROW_NUMBER`.
