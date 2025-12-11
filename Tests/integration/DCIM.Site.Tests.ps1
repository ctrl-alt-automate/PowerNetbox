#
# Copyright 2021, Alexis La Goutte <alexis dot lagoutte at gmail dot com>
#
# SPDX-License-Identifier: Apache-2.0
#
. "$PSScriptRoot/../common.ps1"

BeforeAll {
    Connect-NBAPI @invokeParams
}

Describe "Get (DCIM) Site" {

    BeforeAll {
        New-NBDCIMSite -name $pester_site1
    }

    It "Get Site Does not throw an error" {
        {
            Get-NBDCIMSite
        } | Should -Not -Throw
    }

    It "Get ALL Site" {
        $site = Get-NBDCIMSite
        $site.count | Should -Not -Be $NULL
    }

    It "Get Site ($pester_site1)" {
        $site = Get-NBDCIMSite | Where-Object { $_.name -eq $pester_site1 }
        $site.id | Should -Not -BeNullOrEmpty
        $site.name | Should -Be $pester_site1
        $site.status.value | Should -Be "active"
    }

    It "Search Site by name ($pester_site1)" {
        $site = Get-NBDCIMSite -name $pester_site1
        @($site).count | Should -Be 1
        $site.id | Should -Not -BeNullOrEmpty
        $site.name | Should -Be $pester_site1
    }

    AfterAll {
        Get-NBDCIMSite -name $pester_site1 | Remove-NBDCIMSite -confirm:$false
    }
}

Describe "New (DCIM) Site" {

    It "New Site with no option" {
        New-NBDCIMSite -name $pester_site1
        $site = Get-NBDCIMSite -name $pester_site1
        $site.id | Should -Not -BeNullOrEmpty
        $site.name | Should -Be $pester_site1
        $site.slug | Should -Be $pester_site1
    }

    It "New Site with different slug" {
        New-NBDCIMSite -name $pester_site1 -slug pester_slug
        $site = Get-NBDCIMSite -name $pester_site1
        $site.id | Should -Not -BeNullOrEmpty
        $site.name | Should -Be $pester_site1
        $site.slug | Should -Be "pester_slug"
    }

    AfterEach {
        Get-NBDCIMSite -name $pester_site1 | Remove-NBDCIMSite -confirm:$false
    }
}

Describe "Remove Site" {

    BeforeEach {
        New-NBDCIMSite -name $pester_site1
    }

    It "Remove Site" {
        $site = Get-NBDCIMSite -name $pester_site1
        Remove-NBDCIMSite -id $site.id -confirm:$false
        $site = Get-NBDCIMSite -name $pester_site1
        $site | Should -BeNullOrEmpty
        @($site).count | Should -Be 0
    }

}