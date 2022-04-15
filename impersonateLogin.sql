    SELECT SUSER_SNAME() AS CurrentLogin
    , ORIGINAL_LOGIN() AS OrigLogin
    , USER_NAME() AS Usr
    , CASE IS_SRVROLEMEMBER('sysadmin')
        WHEN 1 THEN 'Yes' ELSE 'No' END AS [Sysadmin?]

    EXECUTE AS Login='Scott'
    REVERT