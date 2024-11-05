TODO
====

- [ ] Get-BusinessObject [name,moduleid]
- [ ] Get-BusinessObject [id]
- [ ] Get-BusinessObjectField [name]
- [ ] Get-BusinessObjectField [id]

- [ ] Get-HierarchyTreeCache
- [ ] Get-CacheProcessingMode
- [ ] Set-CacheProcessingMode [*mode*]
- [ ] Invoke-FlushCache [*cache*]

- [ ] Get-CleanupStatus

- [ ] Delete-DataConnectJob [*ID*]
- [ ] Invoke-FailDataConnectJob [*ID*]
- [ ] Invoke-ReadyDataConnectJob [*ID*]
- [ ] Invoke-RetryDataConnectJob [*ID*]
- [ ] Get-DataConnectJob [*ID*]
- [ ] Get-DataConnectStagingTable [*-Details*]

- [ ] Get-DatabaseInfo
- [ ] Invoke-CleanupWorkflow  POST /api/v1/admin/databaseinfo/task?action=cleanupwf
- [ ] Invoke-DatabaseQuery (Pipe SQL in)

- [ ] Get-LogLast
- [ ] Get-LogAll
- [ ] Roll-Log (all or one)

- [ ] Get-JavaInfo (all or summary)
- [ ] Get-JavaGarbageCollection

- [ ] Get-LockedUsers
- [ ] Unlock-User

- [ ] Get-Navigation
- Model a create OMP, Add objects, Export, Download process
- [ ] Add-ToObjectMigrationPackage (By Name, By ID, All Application Object (various),
- [ ] New-ObjectMigrationPackage (Empty, By Date
- [ ] Download-ObjectMigrationPackage
- [ ] Export-ObjectMigrationPackage (by Name, By ID)
- [ ] Get-ObjectMigrationPackage (by Name, By ID)

- [ ] Get-PerformanceValue  (GET /api/v1/admin/performance/kpi)
- [ ] Get-PerformanceValue
- [ ] Get-CachePerformance

- [x] Write-LogMessage
- [x] Get-PlatformLogging
- [x] Set-PlatformLogging
- [x] Enable-PlatformLogging
- [x] Disable-PlatformLogging
- [x] Reset-PlatformLoggingDuplicates
- [x] Roll-LogCategory
- 

- [ ] Get-Record
- [ ] Get-RecordPortalLink ?

- [ ] Get-Report (name or id)

- [ ] Get-SchedulerManager
- [ ] Set-SchedulerManager

- [ ] Lock-System
- [ ] Unlock-System

- [x] Get-Property (-All)
- [x] Set-Property

- [ ] Get-ServerXml

- [ ] Get-ThreadManager
- [ ] Set-ThreadManager

# There is api give a workflow aget to a specific user
