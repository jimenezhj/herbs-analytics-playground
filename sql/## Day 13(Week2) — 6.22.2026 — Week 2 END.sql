--1. From `Sales.SalesOrderHeader` joined to `Sales.Customer` joined to `Person.Person`,
--2. Returns each customer's full name and total spend across all years,
--3. But only customers whose total spend exceeds $100,000,
--4. Sorted by total spend descending,
--5. Showing only the top 50.



SELECT		TOP 50
			p.firstname,
			p.lastname,
			SUM(soh.totaldue) AS TotalRevenue
FROM		sales.SalesOrderHeader soh
INNER JOIN	Sales.Customer c ON soh.CustomerID = c.CustomerID
INNER JOIN	Person.Person p ON c.PersonID = p.BusinessEntityID
GROUP BY	p.FirstName,p.LastName
HAVING		SUM(soh.totaldue) > 100000
ORDER BY	TotalRevenue DESC;



SELECT * FROM SALES.Customer
INNER JOIN	Person.Person	ON PersonID


SELECT TOP 1 * FROM Sales.Customer;
-- Or, more precisely, see the actual foreign keys on the table:
EXEC sp_help 'Sales.Customer';


-- From Sales.SalesOrderHeader joined to Sales.SalesPerson joined to Person.Person:
-- 1. Return each salesperson's full name (first + last) and their total revenue
--    (SUM of TotalDue) across all their orders.
-- 2. Only salespeople whose total revenue exceeds $2,000,000.
-- 3. Sorted by total revenue descending.
-- 4. Show only the top 10.


EXEC sp_help 'Sales.SalesOrderheader';

SELECT		TOP 10
			p.firstname,
			p.lastname,
			SUM(soh.totaldue) AS TotalRevenue
FROM		sales.SalesOrderHeader soh
INNER JOIN	Sales.SalesPerson sp ON soh.SalesPersonID = sp.BusinessEntityID
INNER JOIN	Person.person p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY	p.FirstName, p.LastName
HAVING		SUM(soh.totaldue) > 2000000
ORDER BY	TotalRevenue DESC;

