@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'NetworkScanner.psm1'

    # Version number of this module.
    ModuleVersion = '2.3.0'

    # Author of this module
    Author = 'Slade Bennett'

    # Copyright statement for this module
    Copyright = '(c) Slade Bennett 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Network scanning and host discovery module with subnet calculation, parallel ping operations, and hostname resolution.'

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-UsableHosts',
        'Invoke-HostPing',
        'ConvertFrom-NetworkInput',
        'Get-IPRange'
    )

    # Cmdlets to export from this module
    CmdletsToExport = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = '*'

    # List of nested modules to be imported into the module namespace
    NestedModules = @(
        'ExcelUtils.psm1'
    )
}
