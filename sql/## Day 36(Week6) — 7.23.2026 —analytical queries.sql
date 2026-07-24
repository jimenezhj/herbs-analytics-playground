USE cre_portfolio_db;
GO

-- aggregation + group by
SELECT	AssetClass,
		COUNT(*) AS PropertyCount,
		SUM(totalsquarefeet) AS TotalSF,
		SUM(acquisitioncost) AS TotalACQ,
		AVG(YearBuilt) AS AvgYearBuilt

FROM	dbo.property
GROUP BY	assetclass
ORDER BY	TotalACQ DESC;

-- multi table join

SELECT	p.propertyname,
		p.city,
		t.tenantname,
		t.industry,
		l.leasestartdate,
		l.leaseenddate,
		l.basemonthlyrent,
		l.basemonthlyrent*12 AS AnnualRent,
		l.squarefeetleased,
		CASE WHEN	l.squarefeetleased > 0 THEN (l.basemonthlyrent*12.0) / l.SquareFeetLeased ELSE NULL END AS RentPerSqFt

FROM	dbo.Lease l
INNER JOIN	dbo.property p ON l.PropertyID = p.propertyid
INNER JOIN	dbo.tenant t ON l.TenantID = t.tenantid
WHERE	l.status = 'Active'
ORDER BY	p.propertyname, l.BaseMonthlyRent DESC;

-- expiration schedule by qtr (dates, case)

SELECT	YEAR(l.leaseenddate) AS ExpirationYear,
		DATEPART(QUARTER, l.leaseenddate) AS ExpirationQuarter,
		COUNT(*) AS LeaseExpiring,
		SUM(l.basemonthlyrent * 12) AS AnnualRentAtRisk,
		SUM(l.squarefeetleased) AS SqFtExpiring
FROM	dbo.lease l
WHERE	l.status = 'active'
	AND l.leaseenddate <= DATEADD (YEAR, 5, GETDATE())
GROUP BY	YEAR(l.leaseenddate), DATEPART(QUARTER, l.leaseenddate)
ORDER BY	ExpirationYear, ExpirationQuarter

-- top 3 tenant per property

WITH rankedtenants AS
(
	SELECT	p.propertyname,
			t.tenantname,
			l.basemonthlyrent * 12 AS AnnualRent,
			ROW_NUMBER () OVER (PARTITION BY p.propertyname ORDER BY l.basemonthlyrent DESC) AS Rankings
	FROM	dbo.lease l
	INNER JOIN dbo.property p ON l.PropertyID = p.propertyid
	INNER JOIN dbo.tenant t ON l.TenantID = t.tenantid
	WHERE	l.Status = 'Active'
)

SELECT	propertyname,
		rankings,
		tenantname,
		annualrent
FROM	rankedtenants
WHERE	rankings <= 3;

-- tenant concentration risk

WITH tenantexposure AS
(
	SELECT	t.tenantid,
			t.tenantname,
			t.industry,
			COUNT(DISTINCT l.propertyID) AS propertycount,
			SUM(l.basemonthlyrent * 12) AS AnnualRent
	FROM	dbo.lease l
	INNER JOIN dbo.tenant t ON l.TenantID = t.tenantid
	WHERE	l.Status = 'ACTIVE'
	GROUP BY	t.tenantid, t.tenantname, t.industry
)

SELECT	tenantname,
		industry,
		propertycount,
		annualrent,
		annualrent * 100.0 / SUM(annualrent) OVER () AS pcrtofportfoliorent,
		SUM(annualrent) OVER (ORDER BY annualrent DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 / SUM(annualrent) OVER (ORDER BY annualrent DESC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS CumulativeRentpcrt
FROM	tenantexposure
ORDER BY	AnnualRent DESC;

-- month over month collection trend

WITH monthlycollection AS 
(
	SELECT	snapshotmonth,
			SUM(billedamount) AS billed,
			SUM(collectedamount) AS collected,
			SUM(collectedamount) * 100.0 / NULLIF(SUM(billedamount),0) AS collectionpcrt
	FROM	dbo.RentRoll
	GROUP BY	SnapshotMonth
)
SELECT	snapshotmonth,
		billed,
		collected,
		collectionpcrt,
		COALESCE(LAG(collectionpcrt) OVER (ORDER BY snapshotmonth),0) AS PriorPcrt,
		COALESCE(Collectionpcrt - LAG(collectionpcrt) OVER (ORDER BY snapshotmonth),0) as MoMChange
FROM	monthlycollection
ORDER BY	SnapshotMonth

-- tenant whose leases have no amendments (LEFT JOIN)

SELECT	t.tenantid,
		t.tenantname,
		COUNT(l.leaseID) AS LeaseCount
FROM	dbo.tenant t
INNER JOIN	dbo.lease l ON t.tenantid = l.TenantID
LEFT JOIN	dbo.LeaseAmendment a ON l.LeaseID = a.LeaseID
WHERE	l.status = 'active' AND a.AmendmentID IS NULL
GROUP BY	t.tenantid, t.tenantname
ORDER BY	t.tenantname;

-- PROPERTY OCCUPANCY AND PERFORMANCE
WITH prop_metrics AS

(
	SELECT	p.propertyid,
			p.propertyname,
			p.city,
			p.assetclass,
			p.totalsquarefeet,
			COUNT(DISTINCT CASE WHEN l.status = 'ACTIVE' THEN l.leaseid END) AS ActiveLeaseCount,
			SUM(CASE WHEN l.status = 'ACTIVE' THEN l.squarefeetleased ELSE 0 END) AS LeasedSqft,
			SUM(CASE WHEN l.status = 'ACTIVE' THEN l.basemonthlyrent * 12 ELSE 0 END) AS AnnualRent
	FROM	dbo.property P
	LEFT JOIN dbo.lease l ON p.propertyid = l.PropertyID
	GROUP BY	p.propertyID, p.propertyname, p.city, p.assetclass, p.totalsquarefeet
)

SELECT	propertyname, city, assetclass, totalsquarefeet, leasedsqft,
		TotalSquarefeet-leasedsqft AS VacantSqft,
		CAST(LeasedSqFt * 100.0 / NULLIF(TotalSquareFeet,0) AS decimal(5,2)) AS OccupancyPcrt,
		Activeleasecount, Annualrent,
		CASE WHEN leasedsqft > 0 THEN AnnualRent / leasedsqft ELSE 0 END AS RentPerLeasedSqft

FROM	prop_metrics
ORDER BY	AnnualRent DESC;




