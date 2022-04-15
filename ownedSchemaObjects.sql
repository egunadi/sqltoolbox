-- https://ardalis.com/how-to-find-all-objects-in-a-sql-server-schema/
SELECT *
FROM sys.objects WHERE schema_id = SCHEMA_ID('dbo')

-- https://www.mssqltips.com/sqlservertip/2620/steps-to-drop-an-orphan-sql-server-user-when-it-owns-a-schema-or-role/
select * from information_schema.schemata
where schema_owner = 'MADMAX\ayang'

-- https://dba.stackexchange.com/questions/19456/the-database-principal-owns-a-schema-in-the-database-and-cannot-be-dropped-mess/19458
alter authorization
on schema::mi_qm128_cms69v8
to dbo
go
