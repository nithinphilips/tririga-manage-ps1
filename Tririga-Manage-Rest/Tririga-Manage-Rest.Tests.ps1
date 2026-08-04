# https://pester.dev/docs/quick-start

BeforeAll {
    $env:PSModulePath = "$(Resolve-Path $PSScriptRoot\..)" + [IO.Path]::PathSeparator + $env:PSModulePath
    Import-Module Tririga-Manage-Rest -Force
    Import-Module Tririga-Manage -Force

    $VerbosePreference = "Continue"

    function Get-ModTestConfiguration1() {
        @{
            "TEST" = @{
                Warn = $False;
                Username = "system";
                Password = "badadmin";
                Servers = @{
                    "ONE" = @{
                        Url = "http://localhost:9080"
                        ApiUrl = "http://localhost:9080"
                    }
                }
            }
        }
    }
}

Describe 'Get-TririgaEnvironment' {
  It "It lists all environments" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaEnvironment
    $output | Should -Be "Known environments are: TEST"
  }
  It "It returns a raw output" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $expected = Get-ModTestConfiguration1
    $actual = Get-TririgaEnvironment -Raw
    Assert-Equivalent -Actual $actual -Expected $expected
  }
}

Describe 'Get-TririgaInstance' {
  It "It lists all instance" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaInstance
    $output | Should -Be "TEST environment: ONE"
  }
  It "It lists one environment's instances" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaInstance TEST
    $output | Should -Be "TEST environment: ONE"
  }
  It "It returns a raw output" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $expected = Get-ModTestConfiguration1
    $actual = Get-TririgaInstance -Raw
    Assert-Equivalent -Actual $actual -Expected $expected
  }
  It "It returns a raw output for one environment's instances" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    $expected = (Get-ModTestConfiguration1)["TEST"]
    $actual = Get-TririgaInstance TEST -Raw
    Assert-Equivalent -Actual $actual -Expected $expected
  }
}


Describe 'Get-TririgaBuildNumber' {
  It "It lists all instance" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    Mock -ModuleName Tririga-Manage-Rest GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaBuildNumber TEST
    $output | Should -Not -Be $null
    $output.buildNumber | Should -Not -Be $null
  }
}

Describe 'Get-TririgaAgent' {
  It "It lists all agents" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    Mock -ModuleName Tririga-Manage-Rest GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaAgent TEST
    $output | Should -Not -Be $null
    $output.count | Should -BeGreaterThan 0
  }
}

Describe 'Get-TririgaCacheMode' {
  It "It gets the current cache mode" {
    Mock -ModuleName Tririga-Manage GetConfiguration { Get-ModTestConfiguration1 }
    Mock -ModuleName Tririga-Manage-Rest GetConfiguration { Get-ModTestConfiguration1 }
    $output = Get-TririgaCacheMode TEST
    $output | Should -Not -Be $null
    $output | Should -Be "AA"
  }
}
