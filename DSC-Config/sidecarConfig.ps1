Configuration sidecarConfig
{
    Import-DscResource -Module nx

    Node  "10.0.7.5"  #Add Thanos Sidecar server name or IP
    
    {
        nxFile tempThanosDir
        {
            DestinationPath = "/tmp/thanos"    
            Ensure          = "Present"
            Type            = "directory"
        }

        nxFile downloadThanos
        {
            Ensure          = "Present"
            SourcePath      = "https://github.com/thanos-io/thanos/releases/download/v0.22.0/thanos-0.22.0.linux-amd64.tar.gz"
            DestinationPath = "/tmp/thanos/thanos-0.22.0.linux-amd64.tar.gz"
            Type            = "File"
            Checksum        = "mtime"        
        }

        nxArchive thanosarchive
        {
            SourcePath      = "/tmp/thanos/thanos-0.22.0.linux-amd64.tar.gz"
            DestinationPath = "/tmp/thanos/"
            Force           = $false
            DependsOn       = "[nxFile]downloadThanos"
            Checksum        = "mtime"
        }

        nxScript cpthanos {

            GetScript  = @"
#!/bin/bash
""
"@

            TestScript = @'
#!/bin/bash
file=/bin/thanos
if test -f "$file";
then
    exit 0
else
    exit 1
fi
'@

            SetScript  = @"
#!/bin/bash
sudo cp -rp /tmp/thanos/thanos-0.22.0.linux-amd64/thanos /bin
"@
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
        
        nxFile sidecarServiceFile
        {
            DestinationPath = "/etc/systemd/system/sidecar.service"
            SourcePath      =  "https://raw.githubusercontent.com/AppDSConsult/prometheusThanos/master/DSC-Config/Service-Files/sidecar.service"     
            Ensure          = "Present"
            Type            = "file"
            DependsOn       = "[nxFile]bucketyml"
        }

        nxService sidecarService
        {
            Name       = "sidecar"
            State      = "running"
            Enabled    = $true
            Controller = "systemd"
            DependsOn  = "[nxFile]sidecarServiceFile"
        }
    }
}

sidecarConfig -OutputPath:"C:\temp\sidecarConfig"
Start-DscConfiguration -Path:"C:\temp\sidecarConfig" -CimSession $Sess -Wait -Verbose -Force