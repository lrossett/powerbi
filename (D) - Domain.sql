SELECT
DOM.Domain,
DOM.[Name],
DOM.[Domain Type],
[Currency],
CASE
WHEN [Currency] = 'USD' THEN 1
WHEN [Currency] = 'CAD' THEN 1.25
ELSE 1 END AS [Rate]
FROM dom_mstr DOM
LEFT JOIN en_mstr ENT ON ENT.[Domain] = DOM.[Domain]
WHERE DOM.Domain IN ('30','35','40','50')
