REM harden winrm
call winrm set winrm/config/service/auth @{Basic="false"}
call winrm set winrm/config/service @{AllowUnencrypted="false"}
call winrm set winrm/config/client/auth '@{Basic="false"}'
shutdown /s /t 10 /f /d p:4:1 /c "Packer Shutdown"