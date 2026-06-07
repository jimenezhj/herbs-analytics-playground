USE AdventureWorks2022;
GO

--1. All columns, all rows (only do this on small tables — never in production on a million-row table)

--SELECT * FROM person.person;

-- 2. Specific columns only

--SELECT 
--	firstname,
--	lastname
--FROM Person.Person;

-- 3. Limit how many rows come back

--SELECT TOP 10
--	firstname,
--	lastname

--FROM person.Person;
	
-- 4. Count rows (includes nulls in this form)

--SELECT COUNT(*)
--FROM Person.Person;

-- 5. Try a different table

--SELECT TOP 5
--	name,
--	listprice
--FROM Production.Product;

--Practice query

--1. Show 5 rows from `Production.Product` — just the columns `Name` and `ListPrice`.
--SELECT TOP 5
--	name,
--	listprice
--FROM Production.Product;

--2. Show all columns from the first 3 rows of `Sales.Customer`.
--SELECT TOP 3 *
--FROM Sales.Customer;

--3. Count the total number of rows in `Sales.SalesOrderHeader`.
--SELECT COUNT(*)
--FROM sales.salesorderheader;
