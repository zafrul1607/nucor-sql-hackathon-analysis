# Schema Overview

The hackathon dataset follows a star-schema style structure. Fact tables contain measurable business events, while dimension tables provide descriptive attributes for dates, locations, customers, suppliers, materials, vehicles, inventory, drivers, and dispatchers.

## Core Date Rule

All analysis is limited to 2025:

```sql
WHERE DateKey BETWEEN 20250101 AND 20251231

d.Month AS MonthKey

FROM Recy.factScrapSalesShipments s
JOIN Recy.dimDate d
    ON d.DateKey = s.DateKey
JOIN Recy.dimLocation loc
    ON loc.LocationKey = s.LocationKey
JOIN Recy.dimSupplier sup
    ON sup.SupplierKey = s.SupplierKey
JOIN Recy.dimConsumer c
    ON c.ConsumerKey = s.ConsumerKey
JOIN Recy.dimMaterial m
    ON m.MaterialKey = s.MaterialKey
LEFT JOIN Recy.dimVehicleType vt
    ON vt.VehicleTypeKey = s.VehicleTypeKey

FROM Recy.factScrapSalesShipments s
JOIN Recy.dimDate d
    ON d.DateKey = s.DateKey
JOIN Recy.dimLocation loc
    ON loc.LocationKey = s.LocationKey
JOIN Recy.dimSupplier sup
    ON sup.SupplierKey = s.SupplierKey
JOIN Recy.dimConsumer c
    ON c.ConsumerKey = s.ConsumerKey
JOIN Recy.dimMaterial m
    ON m.MaterialKey = s.MaterialKey
LEFT JOIN Recy.dimVehicleType vt
    ON vt.VehicleTypeKey = s.VehicleTypeKey

FROM Recy.factTripSnapshot t
JOIN Recy.dimDate d
    ON d.DateKey = t.DateKey
JOIN Recy.dimLocation loc
    ON loc.LocationKey = t.LocationKey
JOIN Recy.dimSupplier sup
    ON sup.SupplierKey = t.SupplierKey
LEFT JOIN Recy.dimDriverHackathon drv
    ON drv.DriverHackKey = t.DriverHackKey
JOIN Recy.dimDispatcherHackathon disp
    ON disp.DispatcherHackKey = t.DispatcherHackKey

FROM Recy.factTransportDelays td
JOIN Recy.dimDate d
    ON d.DateKey = td.DateKey
JOIN Recy.dimLocation loc
    ON loc.LocationKey = td.LocationKey
JOIN Recy.dimDriverHackathon drv
    ON drv.DriverHackKey = td.DriverHackKey

td.DateKey = t.DateKey
td.LocationKey = t.LocationKey
td.TripNumber = t.TripNumber

FROM Recy.factInventorySnapshot i
JOIN Recy.dimDate d
    ON d.DateKey = i.DateKey
JOIN Recy.dimLocation loc
    ON loc.LocationKey = i.LocationKey
JOIN Recy.dimInventory inv
    ON inv.InventoryKey = i.InventoryKey

ROW_NUMBER() OVER (
    PARTITION BY i.LocationKey, d.Month, i.InventoryKey
    ORDER BY i.DateKey DESC
) AS rn

WHERE rn = 1


```text

