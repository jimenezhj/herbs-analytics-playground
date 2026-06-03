--## Day 2 — 6.2.2026 — Filtering rows with WHERE

--**Theory:** The `WHERE` clause filters which rows the query returns. It comes immediately after `FROM`. Conditions can use comparison operators (`=`, `<>`, `<`, `>`, `<=`, `>=`), range operators (`BETWEEN`), list membership (`IN`), pattern matching (`LIKE`),
--and null tests (`IS NULL` / `IS NOT NULL`). Combine multiple conditions with `AND`, `OR`, and `NOT`.

--**In plain English:** WHERE is the equivalent of Excel's auto-filter. You're saying "only show me rows where condition X is true." If you've ever clicked a column filter and selected "Greater than $1000," you've done the WHERE equivalent.

--**Two NULL gotchas to internalize today:**
--- `WHERE Color = NULL` returns ZERO rows, even when nulls exist. Use `WHERE Color IS NULL` instead.
--- `WHERE Color <> 'Red'` excludes nulls too — because NULL isn't "not Red," it's "unknown." To include nulls: `WHERE Color <> 'Red' OR Color IS NULL`.

--**Practice (90 min):**

--```sql
-- Basic comparison -- this is selecting the products that have a list price of greater than $1000
--SELECT Name, ListPrice
--FROM Production.Product
--WHERE ListPrice > 1000;

--SELECT p.name, p.listprice
--FROM production.product p
--WHERE p.listprice > 1000;


---- BETWEEN (inclusive both ends) -- this is selecting the products that have a listprice in between 100 and 500
--SELECT Name, ListPrice
--FROM Production.Product
--WHERE ListPrice BETWEEN 100 AND 500;

--SELECT
--	p.name,
--	p.listprice
--FROM production.product p
--WHERE p.listprice BETWEEN 100 AND 500;

---- IN — match any value in a list -- this is selecting the products that have a color of red, blue or black
--SELECT Name, Color, ListPrice
--FROM Production.Product
--WHERE Color IN ('Red', 'Blue', 'Black');

--SELECT
--	p.name,
--	p.color,
--	p.listprice
--FROM production.product p
--WHERE Color IN ('red','blue','black');

---- LIKE — pattern match (% = any string, _ = any single character) - this is selecting products with name that start with letters before %; can also be between %; or after %;
--SELECT Name
--FROM Production.Product
--WHERE Name LIKE 'Mountain%';   -- starts with "Mountain"

--SELECT
--	p.name
--FROM Production.Product p
--WHERE p.name LIKE '%Mountain';

---- NULL test
--SELECT Name
--FROM Production.Product
--WHERE Color IS NULL;   -- products with no assigned color

--SELECT
--	p.name
--FROM Production.Product p
--WHERE p.color IS NULL;

---- Combining with AND
--SELECT Name, ListPrice, Color
--FROM Production.Product
--WHERE ListPrice > 1000 AND Color = 'Black';

--SELECT
--	p.name,
--	p.listprice,
--	p.color
--FROM production.Product p
--WHERE p.listprice > 1000 AND p.color = 'black';

---- Combining with OR — watch the parentheses
--SELECT Name, ListPrice, Color
--FROM Production.Product
--WHERE (Color = 'Red' OR Color = 'Blue') AND ListPrice > 500;
---- Try removing the parentheses and observe how the result changes.

--SELECT
--	p.name,
--	p.listprice,
--	p.color
--FROM Production.Product p
--WHERE Color = 'red' or (color = 'blue' AND p.listprice > 500);

--```

--**Self-test (45 min):** Write 5 queries from scratch on `Production.Product`:

--1. Products whose name starts with "Road"

--SELECT
--	p.name
--FROM production.product p
--WHERE p.name LIKE '%road%';

--2. Products with `ListPrice = 0` (internal/free items)

--SELECT
--	p.name,
--	p.listprice

--FROM Production.Product p
--WHERE p.listprice = 0;

--3. Products where Color is NOT 'Red', 'Blue', OR 'Black' (include nulls)

--SELECT
--	p.name,
--	p.color
--FROM Production.Product p
--WHERE Color NOT IN ('red','blue','black');

--4. Products with ListPrice between $500 and $1500 AND Color = 'Silver'

--SELECT
--	p.name,
--	p.listprice
--FROM production.Product p
--WHERE p.listprice BETWEEN 500 AND 1500 AND p.color ='silver';

--5. Products where ProductNumber contains the letter "R"

--SELECT 
--	p.name,
--	p.ProductNumber

--FROM Production.Product p
--WHERE p.ProductNumber LIKE '%r%'

--**You Win Today If:** All 5 self-test queries written and producing results. You understand why `(A OR B) AND C` returns different rows than `A OR B AND C`.