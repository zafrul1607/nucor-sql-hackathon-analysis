# Methodology

This project uses SQL to analyze shipment profitability, trip service performance, inventory movement, and operational backlog signals from the 2025 Nucor hackathon dataset.

## Analysis Scope

All analysis is limited to 2025 using:

```sql
DateKey BETWEEN 20250101 AND 20251231

```
## Main Analytical Areas

### 1. Shipment Profitability

Shipment data was aggregated by location and month to calculate:

- Pounds shipped
- Gross tons shipped
- Sales
- Margin
- Freight
- Margin percentage

The top three locations were selected by total margin and used as the focus set for later consumer and driver analysis.

### 2. Consumer Contribution

For the highest-margin locations, consumers were ranked by total margin. Additional KPIs included:

- Sales
- Tons
- Margin percentage
- Margin per ton

This helped identify which customers were driving the most profitability at the top-performing locations.

### 3. Margin Trend

Monthly margin was calculated for the top consumers selected in the consumer contribution analysis.

A running year-to-date margin was calculated using a SQL window function. This helped show whether each top consumer’s margin contribution was stable, increasing, or declining across the year.

### 4. Consumer Concentration

Consumer concentration was analyzed to understand whether each top location depended heavily on one major consumer.

The top consumer’s margin was compared against the total margin from the top five consumers at the same location.

This helped identify concentration risk where one customer accounted for a large share of margin.

### 5. Trip Performance

Trip data was summarized by location and month to measure operational service performance.

Key metrics included:

- Total trips
- On-time rate
- Average cycle minutes

Cycle time was calculated only when both `TripReadyDateTime` and `TripCompletedDateTime` were available. This avoided inaccurate calculations from missing timestamps.

### 6. Driver Performance

For the top locations, drivers were ranked by trip volume.

The analysis calculated:

- Driver trip count
- On-time rate

This helped identify the most active drivers and compare their service performance.

### 7. Executive Scorecard

Shipment profitability and trip service performance were combined into one location-level scorecard.

The scorecard included:

- Shipment tons
- Shipment margin
- Shipment margin percentage
- Trips
- On-time rate
- Average cycle minutes
- Profitability rank
- Service rank

`DENSE_RANK()` was used to rank locations by profitability and service performance.

### 8. Inventory Snapshot Analysis

Inventory data was treated as a daily snapshot table.

To calculate month-end inventory, the latest `DateKey` within each location, month, and inventory was selected using `ROW_NUMBER()`.

This avoided double-counting daily inventory snapshots and allowed month-over-month inventory comparison.

### 9. Inventory Drilldown

For the highest-profit location, the analysis identified the top inventories by latest month-end ending amount.

The drilldown compared:

- Latest ending amount
- Previous ending amount
- Delta ending amount
- Latest ending gross tons
- Previous ending gross tons
- Delta ending gross tons

This helped identify which inventory categories had the largest value movement.

### 10. Backlog Signal

Incomplete trips were analyzed by location and month to identify potential backlog or process issues.

The analysis calculated:

- Total trips
- Completed trips
- Incomplete trips
- Incomplete trip percentage

Only location-month combinations with at least 50 trips were included to avoid overreacting to low-volume months.

### 11. Delay Performance Analysis

A self-directed analysis was created to connect delay minutes with trip performance.

Delay minutes were aggregated by trip and joined back to trip performance data. This helped compare delay burden, on-time rate, and average cycle time by location and month.

## SQL Techniques Used

This project used several SQL techniques, including:

- Joins across fact and dimension tables
- Temporary tables
- Common table expressions
- Aggregations
- Conditional aggregation
- Window functions
- `ROW_NUMBER()`
- `DENSE_RANK()`
- `NULLIF()` for safe division
- `DATEDIFF()` for cycle time calculation
- Month-end snapshot logic

## Data Quality and Calculation Rules

The following rules were used throughout the analysis:

- All analysis was limited to 2025.
- `DNU_` columns were not used for joins.
- `NULLIF()` was used to prevent division-by-zero errors.
- Cycle time was calculated only when both ready and completed timestamps existed.
- Inventory snapshots were reduced to month-end records before monthly comparison.
- `Recy.dimDate.Month` was used as `MonthKey`.

## Data Limitations

Query outputs are not included because the original hackathon dataset was provided in a restricted SQL environment.

This repository focuses on the SQL logic, schema understanding, methodology, and reproducible query structure rather than raw data or result tables.
