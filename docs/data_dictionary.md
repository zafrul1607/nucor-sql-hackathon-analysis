# Data Dictionary

## Database Information

- Database: UC_NBT_Hackathon
- Schema: Recy
- Analysis year: 2025
- Date filter: DateKey BETWEEN 20250101 AND 20251231

## Important Rules

- DateKey is an integer in YYYYMMDD format.
- DateKey joins to Recy.dimDate.DateKey.
- DNU_ columns should not be used for joins.
- There is no physical MonthKey column.
- Use Recy.dimDate.Month as MonthKey.

## Fact Tables

### Recy.factScrapSalesShipments

Purpose: Shipment-level financial and volume measures.

Grain: One row per shipment item.

Main columns:
- ShipmentItemId
- DateKey
- LocationKey
- SupplierKey
- ConsumerKey
- MaterialKey
- VehicleTypeKey
- Pounds
- GrossTons
- SalesAmount
- FreightAmount
- CostOfGoodsSold
- Margin

Derived KPIs:
- MarginPct = Margin / SalesAmount
- MarginPerTon = Margin / GrossTons
- FreightPerTon = FreightAmount / GrossTons

### Recy.factTripSnapshot

Purpose: Trip performance snapshot with timing, completion, drivers, and dispatchers.

Grain: One row per trip per date.

Main columns:
- DateKey
- LocationKey
- SupplierKey
- TripNumber
- CompletedOnTimeCount
- TripReadyDateTime
- TripEnteredDateTime
- TripCompletedDateTime
- DriverHackKey
- DispatcherHackKey

Derived KPIs:
- Trips = COUNT(*)
- OnTimeRate = SUM(CompletedOnTimeCount) / completed trips
- CycleMinutes = DATEDIFF(minute, TripReadyDateTime, TripCompletedDateTime)

### Recy.factTransportDelays

Purpose: Delay events and delay minutes tied to trips.

Grain: One row per delay event per trip segment.

Main columns:
- DateKey
- LocationKey
- DriverHackKey
- TripNumber
- TripSegmentNumber
- DelaySequenceNumber
- DelayNumber
- DelayMinutes

### Recy.factInventorySnapshot

Purpose: Daily ending inventory snapshot by location and inventory.

Grain: One row per location, inventory, and date.

Main columns:
- DateKey
- LocationKey
- InventoryKey
- InventoryCode
- YardCode
- EndingLB
- EndingGT
- EndingAmount

Month-end logic:
Use ROW_NUMBER() partitioned by LocationKey, Month, and InventoryKey, ordered by DateKey descending, then filter to rn = 1.

## Dimension Tables

### Recy.dimDate
Used for calendar and fiscal attributes.

Key:
- DateKey

Important columns:
- Month
- Year
- Quarter
- Fiscal_Year
- Fiscal_Month

### Recy.dimLocation
Used for masked location or yard labels.

Key:
- LocationKey

### Recy.dimSupplier
Used for masked supplier information.

Key:
- SupplierKey

### Recy.dimConsumer
Used for masked consumer/customer information.

Key:
- ConsumerKey

### Recy.dimMaterial
Used for material codes and product group rollups.

Key:
- MaterialKey

### Recy.dimVehicleType
Used for shipment vehicle type.

Key:
- VehicleTypeKey

### Recy.dimInventory
Used for inventory master information.

Key:
- InventoryKey

### Recy.dimDriverHackathon
Used for masked driver names.

Key:
- DriverHackKey

### Recy.dimDispatcherHackathon
Used for masked dispatcher names.

Key:
- DispatcherHackKey
