
  (SELECT [bp].[bps],
          [bp].[bpd],
          [bp].[VDATE],
          [bp].[MUNIT],
          CAST(bp.[BPS] AS int) [bps],
          CAST(bp.[BPD] AS int) [bpd]
   FROM [dbo].[MUBASEPOPULATION] AS [b] CROSS APPLY
     (SELECT TOP (4000000000) CASE
                                  WHEN STUFF(LTRIM(RTRIM(bps)), 1, 1, '') NOT LIKE '%[^.0123456789]%'
                                       AND LEFT(LTRIM(RTRIM(bps)), 1) LIKE '[-.+0123456789]'
                                       AND bpd LIKE '%.%'
                                       AND bps NOT LIKE '%.%.%' THEN 1
                                  WHEN STUFF(LTRIM(RTRIM(bps)), 1, 1, '') NOT LIKE '%[^0123456789]%'
                                       AND LEFT(LTRIM(RTRIM(bps)), 1) LIKE '[-+0123456789]' THEN 1
                                  ELSE 0
                              END [bpscheck], bps, CASE
                                                       WHEN STUFF(LTRIM(RTRIM(bpd)), 1, 1, '') NOT LIKE '%[^.0123456789]%'
                                                            AND LEFT(LTRIM(RTRIM(bpd)), 1) LIKE '[-.+0123456789]'
                                                            AND bpd LIKE '%.%'
                                                            AND bpd NOT LIKE '%.%.%' THEN 1
                                                       WHEN STUFF(LTRIM(RTRIM(bpd)), 1, 1, '') NOT LIKE '%[^0123456789]%'
                                                            AND LEFT(LTRIM(RTRIM(bpd)), 1) LIKE '[-+0123456789]' THEN 1
                                                       ELSE 0
                                                   END [bpdcheck], bpd, [v].[VDATE], v.[MUNIT]
      FROM clvital AS [v]
      WHERE 1=1
        AND [v].[COMPANY] = [b].[company]
        AND [v].[SSNO] = [b].[ssno]
        AND v.[VDATE] >= '20150101' --@_startdate
AND v.[VDATE] < '20160101' --@_enddate
) [bp]
   WHERE [mureportlogID] = 20181105154330000
     AND bp.[bpscheck] = 1
     AND bp.[bpdcheck] = 1 )