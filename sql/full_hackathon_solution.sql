/*
Nucor SQL Hackathon Analysis
Database: UC_NBT_Hackathon
Schema: Recy
Analysis Year: 2025

Note:
Query outputs are not included because the original dataset was provided in a restricted SQL environment.
This script documents the SQL logic used for the hackathon case study.
*/

DECLARE @StartDateKey int = 20250101;
DECLARE @EndDateKey   int = 20251231;

IF OBJECT_ID('tempdb..#Task1') IS NOT NULL DROP TABLE #Task1;
-- Task 1
SELECT dl.LocationKey,dl.Location,d.Month AS Month_Key,SUM(s.Pounds) AS Pounds,SUM(s.GrossTons) AS Tons,
SUM(s.SalesAmount) AS Sales,SUM(s.Margin) AS Margin,SUM(s.FreightAmount) AS Freight,SUM((s.Margin/s.SalesAmount)) AS MarginPct
INTO #Task1
FROM Recy.factScrapSalesShipments s
JOIN Recy.dimLocation dl ON dl.LocationKey=s.LocationKey
JOIN Recy.dimDate d ON d.DateKey=s.DateKey
JOIN Recy.dimConsumer c ON c.ConsumerKey=s.ConsumerKey
JOIN Recy.dimMaterial m ON m.MaterialKey=s.MaterialKey
LEFT JOIN Recy.dimVehicleType vt ON vt.VehicleTypeKey=s.VehicleTypeKey
GROUP BY dl.LocationKey,dl.Location,d.Month;

SELECT TOP 20 * FROM #Task1 ORDER BY Margin DESC;

--Task 2
DROP TABLE IF EXISTS #TopLocations;
SELECT TOP(3) LocationKey,Location,SUM(Margin) AS TotalMargin
INTO #TopLocations
FROM #Task1
GROUP BY LocationKey,Location
ORDER BY SUM(Margin) DESC;

SELECT * FROM #TopLocations;

--Task 3
DROP TABLE IF EXISTS #TopConsumers;
WITH ConsumerAgg AS(SELECT s.LocationKey,s.ConsumerKey,SUM(s.Margin) AS Margin,SUM(s.SalesAmount) AS Sales,SUM(s.GrossTons) AS Tons FROM Recy.factScrapSalesShipments s JOIN #TopLocations tl ON tl.LocationKey=s.LocationKey WHERE s.DateKey BETWEEN 20250101 AND 20251231 GROUP BY s.LocationKey,s.ConsumerKey),
Ranked AS(SELECT ca.*,ROW_NUMBER() OVER(PARTITION BY ca.LocationKey ORDER BY ca.Margin DESC) AS rn FROM ConsumerAgg ca)
SELECT r.LocationKey,loc.Location,r.ConsumerKey,c.ConsumerName,c.AccountType,r.Margin,r.Sales,r.Tons,CAST(r.Margin*1.0/NULLIF(r.Sales,0) AS decimal(18,4)) AS MarginPct,CAST(r.Margin*1.0/NULLIF(r.Tons,0) AS decimal(18,4)) AS MarginPerTon
INTO #TopConsumers
FROM Ranked r
JOIN Recy.dimLocation loc ON loc.LocationKey=r.LocationKey
JOIN Recy.dimConsumer c ON c.ConsumerKey=r.ConsumerKey
WHERE r.rn<=5
ORDER BY loc.Location,r.Margin DESC;

SELECT * FROM #TopConsumers ORDER BY Location,Margin DESC;

-- Task 5
SELECT 
    ftripshot.LocationKey,
    ddate.Month AS MonthKey,
    dlocation.Location,
	count(*) as Trips,
    round((SUM(ftripshot.CompletedOnTimeCount)*1.0)/count(ftripshot.CompletedOnTimeCount),2) as OnTimeRate,
	(Avg(DATEDIFF(minute,ftripshot.TripReadyDateTime,ftripshot.TripCompletedDateTime))) as AvgCycleMinutes
FROM [UC_NBT_Hackathon].[Recy].[factTripSnapshot] AS ftripshot
JOIN [Recy].[dimDate] AS ddate
    ON ftripshot.DateKey = ddate.DateKey
JOIN [Recy].[dimLocation] AS dlocation
    ON ftripshot.LocationKey = dlocation.LocationKey
WHERE 
    TripCompletedDateTime IS NOT NULL 
    AND TripReadyDateTime IS NOT NULL
GROUP BY 
    ftripshot.LocationKey,
    ddate.Month,
    dlocation.Location;


-- Task 4A
DROP TABLE IF EXISTS #Task4;
WITH Monthly AS(SELECT s.LocationKey,s.ConsumerKey,d.Month AS MonthKey,SUM(s.Margin) AS MonthlyMargin FROM Recy.factScrapSalesShipments s JOIN Recy.dimDate d ON d.DateKey=s.DateKey JOIN #TopConsumers tc ON tc.LocationKey=s.LocationKey AND tc.ConsumerKey=s.ConsumerKey WHERE s.DateKey BETWEEN 20250101 AND 20251231 GROUP BY s.LocationKey,s.ConsumerKey,d.Month)
SELECT m.LocationKey,loc.Location,m.ConsumerKey,c.ConsumerName,m.MonthKey,m.MonthlyMargin,SUM(m.MonthlyMargin) OVER(PARTITION BY m.LocationKey,m.ConsumerKey ORDER BY m.MonthKey ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningYTD
INTO #Task4
FROM Monthly m
JOIN Recy.dimLocation loc ON loc.LocationKey=m.LocationKey
JOIN Recy.dimConsumer c ON c.ConsumerKey=m.ConsumerKey
ORDER BY loc.Location,c.ConsumerName,m.MonthKey;

SELECT * FROM #Task4 ORDER BY Location,ConsumerName,MonthKey;


-- Task 6
IF OBJECT_ID('tempdb..#TopDrivers') IS NOT NULL DROP TABLE #TopDrivers;
WITH Base AS(SELECT t.LocationKey,t.DriverHackKey,COUNT(*) AS Trips,AVG(CAST(t.CompletedOnTimeCount AS float)) AS OnTimeRate FROM Recy.factTripSnapshot t WHERE t.DateKey BETWEEN 20250101 AND 20251231 GROUP BY t.LocationKey,t.DriverHackKey),
TopLocations AS(SELECT TOP 3 LocationKey FROM Base GROUP BY LocationKey ORDER BY SUM(Trips) DESC),
Ranked AS(SELECT *,ROW_NUMBER() OVER(PARTITION BY LocationKey ORDER BY Trips DESC) AS rn FROM Base WHERE LocationKey IN(SELECT LocationKey FROM TopLocations))
SELECT r.LocationKey,loc.Location,r.DriverHackKey,d.DriverName,r.Trips,r.OnTimeRate
INTO #TopDrivers
FROM Ranked r
JOIN Recy.dimLocation loc ON loc.LocationKey=r.LocationKey
JOIN Recy.dimDriverHackathon d ON d.DriverHackKey=r.DriverHackKey
WHERE rn<=5;

SELECT * FROM #TopDrivers;

-- Task 4B
DROP TABLE IF EXISTS #Task4B;
WITH Ranked AS(SELECT tc.LocationKey,tc.Location,tc.ConsumerKey,tc.ConsumerName,tc.Margin AS TopConsumerMarginCandidate,SUM(tc.Margin) OVER(PARTITION BY tc.LocationKey) AS Top5MarginTotal,ROW_NUMBER() OVER(PARTITION BY tc.LocationKey ORDER BY tc.Margin DESC) AS rn FROM #TopConsumers tc)
SELECT LocationKey,Location,ConsumerKey AS TopConsumerKey,ConsumerName,TopConsumerMarginCandidate AS TopConsumerMargin,Top5MarginTotal,CAST(TopConsumerMarginCandidate*1.0/NULLIF(Top5MarginTotal,0) AS decimal(18,4)) AS TopConsumerShareOfTop5
INTO #Task4B
FROM Ranked
WHERE rn=1
ORDER BY Location;

SELECT * FROM #Task4B ORDER BY Location;

-- Task 7
DROP TABLE IF EXISTS #ShipLocMonth;
SELECT s.LocationKey,dl.Location,d.Month AS MonthKey,SUM(s.GrossTons) AS ShipTons,COUNT(*) AS Shipments,SUM(s.SalesAmount) AS Sales,SUM(s.Margin) AS ShipMargin
INTO #ShipLocMonth
FROM Recy.factScrapSalesShipments s
JOIN Recy.dimLocation dl ON dl.LocationKey=s.LocationKey
JOIN Recy.dimDate d ON d.DateKey=s.DateKey
WHERE s.DateKey BETWEEN 20250101 AND 20251231
GROUP BY s.LocationKey,dl.Location,d.Month;

DROP TABLE IF EXISTS #TripLocMonth;
SELECT t.LocationKey,dl.Location,d.Month AS MonthKey,COUNT(*) AS Trips,AVG(CAST(t.CompletedOnTimeCount AS float)) AS OnTimeRate,AVG(CAST(DATEDIFF(minute,t.TripReadyDateTime,t.TripCompletedDateTime) AS float)) AS AvgCycle
INTO #TripLocMonth
FROM Recy.factTripSnapshot t
JOIN Recy.dimLocation dl ON dl.LocationKey=t.LocationKey
JOIN Recy.dimDate d ON d.DateKey=t.DateKey
WHERE t.DateKey BETWEEN 20250101 AND 20251231 AND t.TripReadyDateTime IS NOT NULL AND t.TripCompletedDateTime IS NOT NULL
GROUP BY t.LocationKey,dl.Location,d.Month;

WITH Profit AS(SELECT LocationKey,Location,SUM(ShipTons) AS ShipTons,SUM(Shipments) AS Shipments,SUM(Sales) AS Sales,SUM(ShipMargin) AS ShipMargin,SUM(ShipMargin)*1.0/NULLIF(SUM(Sales),0) AS ShipMarginPct FROM #ShipLocMonth GROUP BY LocationKey,Location),
Service AS(SELECT LocationKey,Location,SUM(Trips) AS Trips,SUM(OnTimeRate*Trips)*1.0/NULLIF(SUM(Trips),0) AS OnTimeRate,SUM(AvgCycle*Trips)*1.0/NULLIF(SUM(Trips),0) AS AvgCycle FROM #TripLocMonth GROUP BY LocationKey,Location),
Ranked AS(SELECT p.LocationKey,p.Location,p.ShipTons,p.Shipments,p.Sales,p.ShipMargin,p.ShipMarginPct,s.Trips,s.OnTimeRate,s.AvgCycle,DENSE_RANK() OVER(ORDER BY p.ShipMargin DESC) AS RankProfit,DENSE_RANK() OVER(ORDER BY s.OnTimeRate DESC) AS RankService FROM Profit p JOIN Service s ON s.LocationKey=p.LocationKey)
SELECT TOP(10) LocationKey,Location,ShipTons,Shipments,ShipMargin,ShipMarginPct,Trips,OnTimeRate,AvgCycle,RankProfit,RankService,RankProfit+RankService AS ExecScore
FROM Ranked
ORDER BY ExecScore,ShipMargin DESC;

-- Task 10
SELECT 
    ftripshot.LocationKey,
    ddate.Month AS MonthKey,
    dlocation.Location,
	count(*) as Trips,
	count(case when ftripshot.TripCompletedDateTime is not null and ftripshot.TripEnteredDateTime is not null  then 1 end) as CompletedTrips,
	count(case when ftripshot.TripCompletedDateTime is null and ftripshot.TripEnteredDateTime is not null then 1 end) as IncompletedTrips,
	(count(case when ftripshot.TripCompletedDateTime is null and ftripshot.TripEnteredDateTime is not null then 1 end)*1.0/count(*)) as IncompletePct
FROM [UC_NBT_Hackathon].[Recy].[factTripSnapshot] AS ftripshot
JOIN [Recy].[dimDate] AS ddate
    ON ftripshot.DateKey = ddate.DateKey
JOIN [Recy].[dimLocation] AS dlocation
    ON ftripshot.LocationKey = dlocation.LocationKey
GROUP BY 
    ftripshot.LocationKey,
    ddate.Month,
    dlocation.Location
having count(*) >= 50
order by IncompletePct desc;

IF OBJECT_ID('tempdb..#ShipLocMonth') IS NOT NULL DROP TABLE #ShipLocMonth;
IF OBJECT_ID('tempdb..#TopLoc')       IS NOT NULL DROP TABLE #TopLoc;
IF OBJECT_ID('tempdb..#InvMonthEnd')  IS NOT NULL DROP TABLE #InvMonthEnd;
IF OBJECT_ID('tempdb..#InvLocMonth')  IS NOT NULL DROP TABLE #InvLocMonth;

SELECT
  s.LocationKey,
  loc.Location,
  d.[Month] AS MonthKey,
  SUM(s.Pounds) AS Pounds,
  SUM(s.GrossTons) AS Tons,
  SUM(s.SalesAmount) AS Sales,
  SUM(s.Margin) AS Margin,
  SUM(s.FreightAmount) AS Freight,
  CAST(SUM(s.Margin) AS decimal(18,4)) / NULLIF(SUM(s.SalesAmount), 0) AS MarginPct
INTO #ShipLocMonth
FROM Recy.factScrapSalesShipments s
JOIN Recy.dimDate d ON d.DateKey = s.DateKey
JOIN Recy.dimLocation loc ON loc.LocationKey = s.LocationKey
WHERE s.DateKey BETWEEN @StartDateKey AND @EndDateKey
GROUP BY s.LocationKey, loc.Location, d.[Month];

SELECT TOP (3)
  LocationKey,
  Location,
  SUM(Margin) AS TotalMargin,
  SUM(Tons) AS TotalTons
INTO #TopLoc
FROM #ShipLocMonth
GROUP BY LocationKey, Location
ORDER BY SUM(Margin) DESC;

-- Task 8
WITH MonthEndRows AS (
  SELECT
    i.LocationKey,
    loc.Location,
    d.[Month] AS MonthKey,
    i.InventoryKey,
    inv.Inventory,
    i.EndingAmount,
    i.EndingGT,
    ROW_NUMBER() OVER (
      PARTITION BY i.LocationKey, d.[Month], i.InventoryKey
      ORDER BY i.DateKey DESC
    ) AS rn
  FROM Recy.factInventorySnapshot i
  JOIN Recy.dimDate d ON d.DateKey = i.DateKey
  JOIN Recy.dimLocation loc ON loc.LocationKey = i.LocationKey
  JOIN Recy.dimInventory inv ON inv.InventoryKey = i.InventoryKey
  WHERE i.DateKey BETWEEN @StartDateKey AND @EndDateKey
)
SELECT
  LocationKey,
  Location,
  MonthKey,
  InventoryKey,
  Inventory,
  EndingAmount,
  EndingGT
INTO #InvMonthEnd
FROM MonthEndRows
WHERE rn = 1;

SELECT
  LocationKey,
  Location,
  MonthKey,
  SUM(EndingAmount) AS InvAmount,
  SUM(EndingGT) AS InvGT
INTO #InvLocMonth
FROM #InvMonthEnd
GROUP BY LocationKey, Location, MonthKey;

DECLARE @LatestMonthKey int = (SELECT MAX(MonthKey) FROM #InvLocMonth);
DECLARE @PrevMonthKey   int = (SELECT MAX(MonthKey) FROM #InvLocMonth WHERE MonthKey < @LatestMonthKey);

SELECT
  cur.Location,
  @LatestMonthKey AS LatestMonth,
  cur.InvAmount AS LatestInvAmount,
  prev.InvAmount AS PrevInvAmount,
  cur.InvAmount - ISNULL(prev.InvAmount, 0) AS DeltaInvAmount,
  cur.InvGT AS LatestInvGT,
  prev.InvGT AS PrevInvGT,
  cur.InvGT - ISNULL(prev.InvGT, 0) AS DeltaInvGT
FROM #InvLocMonth cur
LEFT JOIN #InvLocMonth prev
  ON prev.LocationKey = cur.LocationKey
 AND prev.MonthKey = @PrevMonthKey
WHERE cur.MonthKey = @LatestMonthKey
ORDER BY ABS(cur.InvAmount - ISNULL(prev.InvAmount, 0)) DESC;

-- Task 9
DECLARE @TopLocationKey int = (
  SELECT TOP (1) LocationKey
  FROM #TopLoc
  ORDER BY TotalMargin DESC
);

WITH Latest AS (
  SELECT
    InventoryKey,
    Inventory,
    EndingAmount AS LatestEndingAmount,
    EndingGT AS LatestEndingGT
  FROM #InvMonthEnd
  WHERE LocationKey = @TopLocationKey
    AND MonthKey = @LatestMonthKey
),
Prev AS (
  SELECT
    InventoryKey,
    EndingAmount AS PrevEndingAmount,
    EndingGT AS PrevEndingGT
  FROM #InvMonthEnd
  WHERE LocationKey = @TopLocationKey
    AND MonthKey = @PrevMonthKey
),
Top10 AS (
  SELECT TOP (10) InventoryKey
  FROM Latest
  ORDER BY LatestEndingAmount DESC
)
SELECT
  l.Inventory,
  l.LatestEndingAmount,
  p.PrevEndingAmount,
  l.LatestEndingAmount - ISNULL(p.PrevEndingAmount, 0) AS DeltaEndingAmount,
  l.LatestEndingGT,
  p.PrevEndingGT,
  l.LatestEndingGT - ISNULL(p.PrevEndingGT, 0) AS DeltaEndingGT
FROM Top10 t
JOIN Latest l ON l.InventoryKey = t.InventoryKey
LEFT JOIN Prev p ON p.InventoryKey = t.InventoryKey
ORDER BY l.LatestEndingAmount DESC;

-- Task 10
SELECT
  t.LocationKey,
  loc.Location,
  d.[Month] AS MonthKey,
  COUNT(*) AS TotalTrips,
  SUM(CASE WHEN t.TripCompletedDateTime IS NOT NULL THEN 1 ELSE 0 END) AS CompletedTrips,
  SUM(CASE WHEN t.TripCompletedDateTime IS NULL THEN 1 ELSE 0 END) AS IncompleteTrips,
  CAST(SUM(CASE WHEN t.TripCompletedDateTime IS NULL THEN 1 ELSE 0 END) AS decimal(18,4)) / NULLIF(COUNT(*), 0) AS IncompletePct
FROM Recy.factTripSnapshot t
JOIN Recy.dimDate d ON d.DateKey = t.DateKey
JOIN Recy.dimLocation loc ON loc.LocationKey = t.LocationKey
WHERE t.DateKey BETWEEN @StartDateKey AND @EndDateKey
GROUP BY t.LocationKey, loc.Location, d.[Month]
HAVING COUNT(*) >= 50
ORDER BY IncompletePct DESC, TotalTrips DESC;

-- Task 11

-- Insights- Locations with higher total delay minutes per trip tend to have lower OnTimeRate.
-- Delay minutes are more strongly associated with AvgCycleMinutes inflation than with trip volume.
-- A small set of drivers can account for a disproportionate share of delay minutes at a location.


WITH DelayPerTrip AS (
  SELECT
    td.LocationKey,
    d.[Month] AS MonthKey,
    td.TripNumber,
    SUM(ISNULL(td.DelayMinutes, 0)) AS DelayMinutes
  FROM Recy.factTransportDelays td
  JOIN Recy.dimDate d ON d.DateKey = td.DateKey
  WHERE td.DateKey BETWEEN @StartDateKey AND @EndDateKey
  GROUP BY td.LocationKey, d.[Month], td.TripNumber
),
TripPerf AS (
  SELECT
    t.LocationKey,
    d.[Month] AS MonthKey,
    t.TripNumber,
    CASE WHEN t.CompletedOnTimeCount = 1 THEN 1 ELSE 0 END AS OnTimeFlag,
    CASE
      WHEN t.TripReadyDateTime IS NOT NULL AND t.TripCompletedDateTime IS NOT NULL
      THEN DATEDIFF(minute, t.TripReadyDateTime, t.TripCompletedDateTime)
    END AS CycleMinutes
  FROM Recy.factTripSnapshot t
  JOIN Recy.dimDate d ON d.DateKey = t.DateKey
  WHERE t.DateKey BETWEEN @StartDateKey AND @EndDateKey
),
Joined AS (
  SELECT
    p.LocationKey,
    p.MonthKey,
    p.TripNumber,
    ISNULL(dp.DelayMinutes, 0) AS DelayMinutes,
    p.OnTimeFlag,
    p.CycleMinutes
  FROM TripPerf p
  LEFT JOIN DelayPerTrip dp
    ON dp.LocationKey = p.LocationKey
   AND dp.MonthKey = p.MonthKey
   AND dp.TripNumber = p.TripNumber
)
SELECT
  loc.Location,
  j.MonthKey,
  COUNT(*) AS Trips,
  AVG(CAST(j.OnTimeFlag AS decimal(18,4))) AS OnTimeRate,
  AVG(CAST(j.DelayMinutes AS decimal(18,4))) AS AvgDelayMinutesPerTrip,
  AVG(CAST(j.CycleMinutes AS decimal(18,4))) AS AvgCycleMinutes
FROM Joined j
JOIN Recy.dimLocation loc ON loc.LocationKey = j.LocationKey
GROUP BY loc.Location, j.MonthKey
HAVING COUNT(*) >= 50
ORDER BY AvgDelayMinutesPerTrip DESC, OnTimeRate ASC;

