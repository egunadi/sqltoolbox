/*
Look at error logs to pinpoint when the corruption happened

Disconnect all MI users

Stop Net services

Back-up the DB!

Stop SQL Agent (in case something creeps up)

See Palmetto, SBG, and AlvarezThull Cases 00163814, 00168252, & 00168494 for reference
*/

sp_who -- to see who is connected

USE [medical];
GO

ALTER DATABASE [medical] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- run this right away in case another user connects to the single_user [medical]
-- may have to run multiple times
DBCC CHECKDB('medical', REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS; 
GO

--OR
DBCC CHECKTABLE ('dbo.zGEMMSLog', REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS, ALL_ERRORMSGS;  
GO    

/*
if running multiple times doesn't fix, try recreating the corrupted table(s) 
if possible, back-up, script-out, and export as csv the table before doing this
  test first using a test table

if there are other (unknown) corrupted tables, generate a list of 
  dbcc checktable(+ tablename +) with tablock
commands and find out which tables error out
  may be able to do this with exec sp_msforeachtable 'dbcc checktable([?]) with tablock'

if there aren't too many additional tables, try fixing them before re-running REPAIR_ALLOW_DATA_LOSS

for additional info, can also generate a list of
  dbcc checkalloc(+ tablename +) with tablock
commands
*/

--check results
DBCC CHECKTABLE ('dbo.zGEMMSLog');  
GO   

--OR
-- do not run if time is a concern, use CHECKTABLE instead
DBCC CHECKDB('medical') WITH NO_INFOMSGS, ALL_ERRORMSGS;
GO

ALTER DATABASE [medical] SET MULTI_USER;
GO

/*
afterwards, start SQL Agent and Net Services

take a fresh backup of [medical] and screenshot success message from SQL Agent

before taking the backup, check the log file to see if it needs to be shrinked beforehand
*/

USE [Medical]
GO
DBCC SHRINKFILE (N'medical_log' , 1024)
GO

-- https://www.sqlskills.com/blogs/paul/backup-log-with-no_log-use-abuse-and-undocumented-trace-flags-to-stop-it/
SELECT log_reuse_wait_desc FROM sys.databases WHERE NAME = 'medical';
GO

-- https://www.sqlservercentral.com/forums/topic/log_reuse_wait_desc-replication-but-theres-no-replication
EXEC sp_removedbreplication 'medical'
