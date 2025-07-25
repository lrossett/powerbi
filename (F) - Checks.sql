--🎯 Objective
--This query retrieves accounts payable records (vouchers) with canceled payments, allowing finance or accounting teams to:
--Track canceled checks
--Reconcile against invoices
--Audit payment anomalies (e.g., reissues, reversals)
--Normalize currency values for accurate reporting

SELECT
i.reference,
   CAST(cm.[Clear Date] AS date) [Clear Date], -- The date when the check was originally cleared (before cancellation). \ Useful to calculate how long after clearance it was canceled.
     CONCAT(i.[Domain],'_',i.[Reference]) AS [Reference_key],
c.reference AS [check], -- The check number or payment reference tied to the voucher.
CASE
WHEN UPPER(i.Currency) = 'CAD' THEN CAST(c.Amount AS decimal (18,6))/1.25 
WHEN UPPER(i.Currency) = 'EUR' THEN CAST(c.Amount AS decimal (18,6))/0.833
ELSE CAST(c.Amount AS decimal (18,6))END as [Payment] -- Converts the payment to a common base (likely USD), using hardcoded rates.

FROM ap_mstr i -- Base AP data — invoices/vouchers
LEFT JOIN vd_mstr s ON i.[Domain] = s.[Domain] AND i.[Supplier] = s.[Supplier] -- Vendor metadata (used here only for join integrity)
JOIN vo_mstr v ON v.Domain = i.Domain and i.[Reference] = v.Voucher -- Voucher/order data — links voucher to check
LEFT JOIN ckd_det c ON v.Domain = c.Domain and v.[Voucher] = c.Voucher -- Check detail — connects checks to vouchers
LEFT JOIN ck_mstr cm on c.Domain = cm.Domain and c.Reference = cm.Reference -- Check master — used to filter for canceled checks and get clear date
WHERE
cm.[status] = 'CANCEL' AND
i.[Domain] IN ('30', '35', '40','50')
