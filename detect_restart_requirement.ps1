##################################################################################################
# 									Variables to fill
##################################################################################################

# Delay for BIOS update - if BIOS release is older than the delay, it will continue the process
$Reboot_Delay = 1

##################################################################################################
# 									Variables to fill
##################################################################################################
	
# Check Windows registry keys if restart required
#Adapted from https://gist.github.com/altrive/5329377
#Based on <http://gallery.technet.microsoft.com/scriptcenter/Get-PendingReboot-Query-bdb79542>
function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
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
write-output "Last reboot/shutdown: $Reboot_Time"				
If($Boot_Uptime_Days -ge $Reboot_Delay){
		write-output "Device uptime is longer than $Reboot_Delay days. Restart required"			
		EXIT 1		
}

$DoINeedAReboot = Test-PendingReboot
if ($DoINeedAReboot) {
    write-output "Windows registry indictaes a restart is required"	
    #invoke-expression -Command .\restart_service.ps1
    #Restart-Computer
    EXIT 1
  }
write-output "Restart not required"	
EXIT 0
