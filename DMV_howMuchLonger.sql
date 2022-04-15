select  T.text, R.Status, R.Command, DatabaseName = db_name(R.database_id)
        , R.cpu_time, R.total_elapsed_time, R.percent_complete, R.estimated_completion_time
from    sys.dm_exec_requests R
        cross apply sys.dm_exec_sql_text(R.sql_handle)  T

-----------


  SELECT txt.*, r.*
  -- SELECT r.session_id, r.estimated_completion_time, r.percent_complete
  FROM sys.dm_exec_requests r
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) txt    -- If we want to see the sql statements that people are executing
  WHERE r.session_id > 50                               -- If you only want to see the users in your system (non-system)
                                                        -- We could also modify the query to exclude the SQL Agent
