<#
Write-Output "Installing Virtualbox Guest Additions"
Write-Output "Checking for Certificates in vBox ISO"
if(test-path E:\ -Filter *.cer)
{
	Get-ChildItem E:\cert -Filter *.cer | ForEach-Object { certutil -addstore -f "TrustedPublisher" $_.FullName }
}
Start-Process -FilePath "E:\VBoxWindowsAdditions.exe" -ArgumentList "/S" -Wait
#>



Write-Host 'Importing the Oracle (for VirtualBox) certificate as a Trusted Publisher...'
E:\cert\VBoxCertUtil.exe add-trusted-publisher E:\cert\vbox-sha1.cer
if ($LASTEXITCODE) {
	throw "failed to import certificate with exit code $LASTEXITCODE"
}

Write-Host 'Installing the VirtualBox Guest Additions...'
$p = Start-Process -Wait -NoNewWindow -PassThru -FilePath E:\VBoxWindowsAdditions-amd64.exe -ArgumentList '/S'
$p.WaitForExit()
if ($p.ExitCode) {
	throw "failed to install with exit code $($p.ExitCode). Check the logs at C:\Program Files\Oracle\VirtualBox Guest Additions\install.log."
}