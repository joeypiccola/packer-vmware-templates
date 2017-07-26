# install windows managment framework 4 on server 2008r2
$url = 'https://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu'
$file = 'Windows6.1-KB2819745-x64-MultiPkg.msu'
$path = "C:\Windows\Temp\$file"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url,$path)
$args = '/quiet /norestart'
Start-Process -FilePath $path -ArgumentList $args -Wait