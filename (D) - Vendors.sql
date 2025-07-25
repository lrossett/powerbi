SELECT 
UPPER(VD.[Supplier])									AS [Vendor Code],
UPPER(VD.[Sort Name])									AS [Vendor Name],
UPPER(VD.[Currency])									AS [Currency],
UPPER(VD.[Cr Terms])									AS [Credit Terms],
CONCAT(UPPER(VD.[Domain]),'_',UPPER(VD.[Supplier]))		AS [Vendor Key],
CONCAT(UPPER(VD.[Supplier]),'-',UPPER(VD.[Sort Name]))	AS [Vendor No & Name],
UPPER(AD.[City])										AS [City],
UPPER(AD.[State])										AS [State],
UPPER(AD.[Country])										AS [Country],
UPPER(AD.[Telephone])									AS [Telephone],
UPPER(VD.[Domain])										AS [Domain],
UPPER(AD.[Tax ID - Federal])							AS [Tax Federal ID]
FROM vd_mstr VD
LEFT JOIN stg_ad_mstr AD ON AD.Domain = VD.Domain AND VD.Supplier = AD.[Address]
	WHERE	
	
	VD.Domain in ('30','35','40','50') 
			AND UPPER(AD.[List Type]) = 'SUPPLIER'
			;
