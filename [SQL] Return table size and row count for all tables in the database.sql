SELECT [Table Name], (SELECT rows FROM sysindexes s WHERE s.indid < 2 AND s.id = OBJECT_ID(a.[Table Name])) AS [Row count], [Total space used (MB)] FROM
	(
	SELECT	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)) AS [Table Name],
		CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(i.reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [Total space used (MB)]
	FROM	sysindexes i (NOLOCK)
			INNER JOIN
		sysobjects o (NOLOCK)
			ON
		i.id = o.id AND
		((  o.type IN ('U', 'S')) OR o.type = 'U') AND
		( (OBJECTPROPERTY(i.id, 'IsMSShipped') = 0))
	WHERE	indid IN (0, 1, 255)
	GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id))

	) as a
ORDER BY	[Total space used (MB)] DESC
go

---------- same as above but shows when table was last updated ---------------

SELECT a.[Table Name], (SELECT rows FROM sysindexes s WHERE s.indid < 2 AND s.id = OBJECT_ID(a.[Table Name])) AS [Row count], [Total space used (MB)], [Last Update] FROM
	(
	SELECT	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)) AS [Table Name],
		CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(i.reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [Total space used (MB)]
	FROM	sysindexes i (NOLOCK)
			INNER JOIN
		sysobjects o (NOLOCK)
			ON
		i.id = o.id AND
		((  o.type IN ('U', 'S')) OR o.type = 'U') AND
		( (OBJECTPROPERTY(i.id, 'IsMSShipped') = 0))
	WHERE	indid IN (0, 1, 255)
	GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id))

	) as a
LEFT JOIN
	(
	SELECT QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(u.object_id)) AS [Table Name], MAX(u.last_user_update) [Last Update]
	FROM sys.dm_db_index_usage_stats u (NOLOCK)
		INNER JOIN
		sysobjects o (NOLOCK)
			ON
		u.object_id = o.id AND
		((  o.type IN ('U', 'S')) OR o.type = 'U')
	WHERE u.database_id = DB_ID()
	AND u.last_user_update IS NOT NULL
	GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(u.object_id))

	) as b
ON a.[Table Name] = b.[Table Name]
ORDER BY	[Total space used (MB)] DESC
go


---------- same as above, but uses sys.tables (which seems to work better) instead of sys.dm_db_index_usage_stats --------------
SELECT a.[Table Name], (SELECT rows FROM sysindexes s WHERE s.indid < 2 AND s.id = OBJECT_ID(a.[Table Name])) AS [Row count], [Total space used (MB)], [Last Update] FROM
	(
	SELECT	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id)) AS [Table Name],
		CONVERT(numeric(15,2),(((CONVERT(numeric(15,2),SUM(i.reserved)) * (SELECT low FROM master.dbo.spt_values (NOLOCK) WHERE number = 1 AND type = 'E')) / 1024.)/1024.)) AS [Total space used (MB)]
	FROM	sysindexes i (NOLOCK)
			INNER JOIN
		sysobjects o (NOLOCK)
			ON
		i.id = o.id AND
		((  o.type IN ('U', 'S')) OR o.type = 'U') AND
		( (OBJECTPROPERTY(i.id, 'IsMSShipped') = 0))
	WHERE	indid IN (0, 1, 255)
	GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(i.id))

	) as a
INNER JOIN
	(
	SELECT QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(u.object_id)) AS [Table Name], MAX(u.modify_date) [Last Update]
	FROM sys.tables u (NOLOCK)
		INNER JOIN
		sysobjects o (NOLOCK)
			ON
		u.object_id = o.id AND
		((  o.type IN ('U', 'S')) OR o.type = 'U')
	GROUP BY	QUOTENAME(USER_NAME(o.uid)) + '.' + QUOTENAME(OBJECT_NAME(u.object_id))

	) as b
ON a.[Table Name] = b.[Table Name]
ORDER BY	[Total space used (MB)] DESC
go


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


-----------EXEC sp_spaceused

-- TEMP TABLES FOR ANALYSIS
CREATE TABLE #tTables (sName NVARCHAR(MAX), iRows BIGINT, iReservedKB BIGINT, iDataKB BIGINT, iIndexKB BIGINT, iUnusedKB BIGINT)
CREATE TABLE #tTmp (sName NVARCHAR(MAX), iRows BIGINT, sReservedKB NVARCHAR(MAX), sDataKB NVARCHAR(MAX), sIndexKB NVARCHAR(MAX), sUnusedKB NVARCHAR(MAX))
-- COLLECT SPACE USE PER TABLE
EXEC sp_msforeachtable 'INSERT #tTmp EXEC sp_spaceused [?];'
-- CONVERT NUMBER-AS-TEXT COLUMNS TO NUMBER TYPES FOR EASIER ANALYSIS
INSERT #tTables SELECT sName, iRows
                     , CAST(REPLACE(sReservedKB, ' KB', '') AS BIGINT)
                     , CAST(REPLACE(sDataKB    , ' KB', '') AS BIGINT)
                     , CAST(REPLACE(sIndexKB   , ' KB', '') AS BIGINT)
                     , CAST(REPLACE(sUnusedKB  , ' KB', '') AS BIGINT)
                FROM #tTmp
DROP TABLE #tTmp
-- DO SOME ANALYSIS
SELECT sName='TOTALS', iRows=SUM(iRows), iReservedKB=SUM(iReservedKB), iDataKB=SUM(iDataKB),  iIndexKB=SUM(iIndexKB), iUnusedKB=SUM(iUnusedKB) FROM #tTables ORDER BY sName
SELECT * FROM #tTables ORDER BY iReservedKB DESC
-- CLEAN UP
DROP TABLE #tTables



--------------Size of MDF from GUI-----------

SELECT db.name AS [Logical Name],
CASE WHEN db.[type] = 0 THEN 'Rows Data'
     ELSE 'Log' END AS [File Type],
(db.size*8)/1024 AS initialSize
FROM sys.database_files db


--https://www.sqlservercentral.com/Forums/Topic1440652-392-1.aspx