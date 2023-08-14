SELECT 
  CASE
    WHEN Value = 'N' THEN 1
    WHEN Value = 'Y' THEN 0
  END
    FROM ExCoreODS.ExCoreODSSchema.DataStoreSetup WHERE Parameter='DATASTORE_TERMINATE'