# Methodology

This project uses SQL to analyze shipment profitability, trip service performance, inventory movement, and operational backlog signals from the 2025 Nucor hackathon dataset.

## Analysis Scope

All analysis is limited to 2025 using:

```sql
DateKey BETWEEN 20250101 AND 20251231

```
## Main Analytical Areas
1. Shipment Profitability

Shipment data was aggregated by location and month to calculate:

Pounds shipped
Gross tons shipped
Sales
Margin
Freight
Margin percentage

The top three locations were selected by total margin and used as the focus set for later consumer and driver analysis.

2. Consumer Contribution

For the highest-margin locations, consumers were ranked by total margin. Additional KPIs included:

Sales
Tons
Margin percentage
Margin per ton

This helped identify which customers were driving profitability.

3. Margin Trend

Monthly margin was calculated for top consumers. A running YTD margin was calculated using a SQL window function.

4. Trip Performance

Trip data was summarized by location and month using:

Trip count
On-time rate
Average cycle minutes

Cycle time was calculated only when both ready and completed timestamps existed.

5. Executive Scorecard

Profitability and service metrics were combined into a concise ranking table using dense ranking.

6. Inventory Snapshot Analysis

Inventory data was treated as a snapshot table. Month-end inventory was selected using ROW_NUMBER() to identify the latest DateKey within each month, location, and inventory.

7. Backlog Signal

Incomplete trip percentage was calculated by location and month to identify areas where trips were entered but not completed.

Data Limitations

Query outputs are not included because the original hackathon dataset was provided in a restricted SQL environment. This repository focuses on SQL logic, schema understanding, methodology, and reproducible query structure.
