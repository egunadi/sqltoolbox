
SELECT txt.text, r.session_id, r.status, r.percent_complete, r.estimated_completion_time, r.total_elapsed_time, r.wait_type, r.wait_resource
  FROM sys.dm_exec_requests r
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) txt  
  WHERE r.session_id > 50                            
 
