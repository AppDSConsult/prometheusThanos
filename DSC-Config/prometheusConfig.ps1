Configuration prometheusConfig
{
    Import-DscResource -Module nx

    Node  "10.0.7.5"
    {
        nxFile prometheusDataDir
        {
            DestinationPath = "/var/lib/prometheus"    
            Ensure          = "Present"
            Type            = "directory"
        }

        nxFile prometheusDir
        {
            DestinationPath = "/etc/prometheus"    
            Ensure          = "Present"
            Type            = "directory"
        }

        nxFile prometheusTempDir
        {
            DestinationPath = "/tmp/prometheus"    
            Ensure          = "Present"
            Type            = "directory"
        }

        nxFile prometheusDownload
        {
            Ensure          = "Present"
            SourcePath      = "https://github.com/prometheus/prometheus/releases/download/v2.28.1/prometheus-2.28.1.linux-amd64.tar.gz"
            DestinationPath = "/tmp/prometheus/prometheus-2.28.1.linux-amd64.tar.gz"
            Type            = "File"
            Checksum        = "mtime"
        }

        nxArchive prometheusArchive
        {
            SourcePath      = "/tmp/prometheus/prometheus-2.28.1.linux-amd64.tar.gz"
            DestinationPath = "/tmp/prometheus/"
            Force           = $false
            DependsOn       = "[nxFile]prometheusDownload"
            Checksum        = "mtime"
        }

        nxScript promtoolCopy {

            GetScript  = @"
#!/bin/bash
""
"@

            TestScript = @'
#!/bin/bash
file=/usr/local/bin/promtool
if test -f "$file";
then
    exit 0
else
    exit 1
fi
'@

            SetScript  = @"
#!/bin/bash
sudo cp -rp /tmp/prometheus/prometheus-2.28.1.linux-amd64/promtool /usr/local/bin
"@
        }

        nxScript PrometheusCopy {

            GetScript  = @"
#!/bin/bash
""
"@

            TestScript = @'
#!/bin/bash
file=/usr/local/bin/prometheus
if test -f "$file";
then
    exit 0
else
    exit 1
fi
'@

            SetScript  = @"
#!/bin/bash
sudo cp -rp /tmp/prometheus/prometheus-2.28.1.linux-amd64/prometheus /usr/local/bin
"@
        }
        nxFile prometheusYml
        {
            DestinationPath = "/etc/prometheus/prometheus.yml"
            #SourcePath      = "https://raw.githubusercontent.com/audriuz/kplabsdemo/main/prometheus.yml"
            Contents        = "global:
  scrape_interval: 5s
  external_labels:
   cluster: uks-1
   replica: suse15-1
scrape_configs:
  - job_name: 'windows_exporter'
    static_configs:
      - targets: ['10.0.1.6:9182']
"
            Ensure          = "Present"
            Type            = "file"
        }

        nxScript console_librariesCopy {

            GetScript  = @"
#!/bin/bash
""
"@

            TestScript = @'
#!/bin/bash
filecount=`ls /etc/prometheus/console_libraries | wc -l`
if [ $filecount -eq 2 ]
then
    exit 0
else
    exit 1
fi
'@

            SetScript  = @"
#!/bin/bash
sudo cp -r /tmp/prometheus/prometheus-2.28.1.linux-amd64/console_libraries /etc/prometheus
"@
        }
        nxScript consolesCopy {

            GetScript  = @"
#!/bin/bash
""
"@

            TestScript = @'
#!/bin/bash
filecount=`ls /etc/prometheus/consoles | wc -l`
if [ $filecount -eq 7 ]
then
    exit 0
else
    exit 1
fi
'@

            SetScript  = @"
#!/bin/bash
sudo cp -r /tmp/prometheus/prometheus-2.28.1.linux-amd64/consoles /etc/prometheus
"@
        }

        nxFile prometheusServiceFile
        {
            DestinationPath = "/etc/systemd/system/prometheus.service"
            SourcePath      =  "https://raw.githubusercontent.com/audriuz/Prometheus-Thanos-Setup/main/DSC-Config/Service-Files/prometheus.service"    
            Ensure          = "Present"
            Type            = "file"
        }

        nxService prometheusService
        {
            Name       = "prometheus"
            State      = "running"
            Enabled    = $true
            Controller = "systemd"
            DependsOn  = "[nxFile]prometheusServiceFile"
        }



    }
}

prometheusConfig -OutputPath:"C:\temp\prometheusConfig"
Start-DscConfiguration -Path:"C:\temp\prometheusConfig" -CimSession $Sess -Wait -Verbose -Force