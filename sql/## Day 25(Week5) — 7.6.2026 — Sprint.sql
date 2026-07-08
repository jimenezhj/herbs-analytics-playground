SELECT
    OrderDate,
    SalesOrderID,
    TotalDue,
    SUM(TotalDue) OVER (ORDER BY OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013
ORDER BY OrderDate, SalesOrderID;

SELECT
    OrderDate,
    SalesOrderID,
    TotalDue,
    SUM(TotalDue) OVER (ORDER BY OrderDate, SalesOrderID) AS RunningTotal
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2013
ORDER BY OrderDate, SalesOrderID;

--**Problem 1 — Top subcategory revenue per territory (Week 2 Sprint Problem 5)**
--For each `TerritoryID`, find the top-revenue product subcategory. Show TerritoryID, SubcategoryName, TerritoryRevenue. Sort by TerritoryID.
--(Hint: CTE aggregating revenue by territory + subcategory. Window-function rank by revenue partitioned by territory. Filter to rank = 1. Join for the name.)

WITH totalrevenue AS

(
    SELECT  SalesOrderID,
            ProductID,
            SUM(linetotal) AS TotalRevenue
    FROM    sales.SalesOrderDetail
    GROUP BY    SalesorderID, ProductID

),
territoryidtotalrevenue AS
(
    SELECT  sh.territoryid AS TerritoryID,
            ps.name AS SubcategoryName,
            SUM(tr.TotalRevenue) AS TotalRevenue,
            RANK() OVER (PARTITION BY sh.territoryid ORDER BY SUM(tr.TotalRevenue) DESC) AS Ranking
    FROM    totalrevenue tr
    INNER JOIN  sales.SalesOrderHeader sh ON tr.SalesOrderID = sh.SalesOrderID
    INNER JOIN  production.Product p ON tr.ProductID = p.ProductID
    INNER JOIN  production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    GROUP BY    sh.TerritoryID, ps.name
)

    SELECT  TerritoryID,
            SubcategoryName,
            TotalRevenue
    FROM    territoryidtotalrevenue
    WHERE   Ranking = 1
    ORDER BY TerritoryID ASC

    
--**Problem 2 — Top 3 products per category (Week 3 Sprint Problem 3)**
--For each `ProductCategory`, the top 3 products by `ListPrice`. Show CategoryName, Rank, ProductName, ListPrice.
--(Already covered in practice — make it a clean CTE + filter.)

WITH categoryrevenues AS
(
    SELECT  pc.name AS CategoryName,
            p.name AS ProductName,
            p.listprice AS TotalPrice
    FROM    Production.product p 
    INNER JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID   
),
ranking AS
(
    SELECT  CategoryName,
            ProductName,
            TotalPrice,
            DENSE_RANK() OVER (PARTITION BY CategoryName ORDER BY TotalPrice DESC) AS productrank
    FROM    categoryrevenues
)
SELECT  CategoryName,
        productrank AS Rank,
        ProductName,
        TotalPrice AS ListPrice
FROM    ranking
WHERE   productrank <= 3

--**Problem 3 — Year-over-year growth with full context**
--For each year 2011-2014, show: Year, Revenue, PriorYearRevenue, YoYDollarChange, YoYPercentChange, CumulativeRevenue, PctOfFourYearTotal. One row per year.
--(Hint: monthly or yearly CTE, then LAG + SUM OVER + SUM OVER () for the % of total.)

WITH yearlyrevenues AS
(
    SELECT  YEAR(OrderDate) AS Year,
            SUM(totaldue) AS Revenues
    FROM    sales.SalesOrderHeader
    GROUP BY    YEAR(OrderDate)
)
SELECT  Year,
        Revenues,
        LAG(Revenues,1,0) OVER (ORDER BY YEAR) AS PriorYearRevenues,
        Revenues - LAG(Revenues,1,0) OVER (ORDER BY YEAR) AS YoYDollarChange,
        (Revenues - LAG(Revenues,1,0) OVER (ORDER BY YEAR)) / LAG(Revenues,1,Revenues) OVER (ORDER BY YEAR) * 100.00  AS YoYPercentChange,
        SUM(Revenues) OVER (ORDER BY Year) AS CumulativeRevenue,
        CAST((Revenues*100.00 / SUM(Revenues) OVER ()) AS decimal(38,2)) AS PctOfFourYearTotal
FROM    yearlyrevenues


--**Problem 4 — 
-- Build a SALESPERSON cohort-retention report instead of customers.
-- A salesperson's "cohort" = the year they closed their FIRST order.
-- For each cohort year, show:
--   - CohortYear
--   - CohortSize         (how many salespeople first sold that year)
--   - ActiveIn2013       (how many of them closed at least one order in 2013)
--   - ActiveIn2014       (how many of them closed at least one order in 2014)
--   - Retention2014Pct   (ActiveIn2014 * 100.0 / CohortSize)
-- One row per cohort year.
--
-- Tables: Sales.SalesOrderHeader has SalesPersonID (NULL for online orders —
-- decide how to handle that; it's a real judgment call, not a trap to hide).

WITH CohortYearCTE AS
(
SELECT  SalesPersonID,
        YEAR(MIN(OrderDate)) AS CohortYear
FROM    sales.SalesOrderHeader
WHERE   Salespersonid IS NOT NULL
GROUP BY SalesPersonID
),
CohortActivityCTE AS
(
SELECT  DISTINCT salespersonID,
        YEAR(OrderDate) AS ActiveYear
FROM    sales.SalesOrderHeader
)
,CohortActiveYear AS
(
SELECT  cy.cohortyear,
        COUNT(DISTINCT ca.salespersonID) AS CohortSize,
        COUNT(DISTINCT CASE WHEN ca.Activeyear = 2013 THEN ca.salespersonID END) AS ActiveYear2013,
        COUNT(DISTINCT CASE WHEN ca.Activeyear = 2014 THEN ca.salespersonID END) AS ActiveYear2014
FROM    CohortactivityCTE ca
INNER JOIN  CohortYearCTE cy ON ca.salespersonid = cy.salespersonid
GROUP BY cy.cohortyear
)

SELECT  cohortyear,
        SUM(cohortsize) COHORTSIZE,  
        SUM(activeyear2013) ACTIVE2013,
        SUM(activeyear2014) ACTIVE2014,
        SUM(ActiveYear2014) * 100.0 / SUM(Cohortsize) AS Retention
FROM    CohortActiveYear
GROUP BY cohortyear




--**Problem 5 — Pareto analysis (customer revenue concentration)**

--Goal: show whether RioCan-style "80/20" applies to this customer data. Output: one row per decile (1-10) showing:
--- Decile (1 = top spenders)
--- CustomerCount
--- DecileRevenue
--- CumulativeRevenue (sum of this decile + all higher deciles)
--- PctOfTotal (cumulative % of overall revenue)
--(Hint: NTILE(10) over customer total spend. Then aggregate by decile. Then cumulative sum + percent of total.)

WITH Totals AS
(
SELECT  CustomerID,
        CAST(SUM(totaldue) AS decimal(38,2)) TotalRevenue
        
FROM    sales.SalesOrderHeader
GROUP BY CustomerID
)
,deciletotals AS
(
SELECT  CustomerID,
        TotalRevenue AS DecileRevenue,
        NTILE(10) OVER (ORDER BY TotalRevenue DESC) AS Decile
FROM    Totals
)
,deciletotals1 AS
(
SELECT  Decile,
        COUNT(CustomerID) AS NumberOfCustomers,
        SUM(DecileRevenue) AS TotalRevenue
FROM    deciletotals
GROUP BY Decile
)

SELECT  Decile,
        NumberOfCustomers,
        TotalRevenue,
        SUM(TotalRevenue) OVER (ORDER BY Decile ROWS UNBOUNDED PRECEDING) AS CumulativeRevenue,
        SUM(TotalRevenue) OVER (ORDER BY Decile ROWS UNBOUNDED PRECEDING) * 100.0 / SUM(TotalRevenue) OVER () AS Pcrt
FROM    DecileTotals1


--**Problem 6 — Lapsed-customer analysis**

--For each customer, find: their last order date, days since last order (vs. the max order date in the table), and a category — 'Active' (≤90 days), 'At Risk' (91-365), 'Lapsed' (>365). Then summarize: how many customers in each category? Average total spend per category?
--(Hint: CTE with each customer's max order date, plus the global max order date. Then DATEDIFF, CASE, then group by category.)

WITH MaxOrderDateByCustomer AS

(
SELECT  CustomerID,
        SUM(TotalDue) AS TotalSpend,
        MAX(OrderDate) MaxOrderDateCustomer
FROM    Sales.SalesOrderHeader
GROUP BY    CustomerID
)
,MaxOrderDateFromTable AS
(
SELECT  MAX(OrderDate) MaxOrderDateTable
FROM    Sales.SalesOrderHeader
)
,
MainTable AS

(
SELECT  *
FROM    MaxOrderDateByCustomer
CROSS JOIN MaxOrderDateFromTable
)
,buckets AS
(
SELECT  CustomerID,
        MaxOrderDateCustomer,
        MaxOrderDateTable,
        TotalSpend,
        CASE
            WHEN DATEDIFF(DAY,MaxOrderDateCustomer,MaxOrderDateTable) <= 90 THEN 'Active'
            WHEN DATEDIFF(DAY,MaxOrderDateCustomer,MaxOrderDateTable) > 90 AND DATEDIFF(DAY,MaxOrderDateCustomer,MaxOrderDateTable) <=365 THEN 'At Risk'
            WHEN DATEDIFF(DAY,MaxOrderDateCustomer,MaxOrderDateTable) > 365 THEN 'Lapsed'
        END AS Category
FROM    MainTable
)

SELECT  Category,
        COUNT(CustomerID) AS CustomersInCategory,
        AVG(TotalSpend) AS AvgSpendInCategory
FROM    buckets
GROUP BY Category;
