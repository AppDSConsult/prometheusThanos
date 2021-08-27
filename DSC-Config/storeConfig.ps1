Configuration storeConfig
{
    Import-DscResource -Module nx

    Node  "10.0.7.6"  #Add Thanos Store server name or IP
    
    {
        nxFile bucketDir
        {
            DestinationPath = "/etc/prometheus"    
            Ensure          = "Present"
            Type            = "directory"
        }
        nxFile thanosstoreDataDir
        {
            DestinationPath = "/var/lib/thanos-store"    
            Ensure          = "Present"
            Type            = "directory"
        }

        $StorageAccountRG = ""  #Add Storage account resource group name
        $StorageAccountName = ""  #Add Storage account name
        $key1 = Get-AzStorageAccountKey -ResourceGroupName $StorageAccountRG -AccountName $StorageAccountName
        $container = ""  #Add container name
        $contents = "type: AZURE
config:
  storage_account: $StorageAccountName
  storage_account_key: $($key1.value[0])
  container: $container
"
        nxFile bucketyml
        {
            Ensure          = "Present"
            Contents        = $contents
            DestinationPath = "/etc/prometheus/bucket.yml"
            Type            = "File"
        }

        nxFile storeServiceFile
        {
            DestinationPath = "/etc/systemd/system/store.service"
            SourcePath      =  "https://raw.githubusercontent.com/AppDSConsult/prometheusThanos/master/DSC-Config/Service-Files/store.service"     
            Ensure          = "Present"
            Type            = "file"
            DependsOn       = "[nxFile]bucketyml"
        }

        nxService storeService
        {
            Name       = "store"
            State      = "running"
            Enabled    = $true
            Controller = "systemd"
            DependsOn  = "[nxFile]storeServiceFile"
        }

    }
}

storeConfig -OutputPath:"C:\temp\storeConfig"
Start-DscConfiguration -Path:"C:\temp\storeConfig" -CimSession $Sess -Wait -Verbose -Force
