Import-Module bettercredentials
Get-Module -ListAvailable -Name vmware* | Import-Module

# pull in credentials and enable log
$cred = bettercredentials\Get-Credential -UserName 'vcenter_serviceAccount@mydomain.com'
$password = $cred.GetNetworkCredential().Password
$env:PACKER_LOG=1

$builds = @('2008r2s','2012r2s','2016s')

foreach ($build in $builds)
{
    $currentBuild = $null
    $templateName = "Template-$build"
    $env:PACKER_LOG_PATH="C:\gits\packer_logs\packerlog_$build`_$(get-date -Format MM-dd-yy-HHmmss).txt"
    $currentBuild = Start-Process -FilePath 'packer.exe' -ArgumentList "build -force -var-file=`".\variables-global.json`" -var `"name=$templateName`" -var `"vcenter_password=$password`" .\vsphere-$build.json" -WindowStyle Normal -Wait -PassThru
    if ($currentBuild.ExitCode -eq 0)
    {
        Connect-VIServer -Server 'vcenter.mydomain.com'
        Get-VM -Name $templateName | Set-VM -MemoryGB 1 -Confirm:$false
        Get-VM -Name $templateName | Set-VM -NumCpu 1 -Confirm:$false
        Get-VM -Name $templateName | Get-NetworkAdapter | Remove-NetworkAdapter -Confirm:$false
        New-NetworkAdapter -VM $templateName -Portgroup 'vlan3' -Type Vmxnet3 -StartConnected -Confirm:$false
        Get-VM -Name $templateName | Set-VM -ToTemplate -Confirm:$false
        Disconnect-VIServer -Force -Confirm:$false
    }
}