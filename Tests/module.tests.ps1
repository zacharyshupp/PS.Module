BeforeDiscovery {

    $moduleName = "PS.Module"

    $moduleBuildPath = "$PSScriptRoot\..\output\$moduleName" | Convert-Path
    $moduleSourcePath = "$PSScriptRoot\..\$moduleName" | Convert-Path
    $functionTestPath = "$PSScriptRoot\..\Tests\functions" | Convert-Path

    $publicFunctions = $(Get-ChildItem -Path "$moduleSourcePath\Public" -Filter "*.ps1" -Recurse).BaseName
    $testFunctions = $(Get-ChildItem -Path $functionTestPath -Filter "*.tests.ps1" -Recurse).BaseName

    Import-Module -Name $moduleBuildPath -Force

    $exportedFunctions = Get-Command -Module $moduleName -All

}

BeforeAll {

    $moduleName = "PS.Module"

    $moduleBuildPath = "$PSScriptRoot\..\output\$moduleName" | Convert-Path

    # Adds Spacing to screen output to make it easier to read.
    Write-Host ""
}

Describe "General Module Control" {

    It "Should Import without Errors" {
        { Import-Module -Name $moduleBuildPath -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Module $moduleName | Should -Not -BeNullOrEmpty
    }

    It "Should Remove without Errors" {
        { Remove-Module -Name $moduleName -ErrorAction Stop } | Should -Not -Throw
        Get-Module $moduleName | Should -BeNullOrEmpty
    }

}

Describe "Module Details" {

    BeforeAll {

        # Import Module
        $moduleDetials = Import-Module -Name $moduleBuildPath -Force -ErrorAction Stop -PassThru

    }

    It "Should contain RootModule" { $moduleDetials.RootModule | Should -Not -BeNullOrEmpty }

    It "Should contain a Author" { $moduleDetials.Author | Should -Not -BeNullOrEmpty }

    It "Should contain a Copyright" { $moduleDetials.Copyright | Should -Not -BeNullOrEmpty }

    It "Should contain a License" { $moduleDetials.LicenseUri | Should -Not -BeNullOrEmpty }

    It "Should contain a Description" { $moduleDetials.Description | Should -Not -BeNullOrEmpty }

    It "Should have equal number of Functions Exported, found ($($exportedFunctions.count) of $($publicFunctions.count))" {
        $exportedFunctions.count | Should -Be $publicFunctions.count
    }

    It "Each function should have a Pester test, found ($($testFunctions.count) of $($publicFunctions.count))" -Tag "TestCases" {
         $testFunctions.count | Should -Be $publicFunctions.count
    }

}
