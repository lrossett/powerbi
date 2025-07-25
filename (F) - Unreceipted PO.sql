SELECT
POD.[Purchase Order],
POD.[line],
CONCAT(POD.[Purchase Order],pod.[line]) AS [PO_Line_Key], -- Composite key for use in Power BI or reporting systems to join with other detail or receipt data.
CAST (POD.[Due Date] AS date) AS [Due Date], -- The expected delivery date for the line item.\ Essential for forecasting incoming stock and analyzing supplier performance.
CAST (POD.[Qty Ordered] AS decimal (18,6)) * CAST (POD.[Purchase Cost] AS decimal (18,6)) AS [total], -- Calculates the total cost of the PO line: Quantity × Unit Price. \ Calculates the total cost of the PO line: Quantity × Unit Price.
POM.[Supplier],
POD.[Domain],
    CASE WHEN 
    POD.[DOMAIN] = 50 THEN 'CAD'
    ELSE 'USD' END AS [Currency] -- Assigns currency based on domain logic (Domain 50 = CAD, others = USD)

  FROM pod_det POD
 LEFT JOIN po_mstr POM ON POM.[domain] = POD.[domain] and POM.[Purchase Order] = POD.[Purchase Order]
 WHERE
  POD.[pod__qad04] IS NULL AND -- flag column that marks lines that are not yet received or completed
  POD.DOMAIN IN (30,35,40,50) AND  -- Includes only selected operational domains (30, 35, 40, 50)
  YEAR(CAST (POD.[Due Date] AS date)) >= 2025 -- Filters for future or current PO lines only (from 2025 onward)
