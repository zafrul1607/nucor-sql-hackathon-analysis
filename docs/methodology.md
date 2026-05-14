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

This helped identify which customers were driving profitability.

Query outputs are not included because the original hackathon dataset was provided in a restricted SQL environment. This repository focuses on SQL logic, schema understanding, methodology, and reproducible query structure.
