#Requires -RunAsAdministrator

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'FirewallManager.Core.ps1')

function Write-Header {
    param([string]$Title)
    Write-Host ''
    Write-Host ('=' * 60) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ('=' * 60) -ForegroundColor Cyan
}

function Read-Choice {
    param([string]$Prompt, [string[]]$Options, [int]$Default = 0)
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $marker = if ($i -eq $Default) { '*' } else { ' ' }
        Write-Host "  [$marker] $($i + 1). $($Options[$i])"
    }
    $input = Read-Host "$Prompt [1-$($Options.Count), Enter = $($Default + 1)]"
    if ([string]::IsNullOrWhiteSpace($input)) { return $Default }
    $num = 0
    if ([int]::TryParse($input, [ref]$num) -and $num -ge 1 -and $num -le $Options.Count) { return $num - 1 }
    Write-Host ([char]0x041D + [char]0x0435 + [char]0x0432 + [char]0x0435 + [char]0x0440 + [char]0x043D + [char]0x044B + [char]0x0439 + ' ' + [char]0x0432 + [char]0x044B + [char]0x0431 + [char]0x043E + [char]0x0440) -ForegroundColor Yellow
    return $Default
}

function Read-PortList {
    param([string]$Prompt)
    Write-Host ''
    Write-Host '  Formats: 80 | 80,443 | 1000-1010' -ForegroundColor DarkGray
    $raw = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($raw)) { return '' }
    return $raw.Trim()
}

function Show-Rules {
    Write-Header "Rules ($Script:RuleGroupName)"
    $rules = @(Get-FirewallRules)
    if ($rules.Count -eq 0) { Write-Host '  (empty)' -ForegroundColor Yellow; return }
    $i = 1
    foreach ($info in $rules) {
        $status = if ($info.Enabled) { 'ON' } else { 'OFF' }
        $color  = if ($info.Enabled) { 'Green' } else { 'DarkGray' }
        Write-Host ''
        Write-Host "  [$i] $($info.Name)" -ForegroundColor $color
        Write-Host "      $($info.DirectionRu) | $($info.ActionRu) | $($info.Protocol) | $($info.Ports)"
        Write-Host "      IP: $($info.RemoteIp) | $($info.Profile) | $status"
        $i++
    }
}

function New-CustomRule {
    Write-Header 'New rule'
    $name = Read-Host 'Rule name'
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Host 'Name required.' -ForegroundColor Red; return }

    $dirIdx = Read-Choice -Prompt 'Direction' -Options @('Inbound', 'Outbound')
    $direction = @('Inbound', 'Outbound')[$dirIdx]
    $actIdx = Read-Choice -Prompt 'Action' -Options @('Allow', 'Block')
    $action = @('Allow', 'Block')[$actIdx]
    $protoIdx = Read-Choice -Prompt 'Protocol' -Options @('TCP', 'UDP', 'TCP+UDP', 'Any')
    $protocols = switch ($protoIdx) { 0 { @('TCP') } 1 { @('UDP') } 2 { @('TCP','UDP') } 3 { @('Any') } }

    $profiles = @('Domain', 'Private', 'Public')
    $ports = if ($protoIdx -ne 3) { Read-PortList -Prompt 'Ports (empty=all)' } else { '' }
    $remoteIp = Read-Host 'Remote IP (empty=any)'
    $localIp  = Read-Host 'Local IP (empty=any)'

    try {
        $created = Add-FirewallRule -Name $name.Trim() -Direction $direction -Action $action `
            -Protocols $protocols -Ports $ports -RemoteAddress $remoteIp.Trim() `
            -LocalAddress $localIp.Trim() -Profiles $profiles
        Write-Host "Created: $($created -join ', ')" -ForegroundColor Green
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
}

function Set-RuleState {
    param([bool]$Enable)
    Show-Rules
    $rules = @(Get-FirewallRules)
    if ($rules.Count -eq 0) { return }
    $input = Read-Host 'Rule number (0=cancel)'
    if ($input -eq '0' -or [string]::IsNullOrWhiteSpace($input)) { return }
    $num = 0
    if (-not [int]::TryParse($input, [ref]$num) -or $num -lt 1 -or $num -gt $rules.Count) {
        Write-Host 'Invalid number.' -ForegroundColor Red; return
    }
    $rule = $rules[$num - 1]
    try {
        Set-FirewallRuleEnabled -RuleId $rule.RuleId -Enabled $Enable
        Write-Host "OK: $($rule.Name)" -ForegroundColor Green
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
}

function Remove-CustomRule {
    Show-Rules
    $rules = @(Get-FirewallRules)
    if ($rules.Count -eq 0) { return }
    Write-Host ''; Write-Host '  [0] Cancel  [A] Delete ALL' -ForegroundColor DarkGray
    $input = Read-Host 'Rule number'
    if ($input -eq '0' -or [string]::IsNullOrWhiteSpace($input)) { return }
    if ($input -match '^[Aa]$') {
        $confirm = Read-Host "Delete ALL $($rules.Count)? (yes/no)"
        if ($confirm -eq 'yes') { Write-Host "Removed: $(Remove-AllFirewallRules)" -ForegroundColor Green }
        return
    }
    $num = 0
    if (-not [int]::TryParse($input, [ref]$num) -or $num -lt 1 -or $num -gt $rules.Count) {
        Write-Host 'Invalid.' -ForegroundColor Red; return
    }
    $rule = $rules[$num - 1]
    if ((Read-Host "Delete '$($rule.Name)'? (yes/no)") -eq 'yes') {
        try { Remove-FirewallRule -RuleId $rule.RuleId; Write-Host 'Deleted.' -ForegroundColor Green }
        catch { Write-Host $_.Exception.Message -ForegroundColor Red }
    }
}

function Export-RulesBackup {
    $path = Join-Path $env:USERPROFILE "FirewallManager_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    try { Export-FirewallRules -Path $path | Out-Null; Write-Host "Saved: $path" -ForegroundColor Green }
    catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
}

function Import-RulesBackup {
    $path = Read-Host 'JSON backup path'
    if (-not (Test-Path $path)) { Write-Host 'Not found.' -ForegroundColor Red; return }
    try {
        $r = Import-FirewallRules -Path $path
        Write-Host "Imported: $($r.Imported), skipped: $($r.Skipped)" -ForegroundColor Green
    } catch { Write-Host $_.Exception.Message -ForegroundColor Red }
}

function Show-MainMenu {
    Write-Header 'Windows Firewall Manager'
    $s = Get-FirewallRuleStats
    Write-Host "  Group: $Script:RuleGroupName | Rules: $($s.Total) ($($s.Active) active)" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  1. Create  2. List  3. Enable  4. Disable  5. Delete'
    Write-Host '  6. Export  7. Import  0. Exit'
    Write-Host ''
}

if (-not (Test-AdminRights)) {
    Write-Host 'Administrator rights required.' -ForegroundColor Red
    exit 1
}

do {
    Show-MainMenu
    $choice = Read-Host 'Choice'
    switch ($choice) {
        '1' { New-CustomRule }
        '2' { Show-Rules }
        '3' { Set-RuleState -Enable $true }
        '4' { Set-RuleState -Enable $false }
        '5' { Remove-CustomRule }
        '6' { Export-RulesBackup }
        '7' { Import-RulesBackup }
        '0' { break }
        default { Write-Host 'Unknown.' -ForegroundColor Yellow }
    }
    if ($choice -ne '0') { Read-Host 'Enter to continue' }
} while ($choice -ne '0')