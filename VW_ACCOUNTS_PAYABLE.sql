SELECT 
    UPPER(i.[Supplier]) AS [Supplier Code],
    s.[Currency] AS [Supplier Currency],
    s.[Cr Terms] AS [Credit Terms],
    UPPER(s.[Sort Name]) AS [Supplier],
    i.[Reference],
    CAST(i.[Date] AS DATE) AS [Invoice Date],
    CAST(v.[Due Date] AS DATE) AS [Due Date],
    
    DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) AS [Days_Past_Due],

    CASE
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 'Current'
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 30 THEN '0-30'
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 60 THEN '31-60'
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 90 THEN '61-90'
        ELSE '90+'
    END AS [Aging_Bucket],

    CASE
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 1
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 30 THEN 2
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 60 THEN 3
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 90 THEN 4
        ELSE 5
    END AS [Aging_Index],

    CASE 
        WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 'Not Due'
        ELSE 'Overdue'
    END AS [Due Status],

    CASE 
        WHEN UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) * 1.25
        ELSE CAST(i.[Amount] AS DECIMAL(18,6))
    END AS [Total Amount],

    CASE 
        WHEN c.Amount IS NULL THEN CAST(i.[Amount] AS DECIMAL(18,6))
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) = CAST(c.Amount AS DECIMAL(18,6)) THEN 0
        ELSE CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6))
    END AS [Open Amount],

    CASE 
        WHEN c.Amount IS NULL AND UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) * 1.25
        WHEN c.Amount IS NULL AND UPPER(i.Currency) = 'USD' THEN CAST(i.[Amount] AS DECIMAL(18,6))
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) = CAST(c.Amount AS DECIMAL(18,6)) THEN 0
        WHEN UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6)) * 1.25
        ELSE CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6))
    END AS [Open Amount USD],

    CASE 
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) < 0 THEN 'Credit Memo'
        ELSE 'Purchase'
    END AS [Invoice Type],

    UPPER(i.Currency) AS [Currency],
    i.[open] AS [Open],
    i.[domain] AS [Domain]

FROM ap_mstr i
LEFT JOIN vd_mstr s 
    ON i.[Domain] = s.[Domain] 
    AND i.[Supplier] = s.[Supplier]
JOIN vo_mstr v 
    ON v.[Domain] = i.[Domain] 
    AND i.[Reference] = v.[Voucher]
LEFT JOIN ckd_det c 
    ON v.[Domain] = c.[Domain] 
    AND v.[Voucher] = c.[Voucher]

WHERE 
    i.[Domain] IN ('30', '35', '40', '50') 
    AND CAST(i.[Amount] AS DECIMAL(18,6)) <> 0
    AND (
        i.[Supplier] NOT LIKE '5BIM%' 
        OR i.[Supplier] IN ('5BIME005', '5BIME010')
    );
