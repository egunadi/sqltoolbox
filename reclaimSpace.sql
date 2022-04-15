
/*

Added the [tr_cdsRsnRequests_cleanup] trigger and created the "Scrub cdsRsnRequests" SQL job, which is scheduled to run regularly.  Will be monitoring the job in the coming week(s) to ensure it works as intended.

See Cases 00133300 & 00137401 as reference

After reclaiming space, be sure to fire off Index Rebuild job

Do this after hours!

*/
--------------


USE [medical]
GO
DBCC SHRINKDATABASE(N'medical', 10, TRUNCATEONLY)


-- TSQL obtained using Maintenance Plan wizard




--Some other test scripts:

			;with cte_rowDups as (
				select 	row_number() over (partition by company, account, processState, DATEADD(dd, 0, DATEDIFF(dd, 0, createdatetime)) order by lastupdated desc) as GroupID,
						createdatetime,
						lastUpdated,
						company, 
						account, 
						processState
				from cdsrsnrequests
			)
 
			select COUNT(*)
			from cte_rowDups
			where groupid <> 1;












------------------------------------

--https://dba.stackexchange.com/questions/48462/database-size-mdf-too-large



SELECT o.name
     , SUM(ps.reserved_page_count)/128.0 AS ReservedMB
     , SUM(ps.used_page_count)/128.0 AS UsedMB
     , SUM(ps.reserved_page_count-ps.used_page_count)/128.0 AS DiffMB
FROM sys.objects o
JOIN sys.dm_db_partition_stats ps ON o.object_id = ps.object_id
WHERE OBJECTPROPERTYEX(o.object_id, 'IsMSShipped') = 0
GROUP BY o.name
ORDER BY SUM(ps.reserved_page_count) DESC



--------------Size of MDF from GUI-----------

SELECT db.name AS [Logical Name],
CASE WHEN db.[type] = 0 THEN 'Rows Data'
     ELSE 'Log' END AS [File Type],
(db.size*8)/1024 AS initialSize
FROM sys.database_files db


--https://www.sqlservercentral.com/Forums/Topic1440652-392-1.aspx