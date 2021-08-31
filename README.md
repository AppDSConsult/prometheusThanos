# prometheusThanos
*Use Terraform code in the Terraform-VM-build folder if you want to use "Infrastructure as Code" approach to build Azure Linux VMs:*

**variables.tf** - modify variables.tf to match Azure infrastructure and required VM's details. Add subscription_id, client_id, client_secret and tenant_id sensitive variables for Azure Servive Principal with sufficient permissions to create Azure resources.

**main.tf** - Linux VM build terraform code. Existing version assumes that virtual network is created already and NSG not used, but it can be modified easily. Powershell, OMI and DSC are being installed as well, using Azure VM extension.

**script.sh** - script to install Powershell, Open Management Infrastructure (OMI) and Powershell DSC. Modify accordingly to adapt required Linux version or package updates.


*Use Powershell DSC scripts in the DSC-Config folder to set up Prometheus and Thanos components on the Linux VMs:*

**Initiate-Session.ps1** - Configuration documents (MOF files) can be pushed to the Linux computer using the Start-DscConfiguration cmdlet. In order to use this cmdlet, along with the Get-DscConfiguration, or Test-DscConfiguration cmdlets, remotely to a Linux computer, you must use a CIMSession. The New-CimSession cmdlet is used to create a CIMSession to the Linux computer. IMPORTANT - For "Push" mode, the user credential must be the root user on the Linux computer.

**prometheusConfig.ps1** - creates Prometheus server on Linux VM. Should be configured on same server together with Thanos Sidecar. Pay attention to "nxFile prometheusYml" DSC resource - contents must be modified depending on monitored VMs or instances exporter information. Cluster and replica can be modified to anything you want, but each Prometheus cluster node (replica) must have different name to distinguish those server in the Thanos console. Make sure required Prometheus exporters are installed to monitored VMs. Here we monitor specific windows metrics with windows_exporter https://github.com/prometheus-community/windows_exporter . Prometheus.service file contents are being downloaded from Github as file is not being modified often. 

**sidecarConfig.ps1** - installs and configures Thanos Sidecar component on Linux VM. Should be configured on same server together with Prometheus. Same as on other config scripts, adjust package versions if newer is realeased. Make sure you're connected to Azure subscription via terminal, as existing Storage account details are required to create bucket.yml config file that contains Azure object store configuration for uploading TSDB blocks to. Sidecar.service file contents are being downloaded from Github as file is not being modified often.

**queryConfig.ps1** - installs and configures Thanos Query component on Linux VM. Can be created on same or different server as Prometheus/Thanos components. Query.service file contents must be adjusted manualy to match each Prometheus + sidecar server node as a store. When Thanos Store (Store Gateway) component is used, additional store should be added to match Thanos Store server name/IP, so metrics from Azure bucket could be queried (--store=localhost:10905 \ - line 74 in the existing code). 

**storeConfig.ps1** - installs and configures Thanos Store component on Linux VM. Can be created on same or different server as Prometheus/Thanos components. Make sure you're connected to Azure subscription via terminal, as existing Storage account details are required to create bucket.yml config file that contains Azure object store configuration for uploading TSDB blocks to. Store.service file contents are being downloaded from Github as file is not being modified often.

**compactConfig.ps1** - installs and configures Thanos Compact component on Linux VM. Can be created on same or different server as Prometheus/Thanos components. Make sure you're connected to Azure subscription via terminal, as existing Storage account details are required to create bucket.yml config file that contains Azure object store configuration for uploading TSDB blocks to. Compact.service file contents are being downloaded from Github as file is not being modified often. IMPORTANT - all other Prometheus/Thanos components can be load balanced with few nodes, EXCEPT THANOS COMPACT. Thanos Compact must be installed only on single server to avoid conflicts. If "cannot get blob reader", "cannot get properties for Azure blob" or similar errors appear after starting compact.service, issue could be solved with below steps:
 * Increase default value (DefaultLimitNOFILE=1024) to DefaultLimitNOFILE=4096 in the /etc/systemd/system.conf or similar approach
 * Reboot machine
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Deployment diagram:**
![alt text](https://github.com/AppDSConsult/prometheusThanos/blob/master/Thanos-deploy-setup.jpg?raw=true)

*prometheusConfig.ps1* and *sidecarConfig.ps1* should be executed on *Server1* and *Server2*. These servers will be Prometheus and Thanos Sidecar cluster nodes.

*queryConfig.ps1* and *storeConfig.ps1* should be executed on *Server3* and *Server4*. These servers will be Thanos Query and Thanos Store cluster nodes.

*compactConfig.ps1* should be executed on *Server5*. Server5 acts as Thanos Compactor. As mentioned above, Thanos Compact must be installed only on single server to avoid conflicts.

Grafana should be installed separately to *Server3*, *Server4* and *Server5*, or at least on two of them to make Grafana highly available as well.
