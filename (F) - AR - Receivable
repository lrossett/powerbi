SELECT 
AR.[Type],
CASE 
WHEN AR.[Type] = 'P' THEN 'Payment'
WHEN AR.[Type] = 'M' THEN 'Adjustments/Corrections'
WHEN AR.[Type] = 'I' THEN 'Invoice'
ELSE AR.[Type] END AS [Type Description], -- Translates the internal type codes to meaningful descriptions (e.g., 'P' → Payment)
CONCAT(UPPER([Domain]),'_',AR.[Reference]) AS [Reference_Key], -- Unique identifiers for invoice reference and customer domain composite key
AR.[Reference],
UPPER(AR.[Sold-To]) AS [Sold-To],
CONCAT(UPPER(AR.[Domain]),'_',UPPER(AR.[Sold-To])) AS [Customer_Key], -- Unique identifiers for invoice reference and customer domain composite key
UPPER(AR.[Ship-To]) AS [Ship-To],
UPPER(AR.[Sales Order]) AS [Sales Order],
cast(AR.[Date] as DATE) AS [Date],  -- Brings in AR dates to compute days to pay, due dates, and discount deadlines
cast(AR.[Effective] as DATE) AS [Effective Date],  -- Brings in AR dates to compute days to pay, due dates, and discount deadlines  
cast(AR.[Disc Date] as DATE) AS [Disc Date],  -- Brings in AR dates to compute days to pay, due dates, and discount deadlines
cast(AR.[Due Date] as DATE) AS [Due Date],  -- Brings in AR dates to compute days to pay, due dates, and discount deadlines
CASE 
    WHEN [Disc Date] is null and [open] = 0 then cast(AR.[Effective] as DATE) 
    ELSE cast(AR.[Paid Date] as DATE) 
    END AS [Paid Date], -- Handles missing discount dates and chooses appropriate payment date
CASE 
    WHEN AR.[Due Date] IS NULL THEN 0 
    ELSE DATEDIFF(DAY, CAST(AR.[Date] AS DATE), CAST(AR.[Due Date] AS DATE)) 
    END AS [Days_To_Receive], -- Measures time to receive payment vs. invoice and delay from due date
CASE 
    WHEN CAST(AR.[Paid Date] AS DATE) = CAST(AR.[Date] AS DATE) THEN 0 
    ELSE DATEDIFF(DAY, CAST(AR.[Date] AS DATE), CAST(AR.[Paid Date] AS DATE)) 
    END AS [Days_Received], -- Measures time to receive payment vs. invoice and delay from due date
    CASE 
    WHEN AR.[Paid Date] = AR.[Date] THEN 0 
    ELSE DATEDIFF(DAY, CAST(AR.[Due Date] AS DATE), CAST(AR.[Paid Date] AS DATE)) 
    END AS [Days_Delayed], -- Measures time to receive payment vs. invoice and delay from due date
CASE 
        WHEN ar.[Open] = 1 THEN 
            CASE
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -61 THEN 'Due + 60 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -31 THEN 'Due in 31 - 60 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -8  THEN 'Due in 8 - 30 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -2  THEN 'Due in 2 - 7 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) = -1   THEN 'Due Tomorrow'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) = 0    THEN 'Due Today'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 30  THEN 'Overdue 0-30'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 60  THEN 'Overdue 31-60'
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 90  THEN 'Overdue 61-90'
                ELSE 'Overdue 90+'
            END
        ELSE 
            CASE
                WHEN AR.[Due Date] IS NULL AND AR.[Paid Date] = AR.[Date]   THEN 'Due Today'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -61    THEN 'Due + 60 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -31    THEN 'Due in 31 - 60 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -8     THEN 'Due in 8 - 30 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -2     THEN 'Due in 2 - 7 days'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) = -1      THEN 'Due Tomorrow'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) = 0       THEN 'Due Today'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 30     THEN 'Overdue 0-30'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 60     THEN 'Overdue 31-60'
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 90     THEN 'Overdue  61-90'
                ELSE 'Overdue 90+'
            END
    END AS [Aging_Bucket], -- Dynamically creates aging logic depending on whether invoice is open or paid
    CASE 
        WHEN ar.[Open] = 1 THEN 
            CASE
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -61 THEN 1
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -31 THEN 2
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -8  THEN 3
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= -2  THEN 4
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) = -1   THEN 5
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) = 0    THEN 6
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 30  THEN 7
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 60  THEN 8
                WHEN DATEDIFF(DAY, AR.[Due Date], GETDATE()) <= 90  THEN 9
                ELSE 10
            END
        ELSE 
            CASE
                WHEN AR.[Due Date] IS NULL AND AR.[Paid Date] = AR.[Date]   THEN 6
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -61    THEN 1
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -31    THEN 2
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -8     THEN 3
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= -2     THEN 4
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) = -1      THEN 5
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) = 0       THEN 6
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 30     THEN 7
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 60     THEN 8
                WHEN DATEDIFF(DAY, AR.[Due Date], AR.[Paid Date]) <= 90     THEN 9
                ELSE 10
            END
    END AS [Aging_Index],
        CASE 
        WHEN [open] = 0 AND DATEDIFF(DAY, [Due Date], [Paid Date]) <= 0 THEN 'Before Due'
        WHEN [open] = 0 THEN 'Overdue'
        WHEN [open] = 1 AND DATEDIFF(DAY, [Due Date], GETDATE()) <= 0 THEN 'Before Due'
        ELSE 'Overdue'
    END AS [Due Status], -- Classifies each line as "Overdue" or "Before Due" based on real payment dates
AR.[Open],
AR.[Check],
AR.[Bank],
AR.[Currency],
AR.[Batch],
AR.[Account],
AR.[Disc Acct],
AR.[Disc Cost Ctr],
AR.[Cr Terms],
AR.[Domain],
AR.[Sub-Account],
 CASE 
        WHEN UPPER(Currency) = 'CAD' THEN CAST([Amount] AS DECIMAL(18,6)) / 1.25
        WHEN UPPER(Currency) = 'EUR' THEN CAST([Amount] AS DECIMAL(18,6)) / 0.833
        ELSE CAST([Amount] AS DECIMAL(18,6))
    END AS [Amount],
    CASE 
        WHEN UPPER(Currency) = 'CAD' THEN CAST([Applied Amt] AS DECIMAL(18,6)) / 1.25
        WHEN UPPER(Currency) = 'EUR' THEN CAST([Applied Amt] AS DECIMAL(18,6)) / 0.833
        ELSE CAST([Applied Amt] AS DECIMAL(18,6))
    END AS [Received Amount],
    CASE 
        WHEN UPPER(Currency) = 'CAD' THEN (CAST([Amount] AS DECIMAL (18,6)) - CAST([Applied Amt] AS DECIMAL (18,6))) / 1.25
        WHEN UPPER(Currency) = 'EUR' THEN (CAST([Amount] AS DECIMAL (18,6)) - CAST([Applied Amt] AS DECIMAL (18,6))) / 0.833
        ELSE CAST([Amount] AS DECIMAL (18,6)) - CAST([Applied Amt] AS DECIMAL (18,6)) 
        end as [Open Amount],
--CAST([Base Amt] AS DECIMAL (18,6)) AS [Base Amount],
---CAST([Base Applied Amt] AS DECIMAL (18,6)) AS [Base Applied Amount],
 CASE 
        WHEN UPPER(Currency) = 'CAD' THEN CAST([Gr Margin] AS DECIMAL(18,6)) / 1.25
        WHEN UPPER(Currency) = 'EUR' THEN CAST([Gr Margin] AS DECIMAL(18,6)) / 0.833
        ELSE CAST([Gr Margin] AS DECIMAL(18,6))
    END AS [Gr Margin]
from ar_mstr AR  WHERE AR.[Domain] IN ('30', '35', '40','50')
and [Sold-To] NOT LIKE ('1BIME%')
