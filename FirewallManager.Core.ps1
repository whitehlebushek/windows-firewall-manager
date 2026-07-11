# FirewallManager.Core.ps1 — Shared API for CLI and GUI

$Script:RuleGroupName = "FirewallManager_Custom"

$Script:ProtocolMap = @{
    'TCP'       = 'TCP'
    'UDP'       = 'UDP'
    'ICMPv4'    = 'ICMPv4'
    'ICMPv6'    = 'ICMPv6'
    'GRE'       = '47'
    'IGMP'      = '2'
    'SCTP'      = '132'
    'ESP'       = '50'
    'AH'        = '51'
    'IPv4'      = '4'
    'IPv6'      = '41'
    'Любой'     = 'Any'
    'Any'       = 'Any'
}

function Test-AdminRights {
    $current = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $current.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-PortList {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return @() }

    $ports = [System.Collections.Generic.HashSet[int]]::new()
    $parts = $Raw -split '[,\s;]+' | Where-Object { $_ -match '\S' }

    foreach ($part in $parts) {
        if ($part -match '^(\d+)-(\d+)$') {
            $start = [int]$Matches[1]
            $end   = [int]$Matches[2]
            if ($start -gt $end) { $t = $start; $start = $end; $end = $t }
            if ($start -lt 1 -or $end -gt 65535) { throw "Диапазон портов вне 1-65535: $part" }
            for ($p = $start; $p -le $end; $p++) { [void]$ports.Add($p) }
        }
        elseif ($part -match '^\d+$') {
            $p = [int]$part
            if ($p -lt 1 -or $p -gt 65535) { throw "Порт вне диапазона 1-65535: $p" }
            [void]$ports.Add($p)
        }
        else { throw "Неверный формат порта: $part" }
    }
    return ($ports | Sort-Object)
}

function Test-IpAddressPart {
    param([string]$Part)
    if ($Part -match '^(\d{1,3}\.){3}\d{1,3}$') {
        foreach ($oct in $Part.Split('.')) {
            if ([int]$oct -gt 255) { return $false }
        }
        return $true
    }
    if ($Part -match '^(\d{1,3}\.){3}\d{1,3}/(\d{1,2})$') {
        if ([int]$Matches[1] -gt 32) { return $false }
        $ip = $Part.Split('/')[0]
        foreach ($oct in $ip.Split('.')) { if ([int]$oct -gt 255) { return $false } }
        return $true
    }
    if ($Part -match '^([0-9a-fA-F:]+)(/(\d{1,3}))?$') { return $true }
    if ($Part -match '^LocalSubnet$') { return $true }
    return $false
}

function ConvertTo-IpAddressList {
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    $parts = $Raw -split '[,\s;]+' | Where-Object { $_ -match '\S' }
    $list = @()
    foreach ($part in $parts) {
        if (-not (Test-IpAddressPart $part)) { throw "Неверный IP-адрес: $part" }
        $list += $part
    }
    return ($list -join ',')
}

function Resolve-ProtocolValue {
    param([string]$Name)
    $key = $Name.Trim()
    if ($Script:ProtocolMap.ContainsKey($key)) { return $Script:ProtocolMap[$key] }
    if ($key -match '^\d+$') { return $key }
    throw "Неизвестный протокол: $Name"
}

function Resolve-ProtocolSelection {
    param([string]$Selection)
    switch ($Selection) {
        'TCP + UDP' { return @('TCP','UDP') }
        default     { return @(Resolve-ProtocolValue $Selection) }
    }
}

function Format-AddressDisplay {
    param($Value)
    if (-not $Value -or $Value -eq 'Any') { return 'Любые' }
    if ($Value -is [array]) { return ($Value -join ', ') }
    return [string]$Value
}

function Get-FirewallRuleDetails {
    param($Rule)
    $portFilter  = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $Rule -ErrorAction SilentlyContinue
    $addrFilter  = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $Rule -ErrorAction SilentlyContinue
    $protocol    = if ($portFilter.Protocol) { $portFilter.Protocol } else { 'Any' }
    $ports       = if ($portFilter.LocalPort -eq 'Any' -or -not $portFilter.LocalPort) { 'Все' } else { $portFilter.LocalPort }
    $remoteIp    = Format-AddressDisplay $addrFilter.RemoteAddress
    $localIp     = Format-AddressDisplay $addrFilter.LocalAddress

    [PSCustomObject]@{
        Rule        = $Rule
        Name        = $Rule.DisplayName
        RuleId      = $Rule.Name
        Direction   = $Rule.Direction
        DirectionRu = switch ($Rule.Direction) { 'Inbound' { 'Входящие' }; 'Outbound' { 'Исходящие' }; default { $Rule.Direction } }
        Action      = $Rule.Action
        ActionRu    = switch ($Rule.Action) { 'Allow' { 'Разрешить' }; 'Block' { 'Заблокировать' }; default { $Rule.Action } }
        Protocol    = $protocol
        Ports       = $ports
        RemoteIp    = $remoteIp
        LocalIp     = $localIp
        Enabled     = [bool]$Rule.Enabled
        EnabledRu   = if ($Rule.Enabled) { 'Вкл' } else { 'Выкл' }
        Profile     = ($Rule.Profile -join ', ')
    }
}

function Get-FirewallRules {
    Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayGroup -eq $Script:RuleGroupName -or $_.Group -eq $Script:RuleGroupName } |
        Sort-Object DisplayName |
        ForEach-Object { Get-FirewallRuleDetails $_ }
}

function Get-FirewallRuleStats {
    param([array]$Rules = @())
    if ($Rules.Count -eq 0) { $Rules = @(Get-FirewallRules) }
    $active = 0
    $inbound = 0
    foreach ($r in $Rules) {
        if ($r.Enabled) { $active++ }
        if ($r.Direction -eq 'Inbound') { $inbound++ }
    }
    $total = $Rules.Count
    return [PSCustomObject]@{
        Total    = $total
        Active   = $active
        Inactive = $total - $active
        Inbound  = $inbound
        Outbound = $total - $inbound
    }
}

function Test-RuleMatchesSearch {
    param($Rule, [string]$QueryLower)
    if ([string]::IsNullOrWhiteSpace($QueryLower)) { return $true }
    return (
        $Rule.Name.ToLower().Contains($QueryLower) -or
        $Rule.Ports.ToLower().Contains($QueryLower) -or
        $Rule.RemoteIp.ToLower().Contains($QueryLower) -or
        $Rule.LocalIp.ToLower().Contains($QueryLower) -or
        $Rule.Protocol.ToLower().Contains($QueryLower) -or
        $Rule.DirectionRu.ToLower().Contains($QueryLower) -or
        $Rule.ActionRu.ToLower().Contains($QueryLower) -or
        $Rule.EnabledRu.ToLower().Contains($QueryLower)
    )
}

function Get-FirewallRulesFiltered {
    param(
        [array]$Rules,
        [string]$Direction = 'All',
        [string]$Status = 'All',
        [string]$Search = ''
    )
    $result = $Rules
    if ($Direction -eq 'Inbound') {
        $result = @($result | Where-Object { $_.Direction -eq 'Inbound' })
    }
    elseif ($Direction -eq 'Outbound') {
        $result = @($result | Where-Object { $_.Direction -eq 'Outbound' })
    }
    if ($Status -eq 'Active') {
        $result = @($result | Where-Object { $_.Enabled })
    }
    elseif ($Status -eq 'Inactive') {
        $result = @($result | Where-Object { -not $_.Enabled })
    }
    $q = $Search.Trim().ToLower()
    if (-not [string]::IsNullOrWhiteSpace($q)) {
        $result = @($result | Where-Object { Test-RuleMatchesSearch -Rule $_ -QueryLower $q })
    }
    return $result
}

function Test-FirewallRuleExists {
    param([string]$DisplayName)
    return [bool](Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue)
}

function Add-FirewallRule {
    param(
        [string]$Name,
        [ValidateSet('Inbound','Outbound')][string]$Direction,
        [ValidateSet('Allow','Block')][string]$Action,
        [string[]]$Protocols = @('TCP'),
        [string]$Ports = '',
        [string]$RemoteAddress = '',
        [string]$LocalAddress = '',
        [string[]]$Profiles = @('Domain','Private','Public')
    )

    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Название обязательно' }
    if (Test-FirewallRuleExists $Name) { throw "Правило '$Name' уже существует" }

    $resolvedProtos = foreach ($p in $Protocols) { Resolve-ProtocolValue $p }

    $portList = @()
    if ($resolvedProtos -notcontains 'Any' -and -not [string]::IsNullOrWhiteSpace($Ports)) {
        $portList = ConvertTo-PortList $Ports
    }

    $remote = ConvertTo-IpAddressList $RemoteAddress
    $local  = ConvertTo-IpAddressList $LocalAddress

    $created = @()
    foreach ($proto in $resolvedProtos) {
        $ruleName = if ($resolvedProtos.Count -gt 1) { "$Name ($proto)" } else { $Name }
        if (Test-FirewallRuleExists $ruleName) { throw "Правило '$ruleName' уже существует" }

        $params = @{
            DisplayName = $ruleName
            Group       = $Script:RuleGroupName
            Direction   = $Direction
            Action      = $Action
            Protocol    = $proto
            Profile     = $Profiles
            Enabled     = 'True'
        }
        if ($portList.Count -gt 0 -and $proto -in @('TCP','UDP','6','17')) {
            $params.LocalPort = ($portList -join ',')
        }
        if ($remote) { $params.RemoteAddress = $remote }
        if ($local)  { $params.LocalAddress  = $local }

        New-NetFirewallRule @params | Out-Null
        $created += $ruleName
    }
    return $created
}

function Set-FirewallRuleEnabled {
    param([string]$RuleId, [bool]$Enabled)
    Set-NetFirewallRule -Name $RuleId -Enabled $(if ($Enabled) { 'True' } else { 'False' })
}

function Remove-FirewallRule {
    param([string]$RuleId)
    Remove-NetFirewallRule -Name $RuleId
}

function Remove-AllFirewallRules {
    $rules = Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayGroup -eq $Script:RuleGroupName -or $_.Group -eq $Script:RuleGroupName }
    if ($rules) { $rules | Remove-NetFirewallRule }
    return @($rules).Count
}

function Export-FirewallRules {
    param([string]$Path)
    $rules = Get-FirewallRules
    if (-not $rules) { throw 'Нет правил для экспорта' }

    $backup = foreach ($r in $rules) {
        $addrFilter = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $r.Rule
        [PSCustomObject]@{
            DisplayName   = $r.Name
            Direction     = $r.Direction
            Action        = $r.Action
            Protocol      = $r.Protocol
            LocalPort     = if ($r.Ports -eq 'Все') { 'Any' } else { $r.Ports }
            RemoteAddress = if ($r.RemoteIp -eq 'Любые') { 'Any' } else { $r.RemoteIp }
            LocalAddress  = if ($r.LocalIp -eq 'Любые') { 'Any' } else { $r.LocalIp }
            Profile       = $r.Rule.Profile
            Enabled       = $r.Enabled
            Group         = $Script:RuleGroupName
        }
    }
    $backup | ConvertTo-Json -Depth 3 | Set-Content -Path $Path -Encoding UTF8
    return $Path
}

function Import-FirewallRules {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Файл не найден: $Path" }

    $items = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($items -isnot [Array]) { $items = @($items) }

    $imported = 0
    $skipped  = 0
    foreach ($item in $items) {
        if (Test-FirewallRuleExists $item.DisplayName) { $skipped++; continue }

        $params = @{
            DisplayName = $item.DisplayName
            Group       = $Script:RuleGroupName
            Direction   = $item.Direction
            Action      = $item.Action
            Protocol    = $item.Protocol
            Profile     = $item.Profile
            Enabled     = $item.Enabled
        }
        if ($item.LocalPort -and $item.LocalPort -ne 'Any') { $params.LocalPort = $item.LocalPort }
        if ($item.RemoteAddress -and $item.RemoteAddress -ne 'Any') { $params.RemoteAddress = $item.RemoteAddress }
        if ($item.LocalAddress -and $item.LocalAddress -ne 'Any') { $params.LocalAddress = $item.LocalAddress }
        New-NetFirewallRule @params | Out-Null
        $imported++
    }
    return @{ Imported = $imported; Skipped = $skipped }
}