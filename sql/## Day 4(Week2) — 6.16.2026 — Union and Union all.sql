-- Basic UNION ALL — stacking two queries
-- (Contrived example: products that are red OR products that are blue)

SELECT	Name,
		Color,
		Listprice
FROM Production.Product
WHERE Color = 'Red'

UNION ALL

SELECT	Name,
		Color,
		Listprice
FROM	Production.Product
WHERE	Color = 'blue'

-- A more realistic case — combining two different employee-like tables
-- (AdventureWorks has employees and persons; we'll fake a "all people" view)

SELECT	BusinessEntityID AS PersonID,
		Firstname,
		Lastname,
		'Person' AS SourceTable
FROM	Person.Person
WHERE	PersonType = 'EM'

UNION ALL

SELECT	BusinessEntityID AS PersonID,
		FirstName,
		LastName,
		'Vendor Contact' AS SourceTable
FROM	Person.Person
WHERE	PersonType = 'VC'
ORDER BY	LastName;

-- UNION vs UNION ALL — see the difference
-- This will show duplicates (any rows present in both queries appear twice)


SELECT	Color
FROM	Production.Product
WHERE	Color IS NOT NULL
UNION ALL
SELECT	Color
FROM	Production.Product
WHERE	ListPrice > 500;

SELECT	Color
FROM	Production.Product
WHERE	Color IS NOT NULL
UNION 
SELECT	Color
FROM	Production.Product
WHERE	ListPrice > 500;


--1. Write a UNION ALL query that lists all distinct (Name, Color) pairs from products costing under $100, 
--combined with all distinct (Name, Color) pairs from products costing over $2000. Label each with a source column ("Cheap" or "Expensive"). 
--Sort by Color.

SELECT	DISTINCT
		Name,
		Color,
		'Cheap' AS SourceColumn
FROM	Production.Product
WHERE	Listprice <= 100

UNION ALL

SELECT	DISTINCT
		Name,
		Color,
		'Expensive' AS SourceColumn
FROM	Production.Product
WHERE	ListPrice >= 2000
ORDER BY	Color ASC;


--2. Same as #1, but use UNION instead of UNION ALL. Do the row counts match? 
--Why or why not? Write a 1-sentence answer in a comment.

SELECT	
		Name,
		Color,
		'Cheap' AS SourceColumn
FROM	Production.Product
WHERE	Listprice <= 100

UNION 

SELECT	
		Name,
		Color,
		'Expensive' AS SourceColumn
FROM	Production.Product
WHERE	ListPrice >= 2000
ORDER BY	Color ASC;
--the row count matches because UNION effectively de-dupes; SELECT DISTINCT UNION ALL is still more accurate and costs less

--3. `Person.Person` has a `PersonType` column (`'EM'` = employee, `'SC'` = store contact, `'IN'` = individual customer, among others).
--Write a single result that combines all `'EM'` people with all `'IN'` people, each row labeled with a readable `Category` column
--("Employee" or "Customer"). Sort the combined result by LastName. *(This is the real UNION use case: 
--two structurally similar pulls stacked with a source label — exactly the pattern behind "all leases ever signed" 
--from a current table UNION'd with an archive table.)*

SELECT	FirstName,
		LastName,
		PersonType,
		'Employee' AS Category
FROM	Person.Person
WHERE	PersonType IN ('EM','SC')

UNION ALL

SELECT	FirstName,
		LastName,
		PersonType,
		'Customer' AS Category
FROM	Person.Person
WHERE	PersonType = 'IN'
ORDER BY	LastName ASC;


--4. Without running it, predict what would happen if you tried to UNION a query that returns 
--`(int, varchar, money)` with a query that returns `(varchar, varchar, money)`. Then run it and see if your prediction was right. 
--Write a 1-sentence note.

-- it will not work - the rule is that they have to be compatible and same number of columns (compatible meaning matching from top and bottom)

SELECT	SalesOrderID,
		CreditCardApprovalCode,
		TotalDue
FROM	Sales.SalesOrderHeader

UNION ALL

SELECT	RevisionNumber,
		PurchaseOrderNumber,
		TotalDue
FROM	Sales.SalesOrderHeader;