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


--**Problem 4 — Customer cohort retention (architect-level)**

--For each "cohort" (customers who placed their first order in a given year), show:
--- CohortYear
--- CohortSize (number of customers)
--- ActiveIn2013 (count of those customers who placed an order in 2013)
--- ActiveIn2014 (count of those customers who placed an order in 2014)
--- Retention2014 (ActiveIn2014 / CohortSize as percentage)

--(Hint: CTE finding each customer's first-order year. Another CTE finding each customer's per-year activity. Then join + conditional aggregation. 
--This is real analyst work — multiple steps, careful logic. **Watch the subtle bug:** a customer's cohort is their *first year ever* and must be fixed once 
-- if your logic lets a customer's cohort change year to year, retention numbers become meaningless. Compute first-order-year as a single MIN per customer, then never recompute it.)

--**Problem 5 — Pareto analysis (customer revenue concentration)**

--Goal: show whether RioCan-style "80/20" applies to this customer data. Output: one row per decile (1-10) showing:
--- Decile (1 = top spenders)
--- CustomerCount
--- DecileRevenue
--- CumulativeRevenue (sum of this decile + all higher deciles)
--- PctOfTotal (cumulative % of overall revenue)

--(Hint: NTILE(10) over customer total spend. Then aggregate by decile. Then cumulative sum + percent of total.)

--**Problem 6 — Lapsed-customer analysis**

--For each customer, find: their last order date, days since last order (vs. the max order date in the table), and a category — 'Active' (≤90 days), 'At Risk' (91-365), 'Lapsed' (>365). Then summarize: how many customers in each category? Average total spend per category?

--(Hint: CTE with each customer's max order date, plus the global max order date. Then DATEDIFF, CASE, then group by category.)