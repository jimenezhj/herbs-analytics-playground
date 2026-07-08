--**🧠 AI-free zone — Reconstruction exercise (15 min):** Without notes, write a query that:

--1. Aggregates orders to customer-year level (customer + year + revenue).

WITH customer_revenues_year AS

(
		SELECT	CustomerID,
				YEAR(OrderDate) AS OrderYear,
				SUM(TotalDue) AS Revenue
		FROM	Sales.SalesOrderHeader
		GROUP BY	CustomerID, YEAR(OrderDate)
)

--2. Computes each customer's revenue rank within each year (highest = 1).
--3. Returns the top 5 customers per year, with their name (join to Person.Person).
--4. Sort by year, then rank.

,customer_ranking AS
(
SELECT	CustomerID,
		OrderYear,
		Revenue,
		DENSE_RANK() OVER (PARTITION BY OrderYear ORDER BY Revenue DESC) AS Ranking
FROM	customer_revenues_year
)
SELECT	cr.CustomerID,
		p.FirstName+' '+p.lastname AS CustomerName,
		cr.OrderYear,
		cr.Revenue,
		cr.Ranking
FROM	customer_ranking cr
INNER JOIN	sales.Customer c ON cr.CustomerID = c.CustomerID
INNER JOIN	person.person p ON c.PersonID = p.BusinessEntityID
WHERE	ranking <= 5
ORDER BY cr.OrderYear, cr.Ranking

