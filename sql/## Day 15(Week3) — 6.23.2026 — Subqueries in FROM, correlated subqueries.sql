--**🧠 AI-free zone — WARM REP — Day 2. AI-free. Correlated subquery:**
-- Schema-check with SELECT TOP 1 * if a column is unfamiliar (not AI).
--
-- Find every product whose ListPrice is BELOW the average ListPrice of
-- its OWN subcategory. Return: Name, ProductSubcategoryID, ListPrice.
-- Exclude products with ListPrice = 0 and NULL subcategory.
-- (This is the mirror of yesterday's Q1 — "below" instead of "above" —
--  so the structure is the same correlated pattern, flipped.)

select top 1 * from Production.ProductSubcategory
exec sp_help 'production.productsubcategory'


SELECT	p.name,
		p.ProductSubcategoryID,
		p.listprice
FROM	Production.product p
INNER JOIN (SELECT	p.ProductSubcategoryID AS subcat,
				AVG(p.listprice) AS avglpbysubcat
		FROM	Production.Product p
		WHERE	listprice > 0
		GROUP BY	p.ProductSubcategoryID) x ON p.productsubcategoryID = x.subcat
WHERE	p.ProductSubcategoryID IS NOT NULL
	AND	p.ListPrice < x.avglpbysubcat
ORDER BY p.ProductSubcategoryID ASC;	


SELECT	p.name,
		p.ListPrice,
		x.avglpbysubcat
FROM
	(SELECT	p.ProductSubcategoryID AS subcat,
			AVG(p.listprice) AS avglpbysubcat
			FROM	Production.Product p
			WHERE	listprice > 0
			GROUP BY	p.ProductSubcategoryID) x
INNER JOIN	Production.Product p ON x.subcat = p.ProductSubcategoryID
WHERE		p.ProductSubcategoryID IS NOT NULL
	AND		p.ListPrice < x.avglpbysubcat;

SELECT
    p.Name,
    p.ProductSubcategoryID,
    p.ListPrice
FROM Production.Product AS p
WHERE p.ListPrice < (
    SELECT AVG(p2.ListPrice)
    FROM Production.Product AS p2
    WHERE p2.ProductSubcategoryID = p.ProductSubcategoryID
      AND p2.ListPrice > 0
)
AND p.ProductSubcategoryID IS NOT NULL
ORDER BY p.ProductSubcategoryID, p.ListPrice DESC;

-- Derived table: rank customers by spend bracket

SELECT	x.Spendbucket,
		COUNT(*) AS CustomerCount,
		SUM(x.Totalspend) AS BucketTotal
FROM	(SELECT		customerID,
		 SUM(totaldue) AS TotalSpend,
			CASE
				WHEN SUM(totaldue) >= 100000 THEN 'WHALE'
				WHEN SUM(totaldue) >= 10000 THEN 'HIGH'
				WHEN SUM(totaldue) >= 1000 THEN 'MID'
				ELSE 'LOW'
			END AS Spendbucket
		FROM		sales.SalesOrderHeader
		GROUP BY	CustomerID) x
GROUP BY	x.Spendbucket
ORDER BY	BucketTotal DESC;

-- For each customer, their order count and total spend
-- (Inefficient — better done with GROUP BY — but illustrates the pattern)

SELECT TOP 10
    c.CustomerID,
    c.AccountNumber,
    (SELECT COUNT(*) FROM Sales.SalesOrderHeader o WHERE o.CustomerID = c.CustomerID) AS OrderCount,
    (SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader o WHERE o.CustomerID = c.CustomerID) AS TotalSpend
FROM Sales.Customer AS c
ORDER BY (SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader o WHERE o.CustomerID = c.CustomerID) DESC;


SELECT	TOP 10
		c.customerid,
		c.accountnumber,
		x.ordercount,
		x.totalspend

FROM	sales.customer c
LEFT JOIN	( 
			SELECT		customerid,
						COUNT(*) as ordercount,
						SUM(TotalDue) AS totalspend
			FROM		sales.SalesOrderHeader
			GROUP BY	CustomerID
			) as x ON c.CustomerID = x.CustomerID
ORDER BY x.totalspend DESC;



--**🧠 AI-free zone — Self-test (20 min):** No AI:

--1. From `Sales.SalesOrderHeader`, build a derived table that computes per-customer total spend, then in the outer query, count how many customers fall above $50,000 in total spend.


SELECT	COUNT(x.customerid) AS customersabove50k
		
FROM 
		(SELECT		soh.customerid,
					SUM(soh.TotalDue) totalspend
		FROM		sales.SalesOrderHeader soh
		GROUP BY	soh.CustomerID
		HAVING		SUM(soh.TotalDue) > 50000) AS x

--2. Write a correlated subquery: for each `Sales.SalesPerson`, show their `BusinessEntityID` and a column called `OrderCount` computed as `(SELECT COUNT(*) FROM SalesOrderHeader WHERE SalesPersonID = sp.BusinessEntityID)`.

SELECT		p.BusinessEntityID,
			(SELECT	COUNT(*)
			FROM	sales.SalesOrderHeader
			WHERE	SalesPersonID = p.businessentityid) AS ordercount
FROM		sales.SalesPerson p




--3. Take question 2 and rewrite it as a `LEFT JOIN + GROUP BY`. Compare results. Which is more readable? Which would you use in production? Note in a comment.

SELECT		p.BusinessEntityID,
			x.OrderCount
FROM		sales.salesperson p
LEFT JOIN	(SELECT		soh.salespersonid AS spID,
						COUNT(*) AS OrderCount
			 FROM		sales.SalesOrderHeader soh
			 WHERE		soh.salespersonid IS NOT NULL
			 GROUP BY	soh.salespersonid
			 ) x ON p.BusinessEntityID = x.spID 



--4. Using a derived table or correlated subquery: for each subcategory, find its single most expensive product (top-1 per group). Produce subcategory_id + max_price + product_name. 
--This IS solvable now — find the max price per subcategory, then match the product at that price. (The harder *top-N* version is Week 4.)


SELECT		p.productsubcategoryID,
			mp.MaxPrice AS MaxPriceBySubCat,
			p.Name
FROM Production.Product p
INNER JOIN
			(SELECT		p.productsubcategoryID AS subcat,
						MAX(p.listprice) AS MaxPrice
			FROM		Production.Product p
			WHERE		p.productsubcategoryID IS NOT NULL
			GROUP BY	p.productsubcategoryID) mp ON p.productsubcategoryID = mp.subcat
ORDER BY	MaxPriceBySubCat DESC;
 

--5. Now the one that genuinely doesn't have a clean solution yet: find products whose price is in the TOP 3 of their subcategory. Attempt it, and document in a comment exactly where you got stuck 
--— this is the single problem this week deliberately leaves you unable to finish, because window functions (Week 4) are precisely the tool it needs. Feeling the wall here is the setup for next week's payoff.
