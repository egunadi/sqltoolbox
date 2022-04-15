CHECKPOINT;
GO
DBCC DROPCLEANBUFFERS;
GO
DBCC FREEPROCCACHE;
GO


-- Show Time and IO/Processing Information
-- https://littlekendra.com/2016/03/24/3-tricks-with-statistics-io-and-statistics-time-in-sql-server/
SET STATISTICS IO, TIME ON;
GO

--TURN ON EXECUTION PLAN (CTRL+M)

--UPDATE STATISTICS
--EXEC sp_updatestats;
--UPDATE STATISTICS <TABLENAME>;


-- Turn off Time and IO/Processing Information
SET STATISTICS IO, TIME OFF;
GO