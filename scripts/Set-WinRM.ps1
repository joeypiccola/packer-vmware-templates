cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm quickconfig -transport:http
cmd.exe /c winrm set winrm/config @{MaxTimeoutms="1800000"}
cmd.exe /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB="800"}
cmd.exe /c winrm set winrm/config/client/auth '@{Basic="true"}'
cmd.exe /c winrm set winrm/config/service/auth '@{Basic="true"}'
cmd.exe /c winrm set winrm/config/service '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set winrm/config/Listener?Address=*+Transport=HTTP @{Port="5985"}
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm