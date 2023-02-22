##################################################################################################
# 									Variables to fill
##################################################################################################

# Delay for BIOS update - if BIOS release is older than the delay, it will continue the process
$Reboot_Delay = 4

##################################################################################################
# 									Variables to fill
##################################################################################################

$LogFile="C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\ONI-Restart-Policy-Detection.log"
Start-Transcript $LogFile

Write-Host "Detection initiated"

# Check Windows registry keys if restart required
#Adapted from https://gist.github.com/altrive/5329377
#Based on <http://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542>
function Test-PendingReboot
{
	Write-Host "Executing Test-PendingReboot"
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) {
	Write-Host "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending detected"
	return $true
}
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { 
	Write-Host "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired detected"
	return $true 
}
#  if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) {
# 	Write-Host "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations detected"
# 	return $true 
# }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
	Write-Host '[wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities" determined reboot pending'
     return $true
   }
 }catch{}

 return $false
}

$Last_reboot = Get-ciminstance Win32_OperatingSystem | Select -Exp LastBootUpTime	
# Check if fast boot is enabled: if enabled uptime may be wrong
$Check_FastBoot = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -ea silentlycontinue).HiberbootEnabled 
# If fast boot is not enabled
If(($Check_FastBoot -eq $null) -or ($Check_FastBoot -eq 0))
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x0*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}
	}
ElseIf($Check_FastBoot -eq 1) 	
	{
		$Boot_Event = Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x1*"}
		If($Boot_Event -ne $null)
			{
				$Last_boot = $Boot_Event[0].TimeCreated		
			}			
	}		
	
If($Last_boot -eq $null)
	{
		# If event log with ID 27 can not be found we checl last reboot time using WMI
		# It can occurs for instance if event log has been cleaned	
		$Uptime = $Last_reboot
	}
Else
	{
		If($Last_reboot -ge $Last_boot)
			{
				$Uptime = $Last_reboot
			}
		Else
			{
				$Uptime = $Last_boot
			}	
	}
	
$Current_Date = get-date
$Diff_boot_time = $Current_Date - $Uptime
$Boot_Uptime_Days = $Diff_boot_time.Days	
$Hour = $Diff_boot_time.Hours
$Minutes = $Diff_boot_time.Minutes
$Reboot_Time = "$Boot_Uptime_Days day(s)" + ": $Hour hour(s)" + " : $minutes minute(s)"
Write-Host "Last reboot/shutdown: $Reboot_Time"			
If($Boot_Uptime_Days -ge $Reboot_Delay){
	Write-Host "Device uptime is longer than $Reboot_Delay days. Restart required"
	Stop-Transcript
	EXIT 1		
}

$DoINeedAReboot = Test-PendingReboot
if ($DoINeedAReboot) {
	Write-Host "Windows registry indictates a restart is required"
    #invoke-expression -Command .\restart_service.ps1
    #Restart-Computer
    Stop-Transcript
	EXIT 1
  }
Write-Host "Restart not required"
Stop-Transcript
EXIT 0
