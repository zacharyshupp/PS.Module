BeforeDiscovery {
    $cmdName = "Get-Something"
}

BeforeAll {

    # Load Module if its not loaded.
    $cmdName = "Get-Something"
    $moduleName = "PS.Module"
    $modulePath = "$PSScriptRoot\..\..\output\$moduleName" | Convert-Path

    if (-Not(Get-Module -Name $moduleName)) { Import-Module $modulePath -Force }

    $command = Get-Command -Name "Get-Something" -All
    $help = Get-Help -Name "Get-Something"
    $verb = $command.Verb
    $ast = $command.ScriptBlock.Ast

}

Describe "$cmdName" {

    Context "Function Details" {

        It "Should use an approved Verb" { ( $verb -in @( Get-Verb ).Verb ) | Should -Be $true }

        It "[CmdletBinding()] should exist" {
            [boolean]( @( $ast.FindAll( { $true } , $true ) ) | Where-Object { $_.TypeName.Name -eq 'cmdletbinding' } ) | Should -Be $true
        }

        It "Should have help information" { $help | Should -Not -BeNullOrEmpty }

        It "Should have a Synopsis" { ( $command.ScriptBlock -match '.SYNOPSIS' ) | Should -Be $true }

        It "Should have a descrription" {
            ([string]::IsNullOrEmpty($help.description.Text)) | Should -Be $false
        }

        It "Should have at least one example" { [boolean]( $help.examples ) | Should -Be $true }

    }

}
