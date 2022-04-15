
--<<<<<<<<<<----------------------------------------------------------------->>>>>>>>>>--
--5. real-time blockers
    --Report Blocker and Waiter SQL Statements
    --http://www.microsoft.com/technet/scriptcenter/scripts/sql/sql2005/trans/sql05vb044.mspx?mfr=true
    -- SQLCAT BPT
SELECT 
    t1.resource_type as lock_type
  , db_name(resource_database_id) as DB
  , t1.resource_associated_entity_id as blkd_obj
  , t1.request_mode as lock_req          -- lock requested
  , t1.request_session_id as waiter_sid-- spid of waiter
  , t2.wait_duration_ms as waittime
  , (SELECT text FROM sys.dm_exec_requests as r  --- get sql for waiter
        CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) 
            WHERE r.session_id = t1.request_session_id) as waiter_batch
  , (SELECT SUBSTRING(qt.text , r.statement_start_offset/2
          , (CASE WHEN r.statement_end_offset = -1 
                THEN LEN(CONVERT(nvarchar(MAX), qt.text)) * 2 
                ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
        FROM sys.dm_exec_requests as r
            CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) as qt
            WHERE r.session_id = t1.request_session_id) as waiter_stmt    --- this is the statement executing right now
   , t2.blocking_session_id as blocker_sid -- spid of blocker
   , (SELECT text FROM sys.sysprocesses as p       --- get sql for blocker
            CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) 
            WHERE p.spid = t2.blocking_session_id) as blocker_stmt
FROM sys.dm_tran_locks as t1 
    JOIN sys.dm_os_waiting_tasks as t2 
        ON t1.lock_owner_address = t2.resource_address
        
-- Misc queries:
-- INSERT, UPDATE, DELETE - require/acquire "Exclusive" (X)
--		Cannot be viewed by other users

-- SELECT require/acquire "Shared" (S)
--		Can be shared by all readers

-- "Readers block writers; 
-- writers block readers"

BEGIN TRAN
	UPDATE Person.Person	
		SET FirstName = 'Scott'
		WHERE BusinessEntityID = 100
		
sp_lock
		
SELECT @@TRANCOUNT

SELECT * FROM sys.dm_tran_active_transactions

SELECT * FROM sys.dm_tran_current_transaction

SELECT * FROM sys.dm_tran_database_transactions

SELECT txt.*, l.* , r.*
FROM sys.dm_tran_locks l
JOIN sys.dm_exec_requests r
	ON r.session_id = l.request_session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) txt
WHERE request_session_id = @@SPID


