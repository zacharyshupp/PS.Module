<#
  .SYNOPSIS
    Module Build Bootstrap Script

  .DESCRIPTION
    <Brief description of script>

  .EXAMPLE
    <Example goes here. Repeat this attribute for more than one example>

  .NOTES
    Change Log:
      1.0.0 - 1/17/2021
          * Initial script development

#>

# [Script Parameters] ---------------------------------------------------------------------------------------------

[CmdletBinding()]
param (

    # Specifies if the build is for a release or not. Default is Debug for general development.
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('Debug', 'Release')]
    [String]
    $BuildType = 'Debug',

    # Specifies the Tasks to run.
    [Parameter()]
    [ValidateSet(
        "SetBuildEnv",
        "Build",
        "Test",
        "Clean"
    )]
    [string[]]
    $Task,

    # Specifies the powershell gallery to use.
    [Parameter()]
    [string]
    $GalleryRepository = "PSGallery",

    # Specifies the gallery credentials to use if one is required.
    [Parameter()]
    [pscredential]
    $GalleryCredential,

    # Specifies the Proxy to use if one is required.
    [Parameter()]
    [string]
    $GalleryProxy,

    # Specifies if the Dependencies should be installed.
    [Parameter()]
    [switch]
    $InstallDependencies

)

# [Initialisations] -----------------------------------------------------------------------------------------------


# [Functions] -----------------------------------------------------------------------------------------------------

# < Add Imbedded functions, delete section if unused. >

# [Declarations] --------------------------------------------------------------------------------------------------

# Module Specific Variables
$moduleParams = @{
    ModuleName  = "PS.Module"
    Guid        = "21f4165b-61f3-4dd6-b1ca-858e6bcdf8f3"
    Author      = "Zachary Shupp"
    Description = "PowerShell module ..."
    ProjectUri = "https://github.com/zacharyshupp/PS.Module" # get from module of from source control, env var
    LicenseUri = "https://github.com/zacharyshupp/PS.Module/blob/main/LICENSE.md"
    Tags       = @('Module')
}

# Required Modules for Build
$requredModules = @{
    BuildHelpers = 'Latest'
    Pester       = 'Latest'
}

# Project Specific Variables
$projectParams = @{
    ProjectRoot         = "$PSScriptRoot"
    DependenciesPath    = "$PSScriptRoot\Dependencies"
    BuildtaskPath       = "$PSScriptRoot\.build\module.tasks.ps1"
    BuildOutputPath     = "$PSScriptRoot\Output"
    BuildModulePath     = "$PSScriptRoot\Output\$($moduleParams.ModuleName)"
    BuildModulePSM1Path = "$PSScriptRoot\Output\$($moduleParams.ModuleName)\$($moduleParams.ModuleName)`.psm1"
    BuildModulePSD1Path = "$PSScriptRoot\Output\$($moduleParams.ModuleName)\$($moduleParams.ModuleName)`.psd1"
    SourcePath          = "$PSScriptRoot\$($moduleParams.ModuleName)"
    TestPath            = "$PSScriptRoot\Tests"
}

# [Execution] -----------------------------------------------------------------------------------------------------

if ($InstallDependencies) {

    # Remove Dependecies directory if it already exists.
    if ((Test-Path -Path $projectParams.dependenciesPath) -eq $true) {

        Remove-Item -Path $projectParams.dependenciesPath -Recurse -Force -Confirm:$false

    }

    # Setup PSrepository
    if (-not(Get-PackageProvider -Name NuGet -ForceBootstrap)) {

        $providerBootstrapParams = @{
            Name           = 'nuget'
            force          = $true
            ForceBootstrap = $true
        }

        if ($PSBoundParameters['verbose']) { $providerBootstrapParams.add('verbose', $verbose) }

        if ($GalleryProxy) { $providerBootstrapParams.Add('Proxy', $GalleryProxy) }

        $null = Install-PackageProvider @providerBootstrapParams

        Set-PSRepository -Name $GalleryRepository -InstallationPolicy Trusted

    }

    # Install Modules
    $requredModules.GetEnumerator() | ForEach-Object {

        Write-Verbose "Found '$($_.Key)' with a value of '$($_.Value)'"

        $gallaryParams = @{
            Name        = $_.Key
            Force       = $true
            Path        = $projectParams.dependenciesPath
            ErrorAction = 'Stop'
        }

        if ($_.Value -ne 'Latest') { $gallaryParams.Add('RequiredVersion', $_.Value) }

        Save-Module @gallaryParams

    }

}

if ($Task) {

    # Start build using InvokeBuild module
    Write-Verbose -Message "Start Build (using InvokeBuild module)"
    Invoke-Build -Result 'Result' -File $projectParams.buildtaskPath -Task $Task

    # Return error to CI
    if ($Result.Error) {
        $Error[-1].ScriptStackTrace | Out-String
        exit 1
    }

    exit 0

}
