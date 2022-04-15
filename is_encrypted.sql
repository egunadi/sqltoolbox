select
    name,
    OBJECTPROPERTY([object_id], 'IsEncrypted') [IsEncrypted]
from sys.procedures
where name like 'ar_mro_bundle%'