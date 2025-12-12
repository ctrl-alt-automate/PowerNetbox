[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path $PSScriptRoot ".." "PowerNetbox" "PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "Helpers tests" -Tag 'Core', 'Helpers' {
    It "Should throw because we are not connected" {
        InModuleScope -ModuleName 'PowerNetbox' {
            { CheckNetboxIsConnected } | Should -Throw
        }
    }

    Context "Building URIBuilder" {
        BeforeAll {
            # Configure the module's NetboxConfig since BuildNewURI now reads from it directly
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should give a basic URI object" {
            InModuleScope -ModuleName 'PowerNetbox' {
                BuildNewURI -SkipConnectedCheck | Should -BeOfType [System.UriBuilder]
            }
        }

        It "Should generate a URI using configured hostname" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -SkipConnectedCheck
                $URIBuilder.Host | Should -BeExactly 'netbox.domain.com'
                $URIBuilder.Path | Should -BeExactly 'api//'
                $URIBuilder.Scheme | Should -Be 'https'
                $URIBuilder.Port | Should -Be 443
                $URIBuilder.URI.AbsoluteUri | Should -Be 'https://netbox.domain.com/api//'
            }
        }

        It "Should generate a URI with segments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Host | Should -BeExactly 'netbox.domain.com'
                $URIBuilder.Path | Should -BeExactly 'api/seg1/seg2/'
                $URIBuilder.URI.AbsoluteUri | Should -BeExactly 'https://netbox.domain.com/api/seg1/seg2/'
            }
        }

        It "Should generate a URI using HTTP when configured" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.HostScheme = 'http'
                $script:NetboxConfig.HostPort = 80
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Scheme | Should -Be 'http'
                $URIBuilder.Port | Should -Be 80
                $URIBuilder.URI.AbsoluteURI | Should -Be 'http://netbox.domain.com/api/seg1/seg2/'
                # Reset to HTTPS
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should generate a URI on custom port when configured" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.HostPort = 1234
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Scheme | Should -Be 'https'
                $URIBuilder.Port | Should -Be 1234
                $URIBuilder.URI.AbsoluteURI | Should -BeExactly 'https://netbox.domain.com:1234/api/seg1/seg2/'
                # Reset to default port
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should generate a URI with parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIParameters = @{
                    'param1' = 'paramval1'
                }

                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -Parameters $URIParameters -SkipConnectedCheck
                $URIBuilder.Query | Should -Match 'param1=paramval1'
                $URIBuilder.URI.AbsoluteURI | Should -Match 'https://netbox.domain.com/api/seg1/seg2/\?param1=paramval1'
            }
        }
    }

    Context "Building URI components" {
        It "Should give a basic hashtable" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'param1' = 1 }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['param1'] | Should -Be 1
            }
        }

        It "Should add a single ID parameter to the segments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'id' = 123 }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2", '123')
                $URIComponents.Parameters.Count | Should -BeExactly 0
                $URIComponents.Parameters | Should -BeOfType [hashtable]
            }
        }

        It "Should add multiple IDs to the parameters id__in" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'id' = "123", "456" }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['id__in'] | Should -Be '123,456'
            }
        }

        It "Should skip a particular parameter name" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'param1' = 1; 'param2' = 2 } -SkipParameterByName 'param2'

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['param1'] | Should -Be 1
                $URIComponents.Parameters['param2'] | Should -BeNullOrEmpty
            }
        }

        It "Should add a query (q) parameter" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'query' = 'mytestquery' }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['q'] | Should -Be 'mytestquery'
            }
        }

        It "Should generate custom field parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{
                    'CustomFields' = @{
                        'PRTG_Id'     = 1234
                        'Customer_Id' = 'abc'
                    }
                }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 2
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['cf_prtg_id'] | Should -Be '1234'
                $URIComponents.Parameters['cf_customer_id'] | Should -Be 'abc'
            }
        }
    }

    Context "Invoking request tests" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 5 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return [pscustomobject]@{
                    'Method'      = $Method
                    'Uri'         = $Uri
                    'Headers'     = $Headers
                    'Timeout'     = $Timeout
                    'ContentType' = $ContentType
                    'Body'        = $Body
                    'results'     = 'Only results'
                }
            }

            # Configure NetboxConfig for BuildNewURI
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should return direct results instead of the raw request" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder
                $Result | Should -BeOfType [string]
                $Result | Should -BeExactly "Only results"
            }
        }

        It "Should generate a basic request" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Raw
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be $URIBuilder.Uri.AbsoluteUri
                $Result.Headers | Should -BeOfType [System.Collections.HashTable]
                $Result.Headers.Authorization | Should -Be "Token faketoken"
                $Result.ContentType | Should -Be 'application/json'
                $Result.Body | Should -Be $null
            }
        }

        It "Should generate a POST request with body" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Method POST -Body @{
                    'bodyparam1' = 'val1'
                } -Raw
                $Result.Method | Should -Be 'POST'
                $Result.Body | Should -Be '{"bodyparam1":"val1"}'
            }
        }

        It "Should generate a POST request with an extra header" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $Headers = @{
                    'Connection' = 'keep-alive'
                }
                $Body = @{
                    'bodyparam1' = 'val1'
                }
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Method POST -Body $Body -Headers $Headers -Raw
                $Result.Method | Should -Be 'POST'
                $Result.Body | Should -Be '{"bodyparam1":"val1"}'
                $Result.Headers.Count | Should -BeExactly 2
                $Result.Headers.Authorization | Should -Be "Token faketoken"
                $Result.Headers.Connection | Should -Be "keep-alive"
            }
        }

        It "Should throw because of an invalid method" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URI = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                { InvokeNetboxRequest -URI $URI -Method 'Fake' } | Should -Throw
            }
        }

        # NOTE: Timeout validation test removed - InvokeNetboxRequest no longer validates timeout range
    }

    # NOTE: ValidateChoice tests removed - function no longer exists in the module
    # The module now passes values directly to the API without client-side validation
}
