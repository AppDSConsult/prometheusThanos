Configuration compactConfig
{
    Import-DscResource -Module nx

    Node  "10.0.7.6"  #Add Thanos Compact server name or IP
    
    {
        nxFile bucketDir
        {
            DestinationPath = "/etc/prometheus"    
            Ensure          = "Present"
            Type            = "directory"
        }

        nxFile thanoscompactDataDir
        {
            DestinationPath = "/var/lib/thanos-compact"    
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


        nxFile compactServiceFile
        {
            DestinationPath = "/etc/systemd/system/compact.service"
            SourcePath      =  "https://raw.githubusercontent.com/AppDSConsult/prometheusThanos/master/DSC-Config/Service-Files/compact.service"     
            Ensure          = "Present"
            Type            = "file"
            DependsOn       = "[nxFile]bucketyml"
        }
        
        nxService compactService
        {
            Name       = "compact"
            State      = "running"
            Enabled    = $true
            Controller = "systemd"
            DependsOn  = "[nxFile]compactServiceFile"
        }

    }
}

compactConfig -OutputPath:"C:\temp\compactConfig"
Start-DscConfiguration -Path:"C:\temp\compactConfig" -CimSession $Sess -Wait -Verbose -Force
