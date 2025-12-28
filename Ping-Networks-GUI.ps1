#requires -Version 5.0

<#
.SYNOPSIS
    GUI interface for Ping-Networks network scanning tool.

.DESCRIPTION
    Windows Presentation Foundation (WPF) GUI for the Ping-Networks tool.
    Provides a user-friendly interface for configuring and running network scans,
    monitoring progress in real-time, and viewing results.

.NOTES
    Version: 2.0.0
    Requires PowerShell 5.0 or later and .NET Framework
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# XAML for the main window
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Ping-Networks v2.0 - Network Scanner GUI"
    Height="700"
    Width="900"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanResize">

    <Window.Resources>
        <!-- Styles -->
        <Style TargetType="GroupBox">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="BorderBrush" Value="#667eea"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style TargetType="Button">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Background" Value="#667eea"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#764ba2"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="5,2"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>

        <Style TargetType="Label">
            <Setter Property="Margin" Value="5,2"/>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="5,2"/>
            <Setter Property="Padding" Value="5"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
    </Window.Resources>

    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#667eea" Padding="15" Margin="0,0,0,10">
            <StackPanel>
                <TextBlock Text="🌐 Ping-Networks" FontSize="24" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Network Scanner &amp; Analysis Tool" FontSize="12" Foreground="White" Opacity="0.9"/>
            </StackPanel>
        </Border>

        <!-- Input Configuration -->
        <GroupBox Grid.Row="1" Header="Input Configuration">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="100"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Label Grid.Row="0" Grid.Column="0" Content="Input File:"/>
                <TextBox Grid.Row="0" Grid.Column="1" Name="txtInputPath" IsReadOnly="True"/>
                <Button Grid.Row="0" Grid.Column="2" Name="btnBrowseInput" Content="Browse..." Width="100"/>

                <Label Grid.Row="1" Grid.Column="0" Content="Output Dir:"/>
                <TextBox Grid.Row="1" Grid.Column="1" Name="txtOutputPath"/>
                <Button Grid.Row="1" Grid.Column="2" Name="btnBrowseOutput" Content="Browse..." Width="100"/>
            </Grid>
        </GroupBox>

        <!-- Output Formats -->
        <GroupBox Grid.Row="2" Header="Output Formats">
            <StackPanel Orientation="Horizontal">
                <CheckBox Name="chkExcel" Content="Excel (.xlsx)" IsChecked="True"/>
                <CheckBox Name="chkHtml" Content="HTML" IsChecked="True"/>
                <CheckBox Name="chkJson" Content="JSON"/>
                <CheckBox Name="chkXml" Content="XML"/>
                <CheckBox Name="chkCsv" Content="CSV"/>
            </StackPanel>
        </GroupBox>

        <!-- Scan Parameters -->
        <GroupBox Grid.Row="3" Header="Scan Parameters">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Column 1 -->
                <StackPanel Grid.Row="0" Grid.Column="0">
                    <Label Content="Throttle (concurrent pings):"/>
                    <TextBox Name="txtThrottle" Text="50"/>

                    <Label Content="Max Pings per Network:"/>
                    <TextBox Name="txtMaxPings" Text=""/>
                </StackPanel>

                <!-- Column 2 -->
                <StackPanel Grid.Row="0" Grid.Column="1">
                    <Label Content="Timeout (seconds):"/>
                    <TextBox Name="txtTimeout" Text="1"/>

                    <Label Content="Retries:"/>
                    <TextBox Name="txtRetries" Text="0"/>
                </StackPanel>

                <!-- Column 3 -->
                <StackPanel Grid.Row="0" Grid.Column="2">
                    <Label Content="Ping Count:"/>
                    <TextBox Name="txtCount" Text="1"/>

                    <CheckBox Name="chkCheckpoint" Content="Enable Checkpoints"/>
                </StackPanel>

                <!-- Advanced Options Toggle -->
                <StackPanel Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="3" Margin="0,10,0,0">
                    <CheckBox Name="chkShowAdvanced" Content="Show Advanced Options"/>
                    <StackPanel Name="pnlAdvanced" Visibility="Collapsed" Margin="0,10,0,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0">
                                <Label Content="Buffer Size (bytes):"/>
                                <TextBox Name="txtBufferSize" Text="32"/>

                                <Label Content="TTL:"/>
                                <TextBox Name="txtTTL" Text="128"/>
                            </StackPanel>

                            <StackPanel Grid.Column="1">
                                <CheckBox Name="chkHistoryPath" Content="Enable Scan History"/>
                                <CheckBox Name="chkTrendReport" Content="Generate Trend Report" IsEnabled="False"/>
                            </StackPanel>
                        </Grid>

                        <!-- Database Options -->
                        <Separator Margin="0,15,0,10"/>
                        <Label Content="Database Export:" FontWeight="Bold"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0">
                                <CheckBox Name="chkDatabaseExport" Content="Export to Database"/>
                                <CheckBox Name="chkInitializeDatabase" Content="Initialize DB Schema" IsEnabled="False"/>
                            </StackPanel>

                            <StackPanel Grid.Column="1">
                                <Label Content="Database Type:"/>
                                <ComboBox Name="cmbDatabaseType" SelectedIndex="0" IsEnabled="False">
                                    <ComboBoxItem Content="SQL Server"/>
                                    <ComboBoxItem Content="MySQL"/>
                                    <ComboBoxItem Content="PostgreSQL"/>
                                </ComboBox>
                            </StackPanel>
                        </Grid>

                        <Label Content="Connection String:"/>
                        <TextBox Name="txtConnectionString" IsEnabled="False"
                                 Text="Server=localhost;Database=PingNetworks;Integrated Security=True"/>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </GroupBox>

        <!-- Progress and Results -->
        <GroupBox Grid.Row="4" Header="Scan Progress &amp; Results">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <ProgressBar Grid.Row="0" Name="progressBar" Height="30" Margin="5"/>
                <TextBlock Grid.Row="1" Name="txtStatus" Text="Ready to scan" Margin="5" FontStyle="Italic"/>

                <DataGrid Grid.Row="2" Name="dgResults" AutoGenerateColumns="False"
                          IsReadOnly="True" Margin="5" CanUserAddRows="False">
                    <DataGrid.Columns>
                        <DataGridTextColumn Header="Network" Binding="{Binding Network}" Width="150"/>
                        <DataGridTextColumn Header="Host" Binding="{Binding Host}" Width="130"/>
                        <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="100"/>
                        <DataGridTextColumn Header="Hostname" Binding="{Binding Hostname}" Width="*"/>
                    </DataGrid.Columns>
                </DataGrid>
            </Grid>
        </GroupBox>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="btnStart" Content="▶ Start Scan" Width="120" FontWeight="Bold"/>
            <Button Name="btnStop" Content="⏹ Stop" Width="100" IsEnabled="False"/>
            <Button Name="btnClear" Content="Clear Results" Width="120"/>
            <Button Name="btnExit" Content="Exit" Width="100" Background="#999"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtInputPath = $window.FindName("txtInputPath")
$txtOutputPath = $window.FindName("txtOutputPath")
$btnBrowseInput = $window.FindName("btnBrowseInput")
$btnBrowseOutput = $window.FindName("btnBrowseOutput")

$chkExcel = $window.FindName("chkExcel")
$chkHtml = $window.FindName("chkHtml")
$chkJson = $window.FindName("chkJson")
$chkXml = $window.FindName("chkXml")
$chkCsv = $window.FindName("chkCsv")

$txtThrottle = $window.FindName("txtThrottle")
$txtMaxPings = $window.FindName("txtMaxPings")
$txtTimeout = $window.FindName("txtTimeout")
$txtRetries = $window.FindName("txtRetries")
$txtCount = $window.FindName("txtCount")
$txtBufferSize = $window.FindName("txtBufferSize")
$txtTTL = $window.FindName("txtTTL")

$chkCheckpoint = $window.FindName("chkCheckpoint")
$chkHistoryPath = $window.FindName("chkHistoryPath")
$chkTrendReport = $window.FindName("chkTrendReport")
$chkShowAdvanced = $window.FindName("chkShowAdvanced")
$pnlAdvanced = $window.FindName("pnlAdvanced")

$chkDatabaseExport = $window.FindName("chkDatabaseExport")
$chkInitializeDatabase = $window.FindName("chkInitializeDatabase")
$cmbDatabaseType = $window.FindName("cmbDatabaseType")
$txtConnectionString = $window.FindName("txtConnectionString")

$progressBar = $window.FindName("progressBar")
$txtStatus = $window.FindName("txtStatus")
$dgResults = $window.FindName("dgResults")

$btnStart = $window.FindName("btnStart")
$btnStop = $window.FindName("btnStop")
$btnClear = $window.FindName("btnClear")
$btnExit = $window.FindName("btnExit")

# Global variables
$script:scanJob = $null
$script:scanResults = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$dgResults.ItemsSource = $script:scanResults

# Set default output path
$txtOutputPath.Text = [Environment]::GetFolderPath('MyDocuments')

# Event Handlers

# Browse Input File
$btnBrowseInput.Add_Click({
    $openFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $openFileDialog.Filter = "Supported Files (*.xlsx;*.csv;*.txt)|*.xlsx;*.csv;*.txt|Excel Files (*.xlsx)|*.xlsx|CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $openFileDialog.Title = "Select Network Input File"

    if ($openFileDialog.ShowDialog()) {
        $txtInputPath.Text = $openFileDialog.FileName
    }
})

# Browse Output Directory
$btnBrowseOutput.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select Output Directory"
    $folderBrowser.SelectedPath = $txtOutputPath.Text

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtOutputPath.Text = $folderBrowser.SelectedPath
    }
})

# Show/Hide Advanced Options
$chkShowAdvanced.Add_Checked({
    $pnlAdvanced.Visibility = [System.Windows.Visibility]::Visible
})

$chkShowAdvanced.Add_Unchecked({
    $pnlAdvanced.Visibility = [System.Windows.Visibility]::Collapsed
})

# Enable/Disable Trend Report based on History
$chkHistoryPath.Add_Checked({
    $chkTrendReport.IsEnabled = $true
})

$chkHistoryPath.Add_Unchecked({
    $chkTrendReport.IsEnabled = $false
    $chkTrendReport.IsChecked = $false
})

# Enable/Disable Database Options based on Database Export
$chkDatabaseExport.Add_Checked({
    $chkInitializeDatabase.IsEnabled = $true
    $cmbDatabaseType.IsEnabled = $true
    $txtConnectionString.IsEnabled = $true
})

$chkDatabaseExport.Add_Unchecked({
    $chkInitializeDatabase.IsEnabled = $false
    $cmbDatabaseType.IsEnabled = $false
    $txtConnectionString.IsEnabled = $false
})

# Start Scan
$btnStart.Add_Click({
    # Validation
    if ([string]::IsNullOrWhiteSpace($txtInputPath.Text)) {
        [System.Windows.MessageBox]::Show("Please select an input file.", "Validation Error",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if (-not (Test-Path $txtInputPath.Text)) {
        [System.Windows.MessageBox]::Show("Input file does not exist.", "File Not Found",
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    # Build command arguments as hashtable for proper splatting
    $arguments = @{
        InputPath = $txtInputPath.Text
        OutputDirectory = $txtOutputPath.Text
    }

    # Output formats (switches use $true)
    if ($chkExcel.IsChecked) { $arguments['Excel'] = $true }
    if ($chkHtml.IsChecked) { $arguments['Html'] = $true }
    if ($chkJson.IsChecked) { $arguments['Json'] = $true }
    if ($chkXml.IsChecked) { $arguments['Xml'] = $true }
    if ($chkCsv.IsChecked) { $arguments['Csv'] = $true }

    # Parameters
    if (![string]::IsNullOrWhiteSpace($txtThrottle.Text)) {
        $arguments['Throttle'] = [int]$txtThrottle.Text
    }
    if (![string]::IsNullOrWhiteSpace($txtMaxPings.Text)) {
        $arguments['MaxPings'] = [int]$txtMaxPings.Text
    }
    if (![string]::IsNullOrWhiteSpace($txtTimeout.Text)) {
        $arguments['Timeout'] = [int]$txtTimeout.Text
    }
    if (![string]::IsNullOrWhiteSpace($txtRetries.Text)) {
        $arguments['Retries'] = [int]$txtRetries.Text
    }
    if (![string]::IsNullOrWhiteSpace($txtCount.Text)) {
        $arguments['Count'] = [int]$txtCount.Text
    }

    # Advanced parameters
    if ($chkShowAdvanced.IsChecked) {
        if (![string]::IsNullOrWhiteSpace($txtBufferSize.Text)) {
            $arguments['BufferSize'] = [int]$txtBufferSize.Text
        }
        if (![string]::IsNullOrWhiteSpace($txtTTL.Text)) {
            $arguments['TimeToLive'] = [int]$txtTTL.Text
        }
    }

    # Checkpoint
    if ($chkCheckpoint.IsChecked) {
        $checkpointPath = Join-Path $txtOutputPath.Text "Checkpoints"
        $arguments['CheckpointPath'] = $checkpointPath
    }

    # History
    if ($chkHistoryPath.IsChecked) {
        $historyPath = Join-Path $txtOutputPath.Text "History"
        $arguments['HistoryPath'] = $historyPath

        if ($chkTrendReport.IsChecked) {
            $arguments['GenerateTrendReport'] = $true
        }
    }

    # Database Export
    if ($chkDatabaseExport.IsChecked) {
        $arguments['DatabaseExport'] = $true
        $arguments['DatabaseConnectionString'] = $txtConnectionString.Text

        # Map ComboBox selection to database type
        $dbType = switch ($cmbDatabaseType.SelectedIndex) {
            0 { 'SQLServer' }
            1 { 'MySQL' }
            2 { 'PostgreSQL' }
            default { 'SQLServer' }
        }
        $arguments['DatabaseType'] = $dbType

        if ($chkInitializeDatabase.IsChecked) {
            $arguments['InitializeDatabase'] = $true
        }
    }

    # Clear previous results
    $script:scanResults.Clear()
    $progressBar.Value = 0
    $txtStatus.Text = "Starting scan..."

    # Disable controls
    $btnStart.IsEnabled = $false
    $btnStop.IsEnabled = $true

    # Get script path
    $scriptPath = Join-Path $PSScriptRoot "Ping-Networks.ps1"

    # Start scan in background job
    $script:scanJob = Start-Job -ScriptBlock {
        param($ScriptPath, $Arguments)
        & $ScriptPath @Arguments
    } -ArgumentList $scriptPath, $arguments

    # Start monitoring timer
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)

    $timer.Add_Tick({
        if ($script:scanJob.State -eq "Running") {
            # Update status (simplified - actual implementation would parse job output)
            $txtStatus.Text = "Scanning networks..."

            # Pulse progress bar
            if ($progressBar.IsIndeterminate -eq $false) {
                $progressBar.IsIndeterminate = $true
            }
        }
        elseif ($script:scanJob.State -eq "Completed") {
            $this.Stop()

            # Get results
            $output = Receive-Job -Job $script:scanJob

            $progressBar.IsIndeterminate = $false
            $progressBar.Value = 100
            $txtStatus.Text = "Scan completed successfully!"

            # Enable controls
            $btnStart.IsEnabled = $true
            $btnStop.IsEnabled = $false

            [System.Windows.MessageBox]::Show("Scan completed successfully!`nResults saved to: $($txtOutputPath.Text)",
                "Scan Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

            Remove-Job -Job $script:scanJob
        }
        elseif ($script:scanJob.State -eq "Failed") {
            $this.Stop()

            $progressBar.IsIndeterminate = $false
            $txtStatus.Text = "Scan failed!"

            # Enable controls
            $btnStart.IsEnabled = $true
            $btnStop.IsEnabled = $false

            $error = Receive-Job -Job $script:scanJob 2>&1 | Out-String
            [System.Windows.MessageBox]::Show("Scan failed with error:`n$error",
                "Scan Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)

            Remove-Job -Job $script:scanJob
        }
    })

    $timer.Start()
})

# Stop Scan
$btnStop.Add_Click({
    if ($script:scanJob) {
        Stop-Job -Job $script:scanJob
        Remove-Job -Job $script:scanJob -Force

        $progressBar.IsIndeterminate = $false
        $progressBar.Value = 0
        $txtStatus.Text = "Scan stopped by user"

        $btnStart.IsEnabled = $true
        $btnStop.IsEnabled = $false
    }
})

# Clear Results
$btnClear.Add_Click({
    $script:scanResults.Clear()
    $progressBar.Value = 0
    $txtStatus.Text = "Ready to scan"
})

# Exit
$btnExit.Add_Click({
    if ($script:scanJob -and $script:scanJob.State -eq "Running") {
        $result = [System.Windows.MessageBox]::Show("A scan is currently running. Do you want to stop it and exit?",
            "Confirm Exit", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)

        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            Stop-Job -Job $script:scanJob
            Remove-Job -Job $script:scanJob -Force
            $window.Close()
        }
    }
    else {
        $window.Close()
    }
})

# Add System.Windows.Forms for FolderBrowserDialog
Add-Type -AssemblyName System.Windows.Forms

# Show window
$window.ShowDialog() | Out-Null
