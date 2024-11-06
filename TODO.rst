TODO
====
http://localhost:9080/api/doc/p/bos

- [ ] Get-BusinessObject [name,moduleid]
- [ ] Get-BusinessObject [id]
- [ ] Get-BusinessObjectField [name]
- [ ] Get-BusinessObjectField [id]

http://localhost:9080/api/doc/p/cache

- [x] Get-HierarchyTreeCache
- [x] Get-CacheProcessingMode
- [x] Set-CacheProcessingMode [*mode*]
- [x] Invoke-FlushCache [*cache*]

http://localhost:9080/api/doc/p/cleanup

- [ ] Get-CleanupStatus

http://localhost:9080/api/doc/p/dataConnect

.. code:: ps1

    Get-DataConnectJob | Invoke-FailDataConnectJob
    Get-DataConnectJob | Invoke-ReadyDataConnectJob
    Get-DataConnectJob | Invoke-RetryDataConnectJob
    Get-DataConnectJob | Remove-DataConnectJob

- [ ] Remove-DataConnectJob [*ID*]
- [ ] Invoke-FailDataConnectJob [*ID*]
- [ ] Invoke-ReadyDataConnectJob [*ID*]
- [ ] Invoke-RetryDataConnectJob [*ID*]
- [ ] Get-DataConnectJob [*ID*]
- [ ] Get-DataConnectStagingTable [*-Details*]

http://localhost:9080/api/doc/p/dataBaseInfo

- [x] Get-DatabaseInfo
- [x] Invoke-CleanupWorkflow  POST /api/v1/admin/databaseinfo/task?action=cleanupwf
- [ ] Invoke-DatabaseQuery (Pipe SQL in)

http://localhost:9080/api/doc/p/errorLogManager

- [ ] Get-LogLast
- [ ] Get-LogAll
- [ ] Roll-Log (all or one)

http://localhost:9080/api/doc/p/javaProperties

- [ ] Get-JavaInfo (all or summary)
- [ ] Get-JavaGarbageCollection

http://localhost:9080/api/doc/p/lockedUsers

.. code:: ps1

    Get-LockedUsers | Unlock-LockedUsers

- [ ] Get-LockedUsers
- [ ] Unlock-LockedUsers

http://localhost:9080/api/doc/p/om

Model a create OMP, Add objects, Export, Download process

.. code:: ps1

    New-OmPackage Test | Add-ToOmPackage ... | Export-OmPackage | Download-OmPackage

    Get-OmPackage | Export-OmPackage | Download-OmPackage

- [ ] Add-ToOmPackage (By Name, By ID, All Application Object (various),
- [ ] New-OmPackage (Empty, By Date
- [ ] Download-OmPackage (should wait for the status to change!)
- [ ] Export-OmPackage (by Name, By ID)
- [ ] Get-OmPackage (by Name, By ID)

http://localhost:9080/api/doc/p/performanceMonitor

- [ ] Get-PerformanceValue  (GET /api/v1/admin/performance/kpi)
- [ ] Get-PerformanceValue
- [ ] Get-CachePerformance

http://localhost:9080/api/doc/p/platformLogging

- [x] Write-LogMessage
- [x] Get-PlatformLogging
- [x] Set-PlatformLogging
- [x] Enable-PlatformLogging
- [x] Disable-PlatformLogging
- [x] Reset-PlatformLoggingDuplicates
- [x] Roll-LogCategory

http://localhost:9080/api/doc/p/schedulerManager

- [ ] Get-SchedulerManager
- [ ] Set-SchedulerManager

http://localhost:9080/api/doc/p/SystemInfoController

- [x] Lock-System
- [x] Unlock-System
- [x] Get-Property (-All)
- [x] Set-Property
- [x] Get-ServerXml
- [ ] Get-ThreadManager
- [ ] Set-ThreadManager

http://localhost:9080/api/doc/p/WorkflowAgentInfoController

- [ ] Get-WorkflowScheduledEventUser
- [ ] Set-WorkflowScheduledEventUser
- [ ] Limit-WorkflowMax -Max
- [ ] Limit-WorkflowAgent -User -Group

