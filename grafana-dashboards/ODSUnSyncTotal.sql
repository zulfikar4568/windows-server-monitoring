select 
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreInserts1)
  +
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreInserts1Master)
  +
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreInserts2)
  +
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreInserts2Master)
  +
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreUpdates)
  +
  (select COUNT(*) from ExCoreOLTP.ExCoreOLTPSchema.DataStoreUpdatesMaster)