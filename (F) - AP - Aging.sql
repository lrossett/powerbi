WITH cte_ck_mstr AS (
    SELECT 
        cm.[Reference],
        MAX(cm.[Clear Date]) AS [Clear Date]
    FROM ck_mstr cm
    GROUP BY cm.[Reference]
)
SELECT DISTINCT
    CONCAT(i.[Domain], '_', UPPER(i.[Supplier])) AS [Supplier_Key],
    UPPER(i.[Supplier]) AS [Supplier Code],
    s.[Currency] AS [Supplier Currency],
    s.[Cr Terms] AS [Credit Terms],
    UPPER(s.[Sort Name]) AS [Supplier],
    i.[Reference],
    CONCAT(i.[Domain], '_', i.[Reference]) AS [Reference_key],
    CAST(i.[Date] AS DATE) AS [Invoice Date],
    CAST(v.[Due Date] AS DATE) AS [Due Date],
    CAST(v.[Last Paid] AS DATE) AS [Payment Date],
    DATEDIFF(DAY, CAST(i.[Date] AS DATE), CAST(v.[Due Date] AS DATE)) AS [Days to Pay],
    
    CASE 
        WHEN [Open] = 0 THEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE))
        ELSE DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE())
    END AS [Days_Past_Due],

    DATEDIFF(DAY, CAST(i.[Date] AS DATE), CAST(v.[Last Paid] AS DATE)) AS [Lead_Time_Days],

    CASE 
        WHEN i.[Open] = 1 THEN 
            CASE
                WHEN DATEDIFF(DAY, v.[Due Date], GETDATE()) <= 0 THEN  'Current'
                WHEN DATEDIFF(DAY, v.[Due Date], GETDATE()) <= 30 THEN 'Overdue 0-30'
                WHEN DATEDIFF(DAY, v.[Due Date], GETDATE()) <= 60 THEN 'Overdue 31-60'
                WHEN DATEDIFF(DAY, v.[Due Date], GETDATE()) <= 90 THEN 'Overdue 61-90'
                ELSE 'Overdue 90+'
            END
        ELSE 
            CASE
                WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 0 THEN  'Current'
                WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 30  THEN 'Overdue 0-30'
                WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 60  THEN 'Overdue 31-60'
                WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 90  THEN 'Overdue  61-90'
                ELSE 'Overdue 90+'
            END
    END AS [Aging_Bucket],
    CASE 
    WHEN i.[Open] = 1 THEN 
        CASE
            WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0  THEN 1
            WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 30 THEN 2
            WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 60 THEN 3
            WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 90 THEN 4
            ELSE 5
        END
    ELSE 
        CASE
            WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 0  THEN 1
            WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 30 THEN 2
            WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 60 THEN 3
            WHEN DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 90 THEN 4
            ELSE 5
        END
END AS [Aging_Index],

    CASE 
        WHEN [open] = 0 AND DATEDIFF(DAY, v.[Due Date], IIF(cm.[Clear Date] is null, v.[Last Paid], cm.[Clear Date])) <= 0 THEN 'Current'
        WHEN [open] = 0 THEN 'Overdue'
        WHEN [open] = 1 AND DATEDIFF(DAY, v.[Due Date], GETDATE()) <= 0 THEN 'Current'
        ELSE 'Overdue'
    END AS [Due Status],

    CASE 
        WHEN UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) / 1.25
        WHEN UPPER(i.Currency) = 'EUR' THEN CAST(i.[Amount] AS DECIMAL(18,6)) / 0.833
        ELSE CAST(i.[Amount] AS DECIMAL(18,6))
    END AS [Total Amount],

    CASE 
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) < 0 THEN 'Credit Memo'
        ELSE 'Purchase'
    END AS [Invoice Type],

    UPPER(i.Currency) AS 'Currency',
    i.[Open] AS [Open],
    i.[Domain] AS [Domain],
     (
        SELECT 
            SUM(CAST(c.Amount AS DECIMAL(18,6)) * CAST(c.[Exch Rate] AS DECIMAL(18,6)))
        FROM ckd_det c
        WHERE 
            c.Domain = i.Domain 
            AND c.Voucher = i.Reference
 -- and i.[Open] <> 1
    ) AS [Total Paid]

FROM ap_mstr i
LEFT JOIN vd_mstr s ON i.[Domain] = s.[Domain] AND i.[Supplier] = s.[Supplier]
JOIN vo_mstr v ON v.Domain = i.Domain AND i.[Reference] = v.Voucher
LEFT JOIN ckd_det c ON v.Domain = c.Domain AND v.[Voucher] = c.Voucher
LEFT JOIN cte_ck_mstr cm ON i.Reference = cm.Reference

WHERE i.[Domain] IN ('30', '35', '40', '50')  

--and i.Supplier = '5FLAV002' AND [OPEN] = 1 

AND CAST(i.[Amount] AS DECIMAL(18,6)) <> 0;
