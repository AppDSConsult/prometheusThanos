# Install dependencies
zypper update && zypper --non-interactive install curl tar libicu52_1

# Download the powershell '.tar.gz' archive
curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.1.4/powershell-7.1.4-linux-x64.tar.gz -o /tmp/powershell.tar.gz

# Create the target folder where powershell will be placed
mkdir -p /opt/microsoft/powershell/7

# Expand powershell to the target folder
tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

# Set execute permissions
chmod +x /opt/microsoft/powershell/7/pwsh

# Create the symbolic link that points to pwsh
ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Install OMI
sudo rpm -Uvh https://packages.microsoft.com/config/sles/15/packages-microsoft-prod.rpm
sudo zypper --gpg-auto-import-keys install -y omi

# Install DSC
wget https://github.com/microsoft/PowerShell-DSC-for-Linux/releases/download/v1.2.1-0/dsc-1.2.1-0.ssl_110.x64.rpm
sudo rpm -Uvh dsc-1.2.1-0.ssl_110.x64.rpm
cp -R /opt/microsoft/dsc/modules/nx $PSHOME\Modules
