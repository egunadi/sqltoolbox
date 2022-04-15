-- =============================
-- Dropping Tables and SPs
-- =============================
SELECT 'DROP TABLE "' + TABLE_NAME + '"'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'mrg%'

--select top 1 * from INFORMATION_SCHEMA.TABLES

-------------
UNION ALL


SELECT 'DROP PROCEDURE "' + Name + '"'
FROM sys.procedures
WHERE Name like 'mrg%'

--select top 1 * from sys.procedures

-------------
/*
http://stackoverflow.com/questions/4393/drop-all-tables-whose-names-begin-with-a-certain-string
http://stackoverflow.com/questions/2446003/drop-group-of-stored-procedures-by-name
*/
