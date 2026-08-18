@echo off
SqlPackage /Action:Publish ^
  /SourceFile:"bin\Debug\ShopNStopDB.dacpac" ^
  /TargetServerName:"localhost\SQLEXPRESS01" ^
  /TargetDatabaseName:"ShopNShop_db" ^
  /TargetTrustServerCertificate:True ^
  /p:BlockOnPossibleDataLoss=false
