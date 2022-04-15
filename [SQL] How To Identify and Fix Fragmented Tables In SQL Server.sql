/*
   Identify and defrag fragmented tables in sql 2008+
   
   This replaces the following dbcc commands:
   DBCC SHOWCONTIG(TABLE) 
   DBCC DBREINDEX([TABLE])

   See these links for more information:
   http://msdn.microsoft.com/en-us/library/ms188917.aspx (sys.dm_db_index_physical_stats)

   http://msdn.microsoft.com/en-us/library/ms188388.aspx (alter index)

note that the syntax "with(online=on)" may need to be removed if run on an edition of sql server other than developer or enterprise

*/

SELECT  dbschemas.[name] AS 'Schema' ,
        dbtables.[name] AS 'Table' ,
        dbindexes.[name] AS 'Index' ,
        indexstats.avg_fragmentation_in_percent ,
        indexstats.page_count ,
        'alter index [' + dbindexes.[name] + '] on [' + dbtables.[name]
        + '] rebuild with (online = on);'
FROM    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
        INNER JOIN sys.tables dbtables ON dbtables.[object_id] = indexstats.[object_id]
        INNER JOIN sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
        INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
                                               AND indexstats.index_id = dbindexes.index_id
WHERE   indexstats.database_id = DB_ID()
        AND indexstats.avg_fragmentation_in_percent > 30.
        AND indexstats.page_count > 50
        AND dbindexes.[name] IS NOT NULL
ORDER BY indexstats.avg_fragmentation_in_percent DESC; 
GO 

--2) rebuild a specfic index on an index returned by the query above:
alter index THEINDEXNAME on THETABLENAME rebuild
go
 
--3) rebuild all indexes on a table
alter index ALL on THETABLENAME rebuild




-- per SY's intro to querying the mi medical db


--1) get a list of fragmented indexes on a specific table (CLDOCS, in this example)
declare 
   @dbid int, 
   @objId int 

select 
   @dbid  = DB_ID('MEDICAL'), 
   @objId = OBJECT_ID('CLDOCS') 

-- return the indexes on cldocs with >20% fragmentation 
SELECT 
   b.name AS IndexName, 
   a.avg_fragmentation_in_percent AS PercentFragment, 
   a.fragment_count AS TotalFrags, 
   a.avg_fragment_size_in_pages AS PagesPerFrag, 
   a.page_count AS NumPages 
FROM sys.dm_db_index_physical_stats(@dbid,@objid, NULL, NULL , 'DETAILED') AS a 
   JOIN sys.indexes AS b 
      ON a.object_id = b.object_id 
         AND a.index_id = b.index_id 
WHERE a.avg_fragmentation_in_percent > 20 
ORDER BY IndexName 
go 

--2) rebuild a specfic index on cldocs 
alter index DOCS_ACCOUNT on CLDOCS rebuild 
go 

--3) rebuild all indexes on cldocs (CAUTION, THIS CAN BE SLOW) 
alter index ALL on CLDOCS rebuild 
go 


