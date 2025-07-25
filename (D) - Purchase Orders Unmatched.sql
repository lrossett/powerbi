--🎯 Purpose of the Query
-- This query returns a distinct list of open Purchase Orders per domain, by unioning two sources:
-- POs received but not fully invoiced (GRNI)
-- Os not yet received at all (pending delivery)
-- It’s especially valuable for:
-- Inventory accrual reporting
-- Procurement visibility
-- Financial commitment tracking
-- Building a "What’s Still Open?" report in Power BI
SELECT DISTINCT 
    PVO.[Order] AS [Purchase Order],
    PVO.[Domain]
FROM [dbo].[pvo_mstr] PVO
LEFT JOIN pod_det POD 
    ON PVO.[Line] = POD.[Line]
    AND PVO.[Domain] = POD.[Domain]
    AND PVO.[Order] = POD.[Purchase Order]
LEFT JOIN prh_hist HIS 
    ON PVO.[Line] = HIS.[PO Line]
    AND PVO.[Domain] = HIS.[Domain]
    AND PVO.[Internal Reference] = HIS.[Receiver]
WHERE 
    PVO.[Domain] IN (30, 35, 40, 50)
    AND PVO.[Order Type] = '01'
    AND PVO.[Internal Reference Type] = '07'
    AND CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) <> 0
-- Gets POs that have receipts, but not fully vouchered
-- GRNI = received but not invoiced (still open in AP)
-- The join with prh_hist allows for extended cost logic if needed later

UNION

SELECT DISTINCT 
    pod.[Purchase Order],
    pod.[Domain]
FROM pod_det pod
LEFT JOIN po_mstr pom ON pom.domain = pod.domain AND pom.[Purchase Order] = pod.[Purchase Order]

WHERE 
    pod.[pod__qad04] IS NULL  
    AND pod.[Domain] IN (30,35,40,50) 
    AND YEAR(CAST(pod.[Due Date] AS DATE)) >= 2025;

-- Gets POs that are open in the system but have no receipts yet
-- pod__qad04 IS NULL likely flags "not yet received"
-- Focuses on future expected deliveries (2025+)
