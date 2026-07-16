----SELECT
----	i.name AS IndexName,
----	i.type_desc AS Indextype,
----	i.is_unique,
----	i.is_primary_key,
----	STRING_AGG(c.name,', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
----FROM sys.indexes i
----INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
----INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
----WHERE i.object_id = object_id('Sales.SalesOrderHeader')
---- AND i.type > 0
----GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
----ORDER BY i.is_primary_key DESC, i.name;


----SELECT
----    OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS TableName,
----    i.name AS IndexName,
----    i.type_desc AS IndexType,
----    i.is_unique,
----    i.is_primary_key
----FROM sys.indexes i
----WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'Sales'
----  AND i.type > 0
----ORDER BY TableName, i.name;

----INSERT INTO dbo.Tenant (TenantName, ContactEmail, Industry)
----SELECT
----    'Tenant ' + CAST(n AS VARCHAR),
----    'tenant' + CAST(n AS VARCHAR) + '@example.com',
----    'Industry ' + CAST(n % 10 AS VARCHAR)
----FROM (
----    SELECT TOP 10000 ROW_NUMBER() OVER (ORDER BY a.object_id) AS n
----    FROM sys.all_objects a CROSS JOIN sys.all_objects b
----) AS x;

----SET STATISTICS TIME ON;
----SET STATISTICS IO ON;

----SELECT * FROM dbo.Tenant WHERE TenantName = 'Tenant 5000';
------ Note the elapsed time and logical reads.

------ Now create an index
------CREATE INDEX IX_Tenant_TenantName ON dbo.Tenant(TenantName);

------ Run the same query
----SELECT * FROM dbo.Tenant WHERE TenantName = 'Tenant 5000';
------ Significantly fewer logical reads, faster execution.

----SET STATISTICS TIME OFF;
----SET STATISTICS IO OFF;

----1. Inspect the indexes on `Sales.Customer`, `Sales.SalesOrderHeader`, and `Production.Product` in AdventureWorks. List them. For each, identify what column(s) it's on and whether it's clustered or non-clustered.

--SELECT
--    i.name AS IndexName,
--    i.type_desc AS IndexType,
--    i.is_unique,
--    i.is_primary_key,
--    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
--FROM sys.indexes i
--INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
--INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
--WHERE i.object_id = OBJECT_ID('Sales.Customer')
--  AND i.type > 0  -- exclude heap (no index)
--GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
--ORDER BY i.is_primary_key DESC, i.name;


--SELECT
--    i.name AS IndexName,
--    i.type_desc AS IndexType,
--    i.is_unique,
--    i.is_primary_key,
--    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
--FROM sys.indexes i
--INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
--INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
--WHERE i.object_id = OBJECT_ID('Sales.SalesOrderHeader')
--  AND i.type > 0  -- exclude heap (no index)
--GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
--ORDER BY i.is_primary_key DESC, i.name;

--SELECT
--    i.name AS IndexName,
--    i.type_desc AS IndexType,
--    i.is_unique,
--    i.is_primary_key,
--    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
--FROM sys.indexes i
--INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
--INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
--WHERE i.object_id = OBJECT_ID('Production.Product')
--  AND i.type > 0  -- exclude heap (no index)
--GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
--ORDER BY i.is_primary_key DESC, i.name;


----2. For the following queries, predict which existing index AdventureWorks already has that would speed them up (and which would have to scan). Then check by looking at indexes:
----   - `SELECT * FROM Sales.SalesOrderHeader WHERE SalesOrderID = 43671;` will not scan uses a clustered; will go directly to 43671
----   - `SELECT * FROM Sales.SalesOrderHeader WHERE CustomerID = 29825;` will not scan - non-clustered
----   - `SELECT * FROM Sales.SalesOrderHeader WHERE OrderDate >= '2013-01-01' AND OrderDate < '2014-01-01';` will scan
----   - `SELECT * FROM Sales.SalesOrderHeader WHERE TotalDue > 50000;` will scan

----3. In your sandbox, create a non-clustered index on `Lease(EndDate)`. Then write a query "find all leases expiring in the next 12 months from a given date" and explain (in a comment) why this index helps.
--USE practice_sandbox;
--GO

--SELECT * FROM dbo.lease

--SELECT
--    i.name AS IndexName,
--    i.type_desc AS IndexType,
--    i.is_unique,
--    i.is_primary_key,
--    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS KeyColumns
--FROM sys.indexes i
--INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
--INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
--WHERE i.object_id = OBJECT_ID('dbo.lease')
--  AND i.type > 0  -- exclude heap (no index)
--GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
--ORDER BY i.is_primary_key DESC, i.name;

--CREATE INDEX IX_lease_enddate ON dbo.lease(EndDate);


----4. Architect question (comment): your data architect proposes adding non-clustered indexes on every column of the `Lease` table "just in case." What 2-3 problems would you raise with this approach?

----5. Cleanup: Drop the indexes you created in your sandbox.

--DROP INDEX IX_lease_enddate ON dbo.lease


