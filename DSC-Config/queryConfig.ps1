Configuration queryConfig
{
    Import-DscResource -Module nx

    Node  "10.0.7.6"  #Add Thanos Query server name or IP
    
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

        nxFile queryServiceFile
        {
            DestinationPath = "/etc/systemd/system/query.service"
            #Modify Prometheus nodes + Cloud bucket store (--store)
            Contents        = "[Unit]
Description=Thanos Query
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
ExecStart=/bin/thanos query \
     --http-address=0.0.0.0:29090 \
     --grpc-address=localhost:10903 \
     --store=10.0.7.7:10901 \
     --store=10.0.7.5:10901 \
     --store=localhost:10905 \
     --query.replica-label replica
[Install]
WantedBy=multi-user.target
            "   
            Ensure          = "Present"
            Type            = "file"
        }

        nxService queryService
        {
            Name       = "query"
            State      = "running"
            Enabled    = $true
            Controller = "systemd"
            DependsOn  = "[nxFile]queryServiceFile"
        }

    }
}

queryConfig -OutputPath:"C:\temp\queryConfig"
Start-DscConfiguration -Path:"C:\temp\queryConfig" -CimSession $Sess -Wait -Verbose -Force