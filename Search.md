# Search Text in SP or Trigger in SQL Server

I want to search a text from my all database stored procedures. I use the below SQL:

```
SELECT DISTINCT 
       o.name AS Object_Name,
       o.type_desc
  FROM sys.sql_modules m 
       INNER JOIN 
       sys.objects o 
         ON m.object_id = o.object_id
 WHERE m.definition Like '%[ABD]%';
```

I want to search for [ABD] in all stored procedures including square brackets but its not giving proper result. Please tell me how I can change my query to achieve this.
sql sql-server sql-server-2008 stored-procedures system-stored-procedures
shareimprove this question
	
We can also search within syscomments like such:

```
select * from syscomments where text like '%[ABD]%'
```

Escape the square brackets:

```
...
WHERE m.definition Like '%\[ABD\]%' ESCAPE '\'
```

Then the square brackets will be treated as a string literals not as wild cards.

<http://stackoverflow.com/questions/14704105/search-text-in-stored-procedure-in-sql-server>


To add a filter to the object name:

```
SELECT DISTINCT 
       o.name AS Object_Name,
       o.type_desc
  FROM sys.sql_modules m 
       INNER JOIN 
       sys.objects o 
         ON m.object_id = o.object_id
 WHERE m.definition Like '%address%'
 and o.name like 'hdl_%';
 ```

# Find a string by searching all tables in SQL Server Management Studio 2008

```
CREATE PROC SearchAllTables
(
    @SearchStr nvarchar(100)
)
AS
BEGIN

    CREATE TABLE #Results (ColumnName nvarchar(370), ColumnValue nvarchar(3630))

    SET NOCOUNT ON

    DECLARE @TableName nvarchar(256), @ColumnName nvarchar(128), @SearchStr2 nvarchar(110)
    SET  @TableName = ''
    SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

    WHILE @TableName IS NOT NULL

    BEGIN
        SET @ColumnName = ''
        SET @TableName = 
        (
            SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
            FROM     INFORMATION_SCHEMA.TABLES
            WHERE         TABLE_TYPE = 'BASE TABLE'
                AND    QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
                AND    OBJECTPROPERTY(
                        OBJECT_ID(
                            QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                             ), 'IsMSShipped'
                               ) = 0
        )

        WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)

        BEGIN
            SET @ColumnName =
            (
                SELECT MIN(QUOTENAME(COLUMN_NAME))
                FROM     INFORMATION_SCHEMA.COLUMNS
                WHERE         TABLE_SCHEMA    = PARSENAME(@TableName, 2)
                    AND    TABLE_NAME    = PARSENAME(@TableName, 1)
                    AND    DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar', 'int', 'decimal')
                    AND    QUOTENAME(COLUMN_NAME) > @ColumnName
            )

            IF @ColumnName IS NOT NULL

            BEGIN
                INSERT INTO #Results
                EXEC
                (
                    'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) 
                    FROM ' + @TableName + ' (NOLOCK) ' +
                    ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                )
            END
        END    
    END

    SELECT ColumnName, ColumnValue FROM #Results
END
```

## FOR SQL SERVER 2012:

```
CREATE PROC SearchAllTables
(
@SearchStr nvarchar(100)
)
AS
BEGIN

    CREATE TABLE #Results (ColumnName nvarchar(370), ColumnValue nvarchar(3630))

    SET NOCOUNT ON

    DECLARE @TableName nvarchar(256), @ColumnName nvarchar(128), @SearchStr2 nvarchar(110)
    SET  @TableName = ''
    SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%','''')

    WHILE @TableName IS NOT NULL

    BEGIN
        SET @ColumnName = ''
        SET @TableName = 
        (
            SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
            FROM     INFORMATION_SCHEMA.TABLES
            WHERE         TABLE_TYPE = 'BASE TABLE'
                AND    QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
                AND    OBJECTPROPERTY(
                        OBJECT_ID(
                            QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                             ), 'IsMSShipped'
                               ) = 0
        )

        WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)

        BEGIN
            SET @ColumnName =
            (
                SELECT MIN(QUOTENAME(COLUMN_NAME))
                FROM     INFORMATION_SCHEMA.COLUMNS
                WHERE         TABLE_SCHEMA    = PARSENAME(@TableName, 2)
                    AND    TABLE_NAME    = PARSENAME(@TableName, 1)
                    AND    DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar', 'int', 'decimal')
                    AND    QUOTENAME(COLUMN_NAME) > @ColumnName
            )

            IF @ColumnName IS NOT NULL

            BEGIN
                INSERT INTO #Results
                EXEC
                (
                    'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) 
                    FROM ' + @TableName + 'WITH (NOLOCK) ' +
                    ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
                )
            END
        END    
    END

    SELECT ColumnName, ColumnValue FROM #Results
END
```

<http://stackoverflow.com/questions/15757263/find-a-string-by-searching-all-tables-in-sql-server-management-studio-2008>


# How to find all SQL Agent Jobs that call a given stored-proc

```
SELECT
    [sJOB].[job_id] AS [JobID]
    , [sJOB].[name] AS [JobName]
    , [sJSTP].[step_uid] AS [StepID]
    , [sJSTP].[step_id] AS [StepNo]
    , [sJSTP].[step_name] AS [StepName]
    , CASE [sJSTP].[subsystem]
        WHEN 'ActiveScripting' THEN 'ActiveX Script'
        WHEN 'CmdExec' THEN 'Operating system (CmdExec)'
        WHEN 'PowerShell' THEN 'PowerShell'
        WHEN 'Distribution' THEN 'Replication Distributor'
        WHEN 'Merge' THEN 'Replication Merge'
        WHEN 'QueueReader' THEN 'Replication Queue Reader'
        WHEN 'Snapshot' THEN 'Replication Snapshot'
        WHEN 'LogReader' THEN 'Replication Transaction-Log Reader'
        WHEN 'ANALYSISCOMMAND' THEN 'SQL Server Analysis Services Command'
        WHEN 'ANALYSISQUERY' THEN 'SQL Server Analysis Services Query'
        WHEN 'SSIS' THEN 'SQL Server Integration Services Package'
        WHEN 'TSQL' THEN 'Transact-SQL script (T-SQL)'
        ELSE sJSTP.subsystem
      END AS [StepType]
    , [sPROX].[name] AS [RunAs]
    , [sJSTP].[database_name] AS [Database]
    , [sJSTP].[command] AS [ExecutableCommand]
    , CASE [sJSTP].[on_success_action]
        WHEN 1 THEN 'Quit the job reporting success'
        WHEN 2 THEN 'Quit the job reporting failure'
        WHEN 3 THEN 'Go to the next step'
        WHEN 4 THEN 'Go to Step: ' 
                    + QUOTENAME(CAST([sJSTP].[on_success_step_id] AS VARCHAR(3))) 
                    + ' ' 
                    + [sOSSTP].[step_name]
      END AS [OnSuccessAction]
    , [sJSTP].[retry_attempts] AS [RetryAttempts]
    , [sJSTP].[retry_interval] AS [RetryInterval (Minutes)]
    , CASE [sJSTP].[on_fail_action]
        WHEN 1 THEN 'Quit the job reporting success'
        WHEN 2 THEN 'Quit the job reporting failure'
        WHEN 3 THEN 'Go to the next step'
        WHEN 4 THEN 'Go to Step: ' 
                    + QUOTENAME(CAST([sJSTP].[on_fail_step_id] AS VARCHAR(3))) 
                    + ' ' 
                    + [sOFSTP].[step_name]
      END AS [OnFailureAction]
FROM
    [msdb].[dbo].[sysjobsteps] AS [sJSTP]
    INNER JOIN [msdb].[dbo].[sysjobs] AS [sJOB]
        ON [sJSTP].[job_id] = [sJOB].[job_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOSSTP]
        ON [sJSTP].[job_id] = [sOSSTP].[job_id]
        AND [sJSTP].[on_success_step_id] = [sOSSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sOFSTP]
        ON [sJSTP].[job_id] = [sOFSTP].[job_id]
        AND [sJSTP].[on_fail_step_id] = [sOFSTP].[step_id]
    LEFT JOIN [msdb].[dbo].[sysproxies] AS [sPROX]
        ON [sJSTP].[proxy_id] = [sPROX].[proxy_id]
WHERE [sJSTP].[command] LIKE '%MyStoredProc%'
ORDER BY [JobName], [StepNo]
```

<https://stackoverflow.com/questions/18105547/how-to-find-all-sql-agent-jobs-that-call-a-given-stored-proc>
