# install .net 4.6.1 on server 2008r2
$url = 'https://download.microsoft.com/download/E/4/1/E4173890-A24A-4936-9FC9-AF930FE3FA40/NDP461-KB3102436-x86-x64-AllOS-ENU.exe'
$file = 'NDP461-KB3102436-x86-x64-AllOS-ENU.exe'
$path = "C:\Windows\Temp\$file"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url,$path)
$args = '/quiet /norestart /log c:\windows\temp'
Start-Process -FilePath $path -ArgumentList $args -Wait