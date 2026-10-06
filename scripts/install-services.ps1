# Registers the ERP backend (port 3000) and the built Flutter web frontend
# (port 5050) as Windows scheduled tasks so they come back on their own if
# they ever stop. Re-run this script any time to re-register; it replaces the
# existing tasks. Redeploying new code is just: rebuild, then
# `Stop-ScheduledTask` + `Start-ScheduledTask` for the matching task.
#
#   powershell -ExecutionPolicy Bypass -File scripts\install-services.ps1
#
# Everything the tasks need (logs, launcher scripts, the `serve` static
# server) lives next to the repo on D:, deliberately NOT under %APPDATA% /
# %LOCALAPPDATA%: when this script is run from the Claude desktop app (a
# packaged MSIX app) writes there are redirected into a private per-app copy
# that scheduled tasks can't see.
#
# Run from an elevated (Administrator) PowerShell, the tasks start at BOOT,
# before anyone logs in. Without elevation Windows refuses boot-time tasks, so
# the script falls back to starting them at this user's LOGON instead.

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$home_ = Split-Path -Parent $root
$node = (Get-Command node).Source
$logs = Join-Path $home_ 'logs'
$tools = Join-Path $home_ 'tools'
$serve = Join-Path $tools 'node_modules\serve\build\main.js'
New-Item -ItemType Directory -Force $logs, $tools | Out-Null

if (-not (Test-Path $serve)) {
  Write-Host "Installing serve into $tools ..."
  npm install --prefix $tools serve --no-audit --no-fund | Out-Null
  if (-not (Test-Path $serve)) { throw "serve install failed" }
}

$tasks = @(
  @{
    Name = 'ZeraERP-Backend'
    WorkDir = Join-Path $root 'backend'
    Command = "`"$node`" --enable-source-maps dist/main >> `"$logs\backend.log`" 2>&1"
  },
  @{
    Name = 'ZeraERP-Frontend'
    WorkDir = Join-Path $root 'frontend'
    Command = "`"$node`" `"$serve`" -s build/web -l tcp://0.0.0.0:5050 >> `"$logs\frontend.log`" 2>&1"
  }
)

$settings = New-ScheduledTaskSettingsSet `
  -MultipleInstances IgnoreNew `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit ([TimeSpan]::Zero) `
  -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)

# Also re-check every 5 minutes: with MultipleInstances=IgnoreNew a
# still-running server makes the repeat a no-op, while a dead one is
# relaunched within 5 minutes.
$repeat = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) `
  -RepetitionInterval (New-TimeSpan -Minutes 5)

foreach ($t in $tasks) {
  # A tiny VBS launcher runs the command in a hidden window (WshShell.Run
  # style 0) and waits for it, so the task shows as "running" while the
  # server is up and no console window ever appears.
  $vbs = Join-Path $logs ($t.Name + '.vbs')
  $line = 'cmd.exe /c "' + $t.Command + '"'
  Set-Content -Path $vbs -Encoding ASCII -Value @(
    'Set sh = CreateObject("WScript.Shell")',
    ('sh.CurrentDirectory = "' + $t.WorkDir + '"'),
    ('sh.Run "' + $line.Replace('"', '""') + '", 0, True')
  )
  $action = New-ScheduledTaskAction -Execute 'wscript.exe' `
    -Argument ('//B //Nologo "' + $vbs + '"') -WorkingDirectory $t.WorkDir

  try {
    $trigger = @((New-ScheduledTaskTrigger -AtStartup), $repeat)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME `
      -LogonType S4U -RunLevel Limited
    Register-ScheduledTask -TaskName $t.Name -Action $action `
      -Trigger $trigger -Settings $settings -Principal $principal `
      -Force | Out-Null
    Write-Host "Registered $($t.Name) (starts at boot)"
  } catch {
    $trigger = @((New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME), $repeat)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME `
      -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $t.Name -Action $action `
      -Trigger $trigger -Settings $settings -Principal $principal `
      -Force | Out-Null
    Write-Host "Registered $($t.Name) (starts at logon - re-run elevated for boot-time start)"
  }
}
