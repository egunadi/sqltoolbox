SELECT 
Technician__c,
SUM(Work_Time_Entry__c)
FROM Case_Work_Tracking__c 
WHERE Date_Work_Performed__c >= LAST_N_MONTHS:6
  AND Date_Work_Performed__c < 2023-02-04
  AND Technician__c NOT IN (
    '005d0000000f9NUAAY',
    '0050V000007Mk5tQAC',
    '005d0000000f9L4AAI',
    '005d0000000gK7uAAE',
    '0050V000005lJHPQA2',
    '005d0000001Oxm0AAC',
    '0053w000008EUWmAAO',
    '0053w000008jycIAAQ',
    '005d0000000f9KHAAY'
  )
GROUP BY Technician__c