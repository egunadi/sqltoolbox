/**************************
Patient Account Merge Check
***************************/
DECLARE @snippeted table (  triggername varchar(128), tablename varchar(128) );

INSERT INTO @snippeted
  SELECT DISTINCT
     o.name AS Object_Name,
     OBJECT_NAME(o.parent_object_id) AS table_name
  FROM sys.sql_modules m
     INNER JOIN
     sys.objects o
     ON m.object_id = o.object_id
  WHERE m.definition Like '%Disregard Patient Merges%'
    and o.type = 'TR';


    -- Tables not accounted for in the merge
    -- Only applies to tables with %ssno% and %account% column names
      select 'Tables not accounted for in the merge', *
      from    sys.columns c
              inner join sys.tables t on c.object_id = t.object_id
      where   ( c.name like '%ssn%'
                or c.name like '%account%'
                or c.name like '%mrn%'
                or c.name like '%acct%'
              )
              and not exists ( select 1
                               from   dbo.MRGVALIDTABLES v
                               where  (t.name = v.tablename
                                      or SCHEMA_NAME(t.schema_id) + '.' + t.name = v.tablename)
                                      and t.[type] = 'U' )
              and not exists ( select 1
                               from   dbo.mrgexclusions e
                               where  (t.name = e.tablename
                                      or SCHEMA_NAME(t.schema_id) + '.' + t.name = e.tablename)
                                      and t.[type] = 'U' )



    -- Triggers not accounted for in the merge
    select 'Triggers not accounted for in the merge', *
    from sys.triggers t
       inner join sys.trigger_events te
        on t.object_id = te.object_id
        and te.type_desc = 'UPDATE'
       inner join dbo.mrgvalidtables m
        on  object_name(parent_id) = m.tablename
    where not exists (select 1
              from dbo.MRGVALIDTRIGGERS v
              where t.name = v.triggername
                and t.[type] = 'TR')
      and not exists (select 1
               from dbo.mrgtriggerexclusions e
               where t.name = e.triggername
                and t.[type] = 'TR')


    -- Excluded Triggers without Snippets in place
    select  'Excluded Triggers without Snippets in place', *
      from    dbo.mrgtriggerexclusions e
      where   not exists (select 1
              from @snippeted s
              where s.triggername = e.triggername
                and s.tablename = e.tablename)


    -- Triggers with Snippets that are not Excluded
    select  'Triggers with Snippets that are not Excluded', *
      from    @snippeted s
      where   not exists (select 1
              from dbo.mrgtriggerexclusions e
              where s.triggername = e.triggername
                and s.tablename = e.tablename)
 



