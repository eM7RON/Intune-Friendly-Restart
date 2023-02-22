Add-Type -AssemblyName System.Windows.Forms
Function Create-GetSchedTime {   
    Param(   
    $SchedTime   
    )
          $script:StartTime = (Get-Date).AddSeconds($TotalTime)
          $RestartDate = ((get-date).AddSeconds($TotalTime)).AddMinutes(-5)
          $RDate = (Get-Date $RestartDate -f 'dd.MM.yyyy') -replace "\.","/"      # 16/03/2016
          $RTime = Get-Date $RestartDate -f 'HH:mm'                                    # 09:31
}
# $lastReboot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
# $now = Get-Date
# $timeSinceReboot = $now - $lastReboot
# if ($timeSinceReboot.TotalDays -gt $Reboot_Delay) {
$form = New-Object System.Windows.Forms.Form
$form.Text = "ATTENTION: ONI IT Restart Service"
$form.Width = 410
$form.Height = 160
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.ControlBox = $false
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ShowInTaskbar = $false
$form.Visible = $false
$form.TopMost = $true
$form.AutoScaleMode = "Font"

$timerUpdate = New-Object System.Windows.Forms.Timer
$TotalTime = 86400 #Auto restart countdown seconds
Create-GetSchedTime -SchedTime $TotalTime
$timerUpdate_Tick={
    # Define countdown timer
    [TimeSpan]$span = $script:StartTime - (Get-Date)
    # Update the display
    $hours = "{0:00}" -f $span.Hours
    $mins = "{0:00}" -f $span.Minutes
    $secs = "{0:00}" -f $span.Seconds
    $labelTime.Text = "{0}:{1}:{2}" -f $hours, $mins, $secs
    $timerUpdate.Start()
    if ($span.TotalSeconds -le 0)
    {
            $timerUpdate.Stop()
            shutdown -r -f /t 0
    }
}
$Form_StoreValues_Closing=
    {
            #Store the control values
    }
    
$Form_Cleanup_FormClosed=
    {
            #Remove all event handlers from the controls
            try
            {
                $Form.remove_Load($Form_Load)
                $timerUpdate.remove_Tick($timerUpdate_Tick)
                #$Form.remove_Load($Form_StateCorrection_Load)
                $Form.remove_Closing($Form_StoreValues_Closing)
                $Form.remove_FormClosed($Form_Cleanup_FormClosed)
            }
            catch [Exception]
            { }
    }
    

$label1 = New-Object System.Windows.Forms.Label
$label1.Text = "This device requires a restart in order to maintain its health. Please save"
$label1.AutoSize = $true
$label1.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($label1)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "any work and perform a restart. The device will restart automatically when"
$label2.AutoSize = $true
$label2.Location = New-Object System.Drawing.Point(10,35)
$form.Controls.Add($label2)

$label3 = New-Object System.Windows.Forms.Label
$label3.Text = "the below counter reaches zero."
$label3.AutoSize = $true
$label3.Location = New-Object System.Drawing.Point(10,60)
$form.Controls.Add($label3)

$label4 = New-Object System.Windows.Forms.Label
$label4.Text = "Time untill auto restart:"
$label4.AutoSize = $true
$label4.Location = New-Object System.Drawing.Point(10,85)
$form.Controls.Add($label4)

# labelTime
$labelTime = New-Object 'System.Windows.Forms.Label'
$labelTime.AutoSize = $True
$labelTime.Font = 'Arial, 22pt, style=Bold'
$labelTime.Location = '135, 75'
$labelTime.Name = 'labelTime'
$labelTime.Size = '30, 15'
$labelTime.TextAlign = 'MiddleCenter'
$Form.Controls.Add($labelTime)

#Start the timer
$timerUpdate.add_Tick($timerUpdate_Tick)
$timerUpdate.Start()

$button = New-Object System.Windows.Forms.Button
$button.Text = "Restart now"
$button.Width = 80
$button.Height = 30
$button.Location = New-Object System.Drawing.Point(300,80)
$form.Controls.Add($button)
$button.Add_Click({
if ([System.Windows.Forms.MessageBox]::Show(
    
    "This device will restart immediately. Are you sure?", "Reboot Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo
    ) -eq "Yes") {
    shutdown -r -f -t 0
}
})
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
