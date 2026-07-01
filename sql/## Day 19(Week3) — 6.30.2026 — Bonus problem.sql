--1. Uses a CTE to compute total revenue per customer.
--2. In a second CTE, buckets customers into 'Whale' (>=$100k), 'High' ($10k-100k), 'Mid' ($1k-10k), 'Low' (<$1k).
--3. Final SELECT: count of customers and total revenue per bucket, sorted by bucket order (Whale first).

WITH revpercust AS
(
SELECT	CustomerID,
		SUM(Totaldue) TotalRev
FROM	sales.SalesOrderHeader
GROUP BY	CustomerID
),
bucketrev AS
(
SELECT	CustomerID,
		TotalRev,
		CASE
			WHEN TotalRev >= 100000 THEN 'Whale'
			WHEN TotalRev >= 10000 AND TotalRev < 100000 THEN 'High'
			WHEN TotalRev >= 1000 AND TotalRev < 10000 THEN 'Mid'
			WHEN TotalRev < 1000 THEN 'Low'
		END AS bucket,
		CASE
			WHEN TotalRev >= 100000 THEN 1
			WHEN TotalRev >= 10000 AND TotalRev < 100000 THEN 2
			WHEN TotalRev >= 1000 AND TotalRev < 10000 THEN 3
			WHEN TotalRev < 1000 THEN 4
		END AS bucketindex	
FROM	revpercust
)
SELECT  COUNT(br.CustomerID) NumberOfCustomersPerBucket,
		br.bucket Category,
		SUM(br.TotalRev) TotalRevenueByBucket
FROM	bucketrev br
GROUP BY	br.bucketindex, bucket
ORDER BY	br.bucketindex ASC;


--index show as integer for reference
--pull columns into multi step CTEs (avoid joins if possible -- unless joining to non-CTE)
