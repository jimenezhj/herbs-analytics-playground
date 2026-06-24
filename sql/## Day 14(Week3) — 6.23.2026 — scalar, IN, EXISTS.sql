--warm up

-- 1. For each SalesTerritory, its name and the number of customers in it,
--    most customers first. (Sales.Customer has TerritoryID.)

SELECT 
	t.name AS Territory,
	count(c.CustomerID) AS Customers


FROM SALES.SalesTerritory t
left JOIN Sales.Customer c ON t.TerritoryID = c.TerritoryID
GROUP BY t.Name, t.TerritoryID
ORDER BY Customers DESC;

-- 2. Every product (name) that has NEVER appeared on a sales order line.
--    (Production.Product vs Sales.SalesOrderDetail.)

SELECT
			p.name AS productname

FROM		Production.Product p
LEFT JOIN	sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
WHERE		sod.ProductID IS NULL

EXEC SP_HELP 'SALES.SALESORDERDETAIL'

-- 3. Total revenue (SUM of LineTotal) per product category name.
--    (You did the category chain in Week 2 — mind the grain.)


SELECT			pc.name,
				SUM(sod.linetotal) TotalRevenue
FROM			sales.SalesOrderDetail sod
INNER JOIN		Production.Product p ON sod.ProductID = p.ProductID
INNER JOIN		Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
INNER JOIN		Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY		pc.productcategoryID, pc.name
ORDER BY		TotalRevenue DESC;

select top 15 * from sales.SalesOrderDetail
select top 15 * from Production.Product
select top 15 * from Production.ProductSubcategory
select top 15 * from Production.ProductCategory



-- 4. The 5 most recent orders (SalesOrderID, OrderDate) — header table only.

SELECT			TOP 5
				SalesOrderID,
				OrderDate
FROM			Sales.SalesOrderHeader
ORDER BY		OrderDate DESC;



-- 5. Count how many customers have no PersonID recorded (store customers).

SELECT			COUNT(*)
FROM			sales.Customer
WHERE			personID IS NULL;


SELECT SalesOrderID, TotalDue, Tier
FROM (
    SELECT TOP 5 SalesOrderID, TotalDue, 'Highest' AS Tier
    FROM Sales.SalesOrderHeader
    ORDER BY TotalDue DESC
) AS top_orders
UNION ALL
SELECT SalesOrderID, TotalDue, Tier
FROM (
    SELECT TOP 5 SalesOrderID, TotalDue, 'Lowest' AS Tier
    FROM Sales.SalesOrderHeader
    WHERE TotalDue > 0
    ORDER BY TotalDue ASC
) AS bottom_orders;

--SCALAR
SELECT      name, listprice
FROM        Production.Product
WHERE       listprice > (SELECT AVG(Listprice) FROM Production.Product WHERE listprice > 0)

--IN / NOT IN

SELECT      name, listprice
FROM        Production.Product
WHERE       ProductSubcategoryID IN (SELECT ProductSubcategoryID
                                     FROM   Production.ProductSubcategory
                                     WHERE ProductCategoryID = (SELECT ProductCategoryID
                                                                FROM Production.ProductCategory
                                                                WHERE name = 'BIKES')
                                    )
ORDER BY    listprice DESC

--EXISTS / NOT EXISTS

SELECT          c.customerID, c.accountnumber
FROM            sales.customer c
WHERE   EXISTS  (SELECT 1
                 FROM sales.salesorderheader o
                 WHERE o.customerid = c.customerid);



SELECT      name,
            listprice,
            (SELECT AVG(ListPrice) FROM Production.Product WHERE ListPrice > 0) AS AvgPrice
FROM        Production.Product
WHERE       listprice > (SELECT AVG(listprice) FROM Production.Product WHERE listprice > 0)
GROUP BY    productid, name, ListPrice

SELECT      name,
            listprice
FROM        Production.Product
WHERE       ProductSubcategoryID IN (
            SELECT  ProductSubcategoryID
            FROM    Production.Product
            WHERE   name LIKE 'mountain%')

SELECT          c.CustomerID, c.accountnumber
FROM            sales.customer c
WHERE EXISTS    (
                SELECT 1
                FROM sales.SalesOrderHeader o
                WHERE o.CustomerID = c.CustomerID)

SELECT          c.CustomerID, c.accountnumber
FROM            sales.customer c
WHERE NOT EXISTS    (
                SELECT 1
                FROM sales.SalesOrderHeader o
                WHERE o.CustomerID = c.CustomerID)


SELECT ProductID, Name
FROM Production.Product
WHERE ProductSubcategoryID NOT IN (
    SELECT ProductSubcategoryID FROM Production.ProductSubcategory)

SELECT p.ProductID, p.Name
FROM Production.Product AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM Production.ProductSubcategory AS s
    WHERE s.ProductSubcategoryID = p.ProductSubcategoryID)


--1. From `Production.Product`, find products whose `ListPrice` is higher than the average list price for *their own subcategory*. 
--(Hint: scalar subquery in WHERE — but you'll need to think about how to make the inner query reference the outer row. Try writing it and see what happens. 
--If it returns nothing useful, that's because this is actually a *correlated subquery* problem, which we'll formalize tomorrow. For today, attempt and note where you got stuck.)


SELECT      
            p.Name productname,
            ps.Name subcategoryname,
            p.listprice

FROM        Production.Product p
INNER JOIN  Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
WHERE       p.listprice > (
            SELECT AVG(p2.listprice)
            FROM        Production.Product p2 
            WHERE       p2.listprice > 0
            GROUP BY ps.Name)



--2. From `Production.Product`, find all products whose `ProductSubcategoryID` is in the list of subcategories that have more than 20 products. Use an IN subquery.

SELECT  productID, 
        name, 
        ProductSubcategoryID
FROM    Production.Product
WHERE   ProductSubcategoryID IN (
        SELECT      ProductSubcategoryID
        FROM        Production.Product p
        GROUP BY    ProductSubcategoryID
        HAVING  COUNT(*) > 20);

--3. Find every salesperson (`Sales.SalesPerson` — new table; `SELECT TOP 1 *` to see its columns before you write the join, don't ask AI) who has placed at least one order in `Sales.SalesOrderHeader`. Use EXISTS.


SELECT      s2.BusinessEntityID
FROM        sales.SalesPerson s2
WHERE       EXISTS (
            SELECT 1
            FROM sales.SalesOrderHeader soh
            WHERE soh.SalesPersonID = s2.BusinessEntityID
);

SELECT TOP 1 * FROM sales.salesorderheader
EXEC sp_help 'sales.salesorderheader'
SELECT TOP 1 * FROM sales.SalesPerson
EXEC sp_help 'sales.salesperson'


--4. Find every salesperson who has placed *no* orders. Write it two ways:
--   - Using `NOT EXISTS`
--   - Using `LEFT JOIN ... WHERE IS NULL` (from Week 2)
--   Do they return the same result? Add a 1-line comment noting which you'd choose and why.  

SELECT      s2.BusinessEntityID
FROM        sales.SalesPerson s2
WHERE       NOT EXISTS (
            SELECT 1
            FROM sales.SalesOrderHeader soh
            WHERE soh.SalesPersonID = s2.BusinessEntityID
);
--this gives what sales person didnt place orders

SELECT      SP.BusinessEntityID,
            COUNT(soh.salesorderID)
FROM        sales.SalesPerson sp
LEFT JOIN   sales.salesorderheader soh ON soh.SalesPersonID = sp.BusinessEntityID
GROUP BY    sp.BusinessEntityID
HAVING       COUNT(soh.salesorderID) = 0
--this counts how many orders, then if 0 gives which sales person did not place an order


--5. The NULL trap: Run the buggy `NOT IN` query from Practice. Then run the `NOT EXISTS` version. Inspect the row counts. Write a 2-sentence note about what's happening and why architects prefer `NOT EXISTS`.
SELECT ProductID, Name
FROM Production.Product
WHERE ProductSubcategoryID NOT IN (
    SELECT ProductSubcategoryID FROM Production.ProductSubcategory
);

SELECT p.ProductID, p.Name
FROM Production.Product AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM Production.ProductSubcategory AS s
    WHERE s.ProductSubcategoryID = p.ProductSubcategoryID
);

--when not in looks in every row, whenever it finds null, it treats it as unknown so not in cannot return what is unknown due to the nature of nulls hence its blank. 
--not exists looks whether or not the product from select does not exist in the subquery - whether null or not just checks existence, not exist is null safe