SELECT 
    UPPER(i.[Supplier]) AS [Supplier Code],
    s.[Currency] AS [Supplier Currency],
    s.[Cr Terms] AS [Credit Terms],
    UPPER(s.[Sort Name]) AS [Supplier],
    i.[Reference],
    CAST(i.[Date] AS DATE) AS [Invoice Date],
    CAST(v.[Due Date] AS DATE) AS [Due Date],
    CAST(v.[Last Paid] AS DATE) AS [Payment Date],

    -- Days Past Due
    CASE 
        WHEN [Open] = 0 THEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE))
        ELSE DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE())
    END AS [Days_Past_Due],

    -- Aging Bucket
    CASE 
        WHEN i.[Open] = 1 THEN 
            CASE
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 'Current'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 30 THEN '0-30'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 60 THEN '31-60'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 90 THEN '61-90'
                ELSE '90+'
            END
        ELSE 
            CASE
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 0 THEN 'On Time'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 30 THEN '0-30'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 60 THEN '31-60'
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 90 THEN '61-90'
                ELSE '90+'
            END
    END AS [Aging_Bucket],

    -- Aging Index
    CASE 
        WHEN i.[Open] = 1 THEN 
            CASE
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 1
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 30 THEN 2
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 60 THEN 3
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 90 THEN 4
                ELSE 5
            END
        ELSE 
            CASE
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 0 THEN 0
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 30 THEN 2
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 60 THEN 3
                WHEN DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 90 THEN 4
                ELSE 5
            END
    END AS [Aging_Index],

    -- Due Status
    CASE 
        WHEN [Open] = 0 AND DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) <= 0 THEN 'On Time'
        WHEN [Open] = 0 AND DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), CAST(v.[Last Paid] AS DATE)) > 0 THEN 'Overdue'
        WHEN [Open] = 1 AND DATEDIFF(DAY, CAST(v.[Due Date] AS DATE), GETDATE()) <= 0 THEN 'Not Due'
        ELSE 'Overdue'
    END AS [Due Status],

    -- Amounts
    CASE 
        WHEN UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) * 1.25
        ELSE CAST(i.[Amount] AS DECIMAL(18,6))
    END AS [Total Amount],

    CASE 
        WHEN CAST(c.Amount AS DECIMAL(18,6)) IS NULL THEN CAST(i.[Amount] AS DECIMAL(18,6))
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) = CAST(c.Amount AS DECIMAL(18,6)) THEN 0
        ELSE CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6))
    END AS [Open Amount],

    CASE 
        WHEN CAST(c.Amount AS DECIMAL(18,6)) IS NULL AND UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) * 1.25
        WHEN CAST(c.Amount AS DECIMAL(18,6)) IS NULL AND UPPER(i.Currency) = 'USD' THEN CAST(i.[Amount] AS DECIMAL(18,6))
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) = CAST(c.Amount AS DECIMAL(18,6)) THEN 0
        WHEN UPPER(i.Currency) = 'CAD' THEN CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6)) * 1.25
        ELSE CAST(i.[Amount] AS DECIMAL(18,6)) - CAST(c.Amount AS DECIMAL(18,6))
    END AS [Open Amount USD],

    -- Other fields
    CASE 
        WHEN CAST(i.[Amount] AS DECIMAL(18,6)) < 0 THEN 'Credit Memo'
        ELSE 'Purchase'
    END AS [Invoice Type],

    UPPER(i.Currency) AS [Currency],
    i.[Open] AS [Open],
    i.[Domain] AS [Domain]

FROM ap_mstr i
LEFT JOIN vd_mstr s 
    ON i.[Domain] = s.[Domain] AND i.[Supplier] = s.[Supplier]
JOIN vo_mstr v 
    ON v.[Domain] = i.[Domain] AND i.[Reference] = v.[Voucher]
LEFT JOIN ckd_det c 
    ON v.[Domain] = c.[Domain] AND v.[Voucher] = c.[Voucher]

WHERE 
    i.[Domain] IN ('30', '35', '40', '50') 
    AND CAST(i.[Amount] AS DECIMAL(18,6)) <> 0
    AND (
        i.[Supplier] NOT LIKE '5BIM%' 
        OR i.[Supplier] IN ('5BIME005', '5BIME010')
    );

