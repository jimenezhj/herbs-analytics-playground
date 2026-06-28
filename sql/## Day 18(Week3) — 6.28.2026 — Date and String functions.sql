SELECT
	GETDATE() AS Currentdatetime,
	CAST(GETDATE() AS date) AS CurrentDate,
	SYSDATETIME() AS highprecisionnow

SELECT
	Orderdate,
	YEAR(Orderdate) AS OrderYear,
	MONTH(Orderdate) AS OrderMonth,
	DAY(OrderDate) AS OrderDay,
	DATEPART(QUARTER, OrderDate) AS OrderQuarter,
	DATEPART(WEEKDAY, OrderDate) AS WeekdayNum,
	DATENAME(WEEKDAY, OrderDate) AS WeekdayName
FROM	sales.SalesOrderHeader
WHERE	SalesOrderID < 43670;

SELECT	salesorderid,
		orderdate,
		shipdate,
		DATEDIFF(DAY, orderdate, shipdate) AS DaysToShip,
		DATEDIFF(MONTH, orderdate, shipdate) AS Monthssinceorder,
		DATEDIFF(YEAR, orderdate, shipdate) AS Yearssinceorder
FROM	sales.SalesOrderHeader
WHERE	SalesOrderID < 43670;

SELECT	orderdate,
		DATEADD(DAY,30,Orderdate) AS Plusthirtydays,
		DATEADD(MONTH,1,Orderdate) AS PlusOneMonth,
		DATEADD(YEAR,-1,Orderdate) AS OneYearEarlier
FROM	sales.SalesOrderHeader
WHERE	salesorderid = 43660;

SELECT	GETDATE() AS Today,
		EOMONTH(GETDATE()) AS EndofThisMonth,
		EOMONTH(GETDATE(), 1) AS EndofNextMonth,
		EOMONTH(GETDATE(), -1) AS EndofLastMonth

SELECT	Orderdate,
		FORMAT(Orderdate, 'yyyy-MM-dd') AS IsoDate,
		FORMAT(Orderdate, 'MMM yyyy') AS MonthYear,
		FORMAT(Orderdate, 'MMMM dd, yyyy') AS Verbose
FROM	Sales.SalesOrderHeader
WHERE	salesorderID < 43665;



SELECT	firstname,
		lastname,
		LEN(firstname) AS Len1,
		LEN(firstname+' '+Lastname) AS len2
FROM	Person.Person
WHERE	BusinessEntityID < 10;

SELECT	name,
		LEFT(name, 5) AS First5,
		RIGHT(name, 5) AS Last5,
		SUBSTRING(name, 3, 5) AS Char3to7
FROM	Production.Product
WHERE	ProductID < 10;

SELECT	emailaddress,
		CHARINDEX('@', emailaddress) AS Atposition,
		LEFT(emailaddress, CHARINDEX('@',emailaddress) -1) AS Username,
		TRIM(SUBSTRING(emailaddress, CHARINDEX('@',EMAILADDRESS) + 1, 100)) as domain
FROM	person.EmailAddress
WHERE	BusinessEntityID < 10;

SELECT	firstname+' '+lastname AS fullnameplus,
		CONCAT(firstname,' ',lastname) AS fullnameconcat,
		firstname+' '+ NULL AS withnullplus,
		CONCAT(firstname, ' ', NULL) AS withnullconcat
FROM	Person.Person
WHERE	BusinessEntityID < 5;

SELECT
    '   Hello World   ' AS Original,
    LTRIM('   Hello World   ') AS LeftTrimmed,
    RTRIM('   Hello World   ') AS RightTrimmed,
    TRIM('   Hello World   ') AS BothTrimmed,
    UPPER('Hello World') AS Upper,
    LOWER('Hello World') AS Lower,
    REPLACE('Hello World', 'World', 'CRE') AS Replaced;

SELECT EmailAddress
FROM Person.EmailAddress
WHERE CHARINDEX('@', EmailAddress) = 0
   OR CHARINDEX('.', EmailAddress) = 0;

SELECT
    FirstName AS Raw,
    UPPER(LEFT(TRIM(FirstName), 1)) + LOWER(SUBSTRING(TRIM(FirstName), 2, 100)) AS ProperCase
FROM Person.Person
WHERE BusinessEntityID < 10;

SELECT
    OrderDate,
    YEAR(OrderDate) AS FiscalYear,
    'Q' + CAST(DATEPART(QUARTER, OrderDate) AS VARCHAR) + ' ' + CAST(YEAR(OrderDate) AS VARCHAR) AS FiscalQuarter
FROM Sales.SalesOrderHeader
WHERE SalesOrderID < 43665;


--**🧠 AI-free zone — Self-test (15 min):** No AI:

--1. From `Sales.SalesOrderHeader`, compute days between OrderDate and ShipDate for 20 rows. Add a column flagging anything that took more than 7 days as 'SLOW'.

SELECT TOP 1 * FROM sales.salesorderheader


SELECT	TOP 20
		salesorderID,
		DATEDIFF(DAY, orderdate, shipdate) AS Daystoship,
		CASE
			WHEN DATEDIFF(DAY, orderdate, shipdate) > 7 THEN 'slow' 
			ELSE 'standard'
		END AS Flag
FROM	sales.SalesOrderHeader
ORDER BY Orderdate DESC;
--2. From `Person.EmailAddress`, extract the domain part (everything after `@`) for each email. Count how many distinct domains exist.

SELECT	COUNT(DISTINCT TRIM(SUBSTRING(emailaddress, CHARINDEX('@',emailaddress) + 1, 100))) AS distinctdomains
FROM	person.EmailAddress


--3. From `Person.Person`, produce a column `FullName` that handles missing middle name (use `CONCAT` so NULL middle name doesn't break the concatenation).
SELECT	
		firstname,
		middlename,
		lastname,
		CONCAT(firstname,' ',ISNULL(middlename,'') ,' ',lastname) AS fullname

FROM	Person.Person

SELECT	
		firstname,
		middlename,
		lastname,
		CONCAT(firstname,' ',middlename ,' ',lastname) AS fullname

FROM	Person.Person



--4. From `Sales.SalesOrderHeader`, produce a column `FiscalQuarter` like 'Q2 2014' for each order. Group by it. Show order counts per fiscal quarter for 2013-2014.

SELECT	
		CONCAT('Q', DATEPART(QUARTER, OrderDate), ' ', YEAR(Orderdate)) AS FiscalQuarter,
		COUNT(salesOrderID) OrderCount
FROM	sales.SalesOrderHeader
WHERE	OrderDate >= '2013-01-01'
	AND	OrderDate < '2015-01-01'
GROUP BY CONCAT('Q', DATEPART(QUARTER, OrderDate), ' ', YEAR(Orderdate))

--5. From `Production.Product`, find products whose name contains the word 'Bike' (case-insensitive — use `LOWER` or `UPPER`). Show count and sample of 10.

SELECT	name,
		count(*)
FROM Production.Product
WHERE CHARINDEX(UPPER('bike'),UPPER(name)) >= 1
GROUP BY Name
