#Requires -RunAsAdministrator

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'FirewallManager.Core.ps1')

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

if (-not (Test-AdminRights)) {
    [System.Windows.MessageBox]::Show(
        "Требуются права администратора.
Запустите от имени администратора.",
        'Брандмауэр', 'OK', 'Error') | Out-Null
    exit 1
}

$xaml = Get-Content (Join-Path $ScriptDir 'FirewallManager.Gui.xaml') -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$RulesList       = $window.FindName('RulesList')
$TxtSearch       = $window.FindName('TxtSearch')
$TxtStats        = $window.FindName('TxtStats')
$EmptyState      = $window.FindName('EmptyState')
$BtnAdd          = $window.FindName('BtnAdd')
$BtnRefresh      = $window.FindName('BtnRefresh')
$BtnEmptyAdd     = $window.FindName('BtnEmptyAdd')
$BtnStatTotal    = $window.FindName('BtnStatTotal')
$BtnStatActive   = $window.FindName('BtnStatActive')
$BtnStatInactive = $window.FindName('BtnStatInactive')
$BtnStatOutbound = $window.FindName('BtnStatOutbound')
$BtnNavBackup    = $window.FindName('BtnNavBackup')
$TxtEmptyTitle   = $window.FindName('TxtEmptyTitle')
$TxtEmptySubtitle = $window.FindName('TxtEmptySubtitle')
$TxtSelectionInfo = $window.FindName('TxtSelectionInfo')
$BtnEnable       = $window.FindName('BtnEnable')
$BtnDisable      = $window.FindName('BtnDisable')
$BtnDelete       = $window.FindName('BtnDelete')
$BtnExport       = $window.FindName('BtnExport')
$BtnImport       = $window.FindName('BtnImport')
$ModalOverlay    = $window.FindName('ModalOverlay')
$InpName         = $window.FindName('InpName')
$InpPorts        = $window.FindName('InpPorts')
$InpRemoteIp     = $window.FindName('InpRemoteIp')
$InpLocalIp      = $window.FindName('InpLocalIp')
$CmbProtocol     = $window.FindName('CmbProtocol')
$SegInbound      = $window.FindName('SegInbound')
$SegOutbound     = $window.FindName('SegOutbound')
$TxtDirectionHint = $window.FindName('TxtDirectionHint')
$SegAllow        = $window.FindName('SegAllow')
$SegBlock        = $window.FindName('SegBlock')
$ChkDomain       = $window.FindName('ChkDomain')
$ChkPrivate      = $window.FindName('ChkPrivate')
$ChkPublic       = $window.FindName('ChkPublic')
$BtnModalCancel  = $window.FindName('BtnModalCancel')
$BtnModalCreate  = $window.FindName('BtnModalCreate')
$SegFilterAll      = $window.FindName('SegFilterAll')
$SegFilterInbound  = $window.FindName('SegFilterInbound')
$SegFilterOutbound = $window.FindName('SegFilterOutbound')
$SegStatusAll       = $window.FindName('SegStatusAll')
$SegStatusActive    = $window.FindName('SegStatusActive')
$SegStatusInactive  = $window.FindName('SegStatusInactive')
$TxtRulesSummary    = $window.FindName('TxtRulesSummary')
$TxtFilterInfo      = $window.FindName('TxtFilterInfo')
$TxtStatTotal       = $window.FindName('TxtStatTotal')
$TxtStatActive      = $window.FindName('TxtStatActive')
$TxtStatInactive    = $window.FindName('TxtStatInactive')
$TxtStatOutbound    = $window.FindName('TxtStatOutbound')
$TxtStatsActive     = $window.FindName('TxtStatsActive')
$TxtStatsInactive   = $window.FindName('TxtStatsInactive')

$Script:AllRules = @()
$Script:SearchPlaceholder = 'Поиск по названию, порту, IP, протоколу...'
$Script:SearchPlaceholderLower = $Script:SearchPlaceholder.ToLower()
$Script:FilterSync = $false
$Script:BrushSelected = [System.Windows.Media.Brush]([System.Windows.Media.BrushConverter]::new().ConvertFrom('#71717A'))
$Script:BrushMuted    = [System.Windows.Media.Brush]([System.Windows.Media.BrushConverter]::new().ConvertFrom('#A1A1AA'))

$Script:SearchDebounce = New-Object System.Windows.Threading.DispatcherTimer
$Script:SearchDebounce.Interval = [TimeSpan]::FromMilliseconds(300)

function Show-Toast {
    param([string]$Message, [string]$Type = 'Info')
    $title = switch ($Type) { 'Error' { 'Ошибка' }; 'Success' { 'Готово' }; default { 'Брандмауэр' } }
    $icon  = switch ($Type) { 'Error' { 'Error' }; 'Success' { 'Information' }; default { 'Information' } }
    [System.Windows.MessageBox]::Show($Message, $title, 'OK', $icon) | Out-Null
}

function Get-ActiveFilterDirection {
    if ($SegFilterInbound.IsChecked)  { return 'Inbound' }
    if ($SegFilterOutbound.IsChecked) { return 'Outbound' }
    return 'All'
}

function Get-ActiveFilterStatus {
    if ($SegStatusActive.IsChecked)   { return 'Active' }
    if ($SegStatusInactive.IsChecked) { return 'Inactive' }
    return 'All'
}

function Get-SearchQuery {
    $q = $TxtSearch.Text.Trim()
    if ($q.Equals($Script:SearchPlaceholder, [StringComparison]::OrdinalIgnoreCase)) { return '' }
    return $q
}

function Update-Dashboard {
    param([int]$Shown = -1)
    $stats = Get-FirewallRuleStats -Rules $Script:AllRules
    $total    = $stats.Total
    $active   = $stats.Active
    $inactive = $stats.Inactive
    $inbound  = $stats.Inbound
    $outbound = $stats.Outbound

    $TxtStatTotal.Text    = [string]$total
    $TxtStatActive.Text   = [string]$active
    $TxtStatInactive.Text = [string]$inactive
    $TxtStatOutbound.Text = [string]$outbound
    $TxtStats.Text        = "$total правил"
    $TxtStatsActive.Text  = "$active активных"
    $TxtStatsInactive.Text = "$inactive отключённых"

    if ($total -eq 0) {
        $TxtRulesSummary.Text = 'Правил пока нет — создайте первое'
    }
    else {
        $TxtRulesSummary.Text = "В системе $total правил: $active активных, $inactive отключённых ($inbound входящих, $outbound исходящих)"
    }

    if ($Shown -ge 0 -and $Shown -ne $total) {
        $TxtFilterInfo.Text = "Показано $Shown из $total"
    } else {
        $TxtFilterInfo.Text = if ($total -gt 0) { "Показано все $total" } else { '' }
    }
}

function Get-FilteredRules {
    return @(Get-FirewallRulesFiltered -Rules $Script:AllRules `
        -Direction (Get-ActiveFilterDirection) `
        -Status (Get-ActiveFilterStatus) `
        -Search (Get-SearchQuery))
}

function Update-EmptyState {
    param([int]$FilteredCount)
    if ($FilteredCount -gt 0) {
        $EmptyState.Visibility = 'Collapsed'
        return
    }
    $EmptyState.Visibility = 'Visible'
    if ($Script:AllRules.Count -eq 0) {
        $TxtEmptyTitle.Text = 'Правил пока нет'
        $TxtEmptySubtitle.Text = 'Создайте первое правило для управления трафиком'
        $BtnEmptyAdd.Visibility = 'Visible'
    }
    else {
        $TxtEmptyTitle.Text = 'Ничего не найдено'
        $TxtEmptySubtitle.Text = 'Измените фильтры или очистите поиск'
        $BtnEmptyAdd.Visibility = 'Collapsed'
    }
}

function Update-ActionBarState {
    $rule = Get-SelectedRule
    if ($rule) {
        $BtnEnable.IsEnabled  = -not $rule.Enabled
        $BtnDisable.IsEnabled  = [bool]$rule.Enabled
        $BtnDelete.IsEnabled   = $true
        $TxtSelectionInfo.Text = $rule.Name
        $TxtSelectionInfo.Foreground = $Script:BrushSelected
    }
    else {
        $BtnEnable.IsEnabled  = $false
        $BtnDisable.IsEnabled = $false
        $BtnDelete.IsEnabled  = $false
        $TxtSelectionInfo.Text = 'Выберите правило в списке'
        $TxtSelectionInfo.Foreground = $Script:BrushMuted
    }
}

function Set-FilterPreset {
    param(
        [ValidateSet('All', 'Inbound', 'Outbound')][string]$Direction = 'All',
        [ValidateSet('All', 'Active', 'Inactive')][string]$Status = 'All'
    )
    $Script:FilterSync = $true
    try {
        $SegFilterAll.IsChecked      = ($Direction -eq 'All')
        $SegFilterInbound.IsChecked  = ($Direction -eq 'Inbound')
        $SegFilterOutbound.IsChecked = ($Direction -eq 'Outbound')
        $SegStatusAll.IsChecked      = ($Status -eq 'All')
        $SegStatusActive.IsChecked   = ($Status -eq 'Active')
        $SegStatusInactive.IsChecked = ($Status -eq 'Inactive')
    }
    finally {
        $Script:FilterSync = $false
    }
}

function Reload-RulesFromSystem {
    try { $Script:AllRules = @(Get-FirewallRules) }
    catch { Show-Toast $_.Exception.Message 'Error'; $Script:AllRules = @() }
}

function Apply-RuleFilters {
    $selectedId = $null
    $sel = Get-SelectedRule
    if ($sel) { $selectedId = $sel.RuleId }

    $filtered = @(Get-FilteredRules)
    $RulesList.ItemsSource = $filtered

    if ($selectedId) {
        $restore = $filtered | Where-Object { $_.RuleId -eq $selectedId } | Select-Object -First 1
        if ($restore) { $RulesList.SelectedItem = $restore }
    }

    Update-EmptyState -FilteredCount $filtered.Count
    Update-Dashboard -Shown $filtered.Count
    Update-ActionBarState
}

function Refresh-RulesList {
    Reload-RulesFromSystem
    Apply-RuleFilters
}

function Get-SelectedRule { return $RulesList.SelectedItem }

function Show-Modal {
    $InpName.Text = ''
    $InpPorts.Text = ''
    $InpRemoteIp.Text = ''
    $InpLocalIp.Text = ''
    $CmbProtocol.SelectedIndex = 0
    $SegInbound.IsChecked = $true; $SegOutbound.IsChecked = $false
    $SegAllow.IsChecked = $true; $SegBlock.IsChecked = $false
    $ChkDomain.IsChecked = $true; $ChkPrivate.IsChecked = $true; $ChkPublic.IsChecked = $true
    $ModalOverlay.Visibility = 'Visible'
    Update-DirectionHint
    $InpName.Focus() | Out-Null
}

function Hide-Modal { $ModalOverlay.Visibility = 'Collapsed' }

function Update-DirectionHint {
    if ($SegOutbound.IsChecked) {
        $TxtDirectionHint.Text = 'Исходящие: фильтрует подключения с вашего компьютера в сеть'
    } else {
        $TxtDirectionHint.Text = 'Входящие: фильтрует подключения извне к вашему компьютеру'
    }
}

function Get-SelectedProfiles {
    $p = @()
    if ($ChkDomain.IsChecked)  { $p += 'Domain' }
    if ($ChkPrivate.IsChecked) { $p += 'Private' }
    if ($ChkPublic.IsChecked)  { $p += 'Public' }
    if ($p.Count -eq 0) { throw 'Выберите хотя бы один профиль сети' }
    return $p
}

function Get-SelectedProtocols {
    $item = $CmbProtocol.SelectedItem
    $sel = if ($item) { [string]$item.Content } else { 'TCP' }
    return @(Resolve-ProtocolSelection $sel)
}

$SegInbound.Add_Checked({ if ($SegInbound.IsChecked) { $SegOutbound.IsChecked = $false; Update-DirectionHint } })
$SegOutbound.Add_Checked({ if ($SegOutbound.IsChecked) { $SegInbound.IsChecked = $false; Update-DirectionHint } })
$SegAllow.Add_Checked({ if ($SegAllow.IsChecked) { $SegBlock.IsChecked = $false } })
$SegBlock.Add_Checked({ if ($SegBlock.IsChecked) { $SegAllow.IsChecked = $false } })

$SegFilterAll.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegFilterAll.IsChecked) { $SegFilterInbound.IsChecked = $false; $SegFilterOutbound.IsChecked = $false; Apply-RuleFilters } })
$SegFilterInbound.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegFilterInbound.IsChecked) { $SegFilterAll.IsChecked = $false; $SegFilterOutbound.IsChecked = $false; Apply-RuleFilters } })
$SegFilterOutbound.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegFilterOutbound.IsChecked) { $SegFilterAll.IsChecked = $false; $SegFilterInbound.IsChecked = $false; Apply-RuleFilters } })

$SegStatusAll.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegStatusAll.IsChecked) { $SegStatusActive.IsChecked = $false; $SegStatusInactive.IsChecked = $false; Apply-RuleFilters } })
$SegStatusActive.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegStatusActive.IsChecked) { $SegStatusAll.IsChecked = $false; $SegStatusInactive.IsChecked = $false; Apply-RuleFilters } })
$SegStatusInactive.Add_Checked({ if ($Script:FilterSync) { return }; if ($SegStatusInactive.IsChecked) { $SegStatusAll.IsChecked = $false; $SegStatusActive.IsChecked = $false; Apply-RuleFilters } })

$TxtSearch.Text = $Script:SearchPlaceholder
$TxtSearch.Foreground = [System.Windows.Media.Brushes]::Gray
$TxtSearch.Add_GotFocus({
    if ($TxtSearch.Text -eq $Script:SearchPlaceholder) { $TxtSearch.Text = ''; $TxtSearch.Foreground = [System.Windows.Media.Brushes]::Black }
})
$TxtSearch.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($TxtSearch.Text)) { $TxtSearch.Text = $Script:SearchPlaceholder; $TxtSearch.Foreground = [System.Windows.Media.Brushes]::Gray }
})
$Script:SearchDebounce.Add_Tick({ $Script:SearchDebounce.Stop(); Apply-RuleFilters })
$TxtSearch.Add_TextChanged({
    $Script:SearchDebounce.Stop()
    $Script:SearchDebounce.Start()
})

$RulesList.Add_SelectionChanged({ Update-ActionBarState })
$RulesList.Add_MouseDoubleClick({
    $rule = Get-SelectedRule
    if (-not $rule) { return }
    try {
        Set-FirewallRuleEnabled -RuleId $rule.RuleId -Enabled (-not $rule.Enabled)
        Reload-RulesFromSystem
        Apply-RuleFilters
    }
    catch { Show-Toast $_.Exception.Message 'Error' }
})

$BtnRefresh.Add_Click({ Refresh-RulesList })
$BtnEmptyAdd.Add_Click({ Show-Modal })
$BtnStatTotal.Add_Click({ Set-FilterPreset; Apply-RuleFilters })
$BtnStatActive.Add_Click({ Set-FilterPreset -Status Active; Apply-RuleFilters })
$BtnStatInactive.Add_Click({ Set-FilterPreset -Status Inactive; Apply-RuleFilters })
$BtnStatOutbound.Add_Click({ Set-FilterPreset -Direction Outbound; Apply-RuleFilters })
$BtnNavBackup.Add_Click({ $BtnExport.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)) })

$BtnAdd.Add_Click({ Show-Modal })
$BtnModalCancel.Add_Click({ Hide-Modal })
$ModalOverlay.Add_MouseLeftButtonDown({ if ($_.OriginalSource -eq $ModalOverlay) { Hide-Modal } })

$BtnModalCreate.Add_Click({
    try {
        $direction = if ($SegInbound.IsChecked) { 'Inbound' } else { 'Outbound' }
        $action    = if ($SegAllow.IsChecked) { 'Allow' } else { 'Block' }
        $created = Add-FirewallRule -Name $InpName.Text.Trim() -Direction $direction -Action $action `
            -Protocols (Get-SelectedProtocols) -Ports $InpPorts.Text.Trim() `
            -RemoteAddress $InpRemoteIp.Text.Trim() -LocalAddress $InpLocalIp.Text.Trim() `
            -Profiles (Get-SelectedProfiles)
        Hide-Modal; Refresh-RulesList
        Show-Toast ('Создано: ' + ($created -join ', ')) 'Success'
    } catch { Show-Toast $_.Exception.Message 'Error' }
})

$BtnEnable.Add_Click({
    $rule = Get-SelectedRule
    if (-not $rule) { Show-Toast 'Сначала выберите правило'; return }
    try { Set-FirewallRuleEnabled -RuleId $rule.RuleId -Enabled $true; Reload-RulesFromSystem; Apply-RuleFilters } catch { Show-Toast $_.Exception.Message 'Error' }
})

$BtnDisable.Add_Click({
    $rule = Get-SelectedRule
    if (-not $rule) { Show-Toast 'Сначала выберите правило'; return }
    try { Set-FirewallRuleEnabled -RuleId $rule.RuleId -Enabled $false; Reload-RulesFromSystem; Apply-RuleFilters } catch { Show-Toast $_.Exception.Message 'Error' }
})

$BtnDelete.Add_Click({
    $rule = Get-SelectedRule
    if (-not $rule) { Show-Toast 'Сначала выберите правило'; return }
    $confirm = [System.Windows.MessageBox]::Show("Удалить правило '$($rule.Name)'?", 'Подтверждение', 'YesNo', 'Warning')
    if ($confirm -ne 'Yes') { return }
    try { Remove-FirewallRule -RuleId $rule.RuleId; Reload-RulesFromSystem; Apply-RuleFilters; Show-Toast 'Правило удалено' 'Success' }
    catch { Show-Toast $_.Exception.Message 'Error' }
})

$BtnExport.Add_Click({
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Filter = 'JSON (*.json)|*.json'
    $dlg.FileName = "FirewallManager_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    if ($dlg.ShowDialog()) {
        try { Export-FirewallRules -Path $dlg.FileName | Out-Null; Show-Toast "Сохранено: $($dlg.FileName)" 'Success' }
        catch { Show-Toast $_.Exception.Message 'Error' }
    }
})

$BtnImport.Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'JSON (*.json)|*.json'
    if ($dlg.ShowDialog()) {
        try {
            $result = Import-FirewallRules -Path $dlg.FileName
            Refresh-RulesList
            Show-Toast "Импортировано: $($result.Imported), пропущено: $($result.Skipped)" 'Success'
        } catch { Show-Toast $_.Exception.Message 'Error' }
    }
})

$window.Add_KeyDown({
    param($sender, $e)
    $ctrl = [System.Windows.Input.Keyboard]::Modifiers -band [System.Windows.Input.ModifierKeys]::Control

    if ($e.Key -eq 'Escape' -and $ModalOverlay.Visibility -eq 'Visible') {
        Hide-Modal
        $e.Handled = $true
        return
    }
    if ($e.Key -eq 'F5') {
        Refresh-RulesList
        $e.Handled = $true
        return
    }
    if ($ctrl -and $e.Key -eq 'N') {
        Show-Modal
        $e.Handled = $true
        return
    }
    if ($ctrl -and $e.Key -eq 'F') {
        $TxtSearch.Focus() | Out-Null
        if ($TxtSearch.Text -eq $Script:SearchPlaceholder) {
            $TxtSearch.Text = ''
            $TxtSearch.Foreground = [System.Windows.Media.Brushes]::Black
        }
        $TxtSearch.SelectAll()
        $e.Handled = $true
        return
    }
    if ($e.Key -eq 'Delete' -and $ModalOverlay.Visibility -ne 'Visible' -and $BtnDelete.IsEnabled) {
        $BtnDelete.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
        $e.Handled = $true
    }
})

$window.Add_Loaded({ $window.Focus() | Out-Null })

Refresh-RulesList
[void]$window.ShowDialog()