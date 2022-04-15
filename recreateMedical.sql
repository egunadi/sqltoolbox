EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'medical'
GO
USE [master]
GO
/****** Object:  Database [ChangeLog]    Script Date: 4/20/2020 9:25:33 AM ******/
DROP DATABASE [medical]
GO

-----------
-- syntax: source, target
-- DBCC CLONEDATABASE ('medical', 'medical_bak');
DBCC CLONEDATABASE ('medical_bak', 'medical');

-------------

ALTER DATABASE medical SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [medical] SET READ_WRITE with NO_WAIT  
GO
ALTER DATABASE medical SET MULTI_USER
GO
