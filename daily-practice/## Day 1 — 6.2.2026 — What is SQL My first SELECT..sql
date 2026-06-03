--## Day 1 — Monday — What is SQL? Your first SELECT.

--**Theory:** SQL (Structured Query Language) is the standard language for talking to relational databases. A relational database stores data in **tables** — collections of rows and columns, similar to spreadsheets. A **query** is a sentence written in SQL that asks the database for specific data and returns rows.

--**In plain English:** Imagine your company's data lives in many connected Excel workbooks. SQL is the language you use to say: "From the Customers workbook, give me the FirstName and LastName of every row." Instead of opening the file and scrolling, you write a sentence and the database hands you back exactly what you asked for. It's 100x faster than Excel for anything bigger than a few thousand rows.

--Three required parts of every basic query:
--- `SELECT` — what columns you want
--- `FROM` — what table
--- `;` — every statement ends with a semicolon (technically optional in SSMS, but always include it)

--**Practice (90 min):** Open SSMS. Connect to your local server. Click "New Query". Make sure the dropdown at the top says `AdventureWorks2022`. Then run these one at a time, reading the result before moving on:

--```sql
---- 1. All columns, all rows (only do this on small tables)
--SELECT * FROM Person.Person;
--USE AdventureWorks2022;
--GO
--SELECT * FROM Person.person;	

---- 2. Specific columns only
--SELECT FirstName, LastName FROM Person.Person;

--SELECT 
--	FirstName, 
--	LastName 
--FROM Person.Person;

---- 3. Limit how many rows come back
--SELECT TOP 10 FirstName, LastName FROM Person.Person;

--SELECT TOP 10
--	FirstName,
--	LastName
--FROM Person.person;

---- 4. Count rows - counts every rows including nulls
--SELECT COUNT(*) FROM Person.Person;

--SELECT COUNT(*) FROM Person.person;

--```

--Notice: `Person.Person` has a dot. The first `Person` is a **schema** (a folder inside the database). The second `Person` is the **table name**. AdventureWorks uses schemas to group related tables. Every fully-qualified table name is `Schema.TableName`.

--**Self-test (30 min):** Write each of these from scratch, then run:

--1. Show 5 rows from `Production.Product` — just the columns `Name` and `ListPrice`.

--SELECT TOP 5
--	Name,
--	ListPrice
--FROM Production.Product
--ORDER BY ListPrice DESC

--2. Show all columns from the first 3 rows of `Sales.Customer`.

--SELECT TOP 3 *
--FROM Sales.Customer;

--3. Count the total number of rows in `Sales.SalesOrderHeader`.

--SELECT COUNT (*)
--FROM Sales.SalesOrderHeader


