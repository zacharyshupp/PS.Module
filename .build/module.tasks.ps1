
# Synopsis: Runs before any task
Enter-Build {
    "Entering Build process"
}

# Synopsis: Alias Task for Build
Add-BuildTask Build Clean, BuildModule, Test

# Synopsis: Clean up the target build directory
Add-BuildTask Clean {

    if ($(Test-Path "$($projectParams.BuildOutputPath)") -eq $true) {
        Remove-Item –Path "$($projectParams.BuildOutputPath)" –Recurse -Force
    }

}

# Synopsis: Build Module
Add-BuildTask BuildModule {

    # Warning on local builds
    if ($Buildtype -ne 'Release') { Write-Warning "Creating a debug build. Use it for test purpose only!" }

    # Create Module Buildoutput Directory
    New-Item -Path $projectParams.BuildModulePath -ItemType Directory -Force | Out-Null

    # Retrieve functions
    $params = @{
        Recurse     = $true
        ErrorAction = "SilentlyContinue"
    }

    $publicFiles = @(Get-ChildItem -Path "$($projectParams.SourcePath)\public\*.ps1" @params)
    $privateFiles = @(Get-ChildItem -Path "$($projectParams.SourcePath)\private\*.ps1" @params)

    # Build PSM1 file with all the functions
    foreach ($file in @($publicFiles + $privateFiles)) {

        $params = @{
            FilePath = $projectParams.BuildModulePSM1Path
            Append   = $true
            Encoding = 'utf8'
            Force    = $true
        }

        Get-Content -Path $($file.fullname) | Out-File @params

    }

    # Create PSD1
    # Build PSD1 file with all the module Information
    $moduleManifestParams = @{
        Author            = $moduleParams.Author
        Description       = $moduleParams.Description
        Copyright         = "(c) $((Get-Date).year) $($moduleParams.Author). All rights reserved."
        Path              = $projectParams.BuildModulePSD1Path
        Guid              = $moduleParams.Guid
        FunctionsToExport = $publicFiles.basename
        VariablesToExport = '*'
        Rootmodule        = "$($moduleParams.ModuleName).psm1"
        ModuleVersion     = '0.1.0'
        LicenseUri        = $moduleParams.LicenseUri
        ProjectUri        = $moduleParams.ProjectUri
        Tags              = $moduleParams.Tags
    }

    New-ModuleManifest @moduleManifestParams

}

# Synopsis: Clean up the target build directory
Add-BuildTask SetBuildEnv {

    Get-ChildItem -Path $projectParams.dependenciesPath -Attributes "directory" | ForEach-Object {

        $module = $_.BaseName
        $modulePath = "{0}\{1}" -f $projectParams.dependenciesPath, $module

        $import = Import-Module $modulePath -PassThru

        "Imported '$module' version '$($import.Version)'"

    }

}

# Synopsis: Invoke Pester for Module Testing
Add-BuildTask Test {

    # Import Pester Module
    Import-Module "$($projectParams.DependenciesPath)\Pester" -Force

    # Configure Pester
    $configuration = [PesterConfiguration]::Default

    $configuration.Run.Path = $projectParams.TestPath
    $configuration.Run.Exit = $true

    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputPath = "$($projectParams.BuildOutputPath)\TestResults.xml"

    $configuration.output.Verbosity = 'Detailed'

    $r = Invoke-Pester -Configuration $configuration

    if ("Failed" -eq $r.Result) { throw "Run failed!" }

    ""
}
