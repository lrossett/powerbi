SELECT 
    PVO.[Order],
    PVO.[Supplier],
    PVO.[Internal Reference],
    PVO.[Line],
    PVO.[Item Number],
    CAST(PVO.[Transaction Date] AS DATE) AS [Receipt Date],
    CAST(PVO.[GL Effective Date] AS DATE) AS [Effective Date],
    
    CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) AS [Qty Open], -- Open quantity not yet invoiced / Core of the GRNI logic
    
    CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) +  CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6))  AS [GL Cost],  -- GL Cost = Standard cost used for inventory valuation (includes material + sub costs)
    CAST(HIS.[PO Cost] AS DECIMAL(18,6)) AS [Purchase Cost], --  Purchase order unit cost used for invoicing

    -- Extended PO Cost Accrued Tax (Qty Open * PO Cost * UM Conversion)
    ROUND(
        CAST(HIS.[PO Cost] AS DECIMAL(18,6)) 
        * (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)))
        * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0),
    2) AS [Extended PO Cost Accrued Tax],

    -- Extended GL Cost  (Qty Open * GL Cost)
    ((CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) 
    * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) )
    * (CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) +  CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6)))  AS [Ext GL Cost],

    -- PO-GL Var Shows if there’s a difference between PO value and what’s hitting GL \ Important for accrual adjustments and reconciliation
    CASE 
        WHEN CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) + (CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) +  CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6))) = 0 THEN 0
        ELSE   
      -- extended PO COST  
        ROUND(
        CAST(HIS.[PO Cost] AS DECIMAL(18,6)) 
        * (CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)))
        * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0),
    2) 
    -
    ((CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) 
    * ISNULL(CAST(HIS.[UM Conversion] AS DECIMAL(18,6)), 1.0)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) )
    * (CAST(HIS.[Std Mtl Cost] AS DECIMAL(18,6)) +  CAST(HIS.[STD Sub Cost] AS DECIMAL(18,6))) 

    END AS [PO-GL Var],

    PVO.[Domain],
    case when 
    PVO.[DOMAIN] = 50 THEN 'CAD'
    ELSE 'USD' END as [Currency]

FROM [dbo].[pvo_mstr] PVO
LEFT JOIN pod_det POD -- (POD): Included but unused — might be used for future enrichments
    ON PVO.[Line] = POD.[Line]
    AND PVO.[Domain] = POD.[Domain]
    AND PVO.[Order] = POD.[Purchase Order]
LEFT JOIN prh_hist HIS --  (HIS): Brings in unit costs and UM conversion based on receiver + line match
    ON PVO.[Line] = HIS.[PO Line]
    AND PVO.[Domain] = HIS.[Domain]
    AND PVO.[Internal Reference] = HIS.[Receiver]

WHERE 
    PVO.[Domain] IN (30, 35, 40, 50)
    --AND PVO.[Supplier] = '5UNIV004'
    AND PVO.[Order Type] = '01' -- PO Type filter (standard POs)
    AND PVO.[Internal Reference Type] = '07' -- Receipt-type lines only
    AND CAST(PVO.[Transaction Qty] AS DECIMAL(18,6)) - CAST(PVO.[Vouchered Qty] AS DECIMAL(18,6)) <> 0  -- Only open lines (not fully vouchered)
    AND pvo.Voucher = ''
