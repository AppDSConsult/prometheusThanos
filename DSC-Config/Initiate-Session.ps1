$Node = "10.0.7.6"
$Credential = Get-Credential -UserName "root" -Message "Enter Password:"
#Options for a trusted SSL certificate
#Ignore SSL certificate validation
$opt = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$sessParams = @{
    Credential = $credential
    ComputerName = $Node
    Port = 5986
    Authentication = 'basic'
    SessionOption = $opt
    OperationTimeoutSec = 90
}

$Sess = New-CimSession @sessParams
