SELECT name FROM sys.procedures
WHERE OBJECTPROPERTY([object_id], 'IsEncrypted') = 1;


--for userdefined functions:
--https://blog.sqlauthority.com/2008/02/02/sql-server-find-all-the-user-defined-functions-udf-in-a-database/
SELECT name AS function_name
,SCHEMA_NAME(schema_id) AS schema_name
,type_desc
,object_id
FROM sys.objects
WHERE type_desc LIKE '%FUNCTION%'
and OBJECTPROPERTY([object_id], 'IsEncrypted') = 1
order by function_name;