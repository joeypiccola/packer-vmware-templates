# install vmware tools 10.1.7
$url = 'https://packages.vmware.com/tools/releases/10.1.7/windows/x64/VMware-tools-10.1.7-5541682-x86_64.exe'
$file = 'VMware-tools-10.1.7-5541682-x86_64.exe'
$path = "C:\Windows\Temp\$file"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url,$path)
$args = '/s /v /qn reboot=r'
Start-Process -FilePath $path -ArgumentList $args -Wait