# script used to incremenelty install windows udpates
# expects the PSWindowsUpdate module to be installed
# needs to be run by a packer powershell provisioner at least 4 times in a row with reboots in between (4x depends on your OS)
# no longer used since https://github.com/rgl/packer-provisioner-windows-update came to be with https://github.com/rgl/packer-provisioner-windows-update/pull/4

$UpdateLimit = 50
$updates = Get-WUList
if ($updates)
{
    Write-Host "$($updates.count) total updates found for install." -ForegroundColor Green
    $FiftyMostRecentUpdates = $updates | Sort-Object -Property LastDeploymentChangeTime -Descending | select -First $UpdateLimit
    if ($updates.count -gt $UpdateLimit)
    {
        $updatesHidden = $true
        $EverythingElse = Compare-Object -ReferenceObject $updates -DifferenceObject $FiftyMostRecentUpdates -Property kb -PassThru
        $kbarray = @()
        $EverythingElse | %{$kbarray += $_.kb}
        write-host "Hiding $($EverythingElse.count) updates." -ForegroundColor Green
        Hide-WUUpdate -KBArticleID $kbarray -HideStatus:$true -Confirm:$false | Out-Null
    }

    $updatesToInstall = Get-WUInstall -ListOnly
    Write-Host "Installing $($updatesToInstall.count) updates." -ForegroundColor Green
    Get-WuInstall -AcceptAll -IgnoreUserInput -IgnoreReboot -Confirm:$false

    if ($updatesHidden -eq $true)
    {
        write-host "Unhiding previously $($EverythingElse.count) hidden updates." -ForegroundColor Green
        Hide-WUUpdate -KBArticleID $kbarray -HideStatus:$false -Confirm:$false | Out-Null
    }
}
else
{
    Write-Host "No updates found to install." -ForegroundColor Green
}