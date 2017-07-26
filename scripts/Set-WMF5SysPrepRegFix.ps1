# fix sysprep issue with WMF5
# discussed here, https://windowsserver.uservoice.com/forums/301869-powershell/suggestions/11591262-bug-wmf-5-production-preview-on-windows-server-2
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\StreamProvider" -Name LastFullPayloadTime -Value 0 -PropertyType DWord -Force