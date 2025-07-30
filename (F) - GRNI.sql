SELECT 
    PVO.[Order],
    pvo.Voucher,
    PVO.[Supplier],
    PVO.[Internal Reference],
    PVO.[Line],
    PVO.[Item Number],
    CAST(PVO.[Transaction Date] AS DATE) AS [Receipt Date],
    CAST(PVO.[GL Effective Date] AS DATE) AS [Effective Date],
    
    CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) AS [Qty Open],
    
    CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) + CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6)) AS [GL Cost],
    CAST(HIS.[PO Cost] AS DECIMAL(18,6)) AS [Purchase Cost],

    -- Extended PO Cost Accrued Tax
    ROUND(
        CAST(HIS.[PO Cost] AS DECIMAL(18,6)) 
        * (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)))
        * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0),
        2
    ) AS [Extended PO Cost Accrued Tax],

    -- Extended GL Cost
    (
        (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0))
        - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6))
    ) * (CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) + CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6))) AS [Ext GL Cost],

    -- PO-GL Var
    CASE 
        WHEN CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) + CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6)) = 0 THEN 0
        ELSE
            ROUND(
                CAST(HIS.[PO Cost] AS DECIMAL(18,6)) 
                * (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)))
                * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0),
                2
            )
            -
            (
                (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0))
                - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6))
            )
            * (CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) + CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6)))
    END AS [PO-GL Var],

    PVO.[Domain],
    PVO.Currency

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
    --AND PVO.[Order] IN ('PO14324')
    AND PVO.[Order Type] = '01'
    AND PVO.[Internal Reference Type] = '07'
    AND CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) <> 0
    AND pvo.Voucher = ''
