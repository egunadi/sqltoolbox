--[B-001709] 
IF EXISTS ( SELECT  *
            FROM    sys.indexes
            WHERE   name = 'PK_CLREMITDCODEPROP'
                    AND OBJECT_NAME(object_id) = 'CLREMITDCODEPROP'
                    AND is_primary_key = 1 )
    AND NOT EXISTS ( SELECT K.TABLE_NAME ,
                            K.COLUMN_NAME ,
                            K.CONSTRAINT_NAME, c.CONSTRAINT_TYPE
                     FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C
                            JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K ON C.TABLE_NAME = K.TABLE_NAME
                                                              AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG
                                                              AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA
                                                              AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
                     WHERE  C.CONSTRAINT_TYPE = 'PRIMARY KEY'
                            AND K.COLUMN_NAME = 'CODE'
							AND K.TABLE_NAME  = 'CLREMITDCODEPROP' )
    BEGIN
        ALTER TABLE dbo.CLREMITDCODEPROP
        DROP CONSTRAINT PK_CLREMITDCODEPROP;
    END 
GO

IF ( SELECT is_nullable 
     FROM   sys.columns 
     WHERE  object_id = object_id('CLREMITDCODEPROP') 
     AND name = 'CODE' ) = 1

  BEGIN    
        UPDATE  CLREMITDCODEPROP
        SET     CODE = ''
        WHERE   CODE IS NULL;

        ALTER TABLE CLREMITDCODEPROP
        ALTER COLUMN CODE VARCHAR(15) NOT NULL;
  END
GO  