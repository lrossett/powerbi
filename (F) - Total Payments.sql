--🎯 Objective
--This query retrieves the total amount paid from check statements (ckd_det) against each AP voucher (invoice), even if the check was later canceled, in order to:
--Aggregate all attempted or recorded payments
--Compare it against the original invoice amount
--Identify what is still open or pending for payment
--This is particularly useful for reconciliation workflows in Accounts Payable (AP) reporting.

SELECT 
i.reference,
i.currency,
 CONCAT(i.[Domain],'_',i.[Reference]) AS [Reference_key], -- unique identifier per voucher across domains (great for Power BI joins)
c.reference AS [check],
CASE
WHEN UPPER(i.Currency) = 'CAD' THEN CAST(c.Amount as decimal (18,6))*1.25 ELSE CAST(c.Amount AS decimal (18,6))END AS [Payment],
CAST(v.[Last Paid] AS DATE) AS [Payment Date]
FROM ap_mstr i
LEFT JOIN vd_mstr s ON i.[Domain] = s.[Domain] AND i.[Supplier] = s.[Supplier] -- 	Supplier data
 JOIN vo_mstr v ON v.Domain = i.Domain and i.[Reference] = v.Voucher -- Links invoice to voucher
LEFT JOIN ckd_det c ON v.Domain = c.Domain and v.[Voucher] = c.Voucher -- Payment info — this is the core for what was paid
LEFT JOIN ck_mstr cm on c.Domain = cm.Domain and c.Reference = cm.Reference -- 	Lets you filter for canceled checks (which are still included here)
WHERE 
cm.[status] = 'CANCEL' AND i.[Domain] IN ('30', '35', '40','50')  
