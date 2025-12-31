# PSScriptAnalyzer Settings for PowerNetbox
# https://github.com/ctrl-alt-automate/PowerNetbox

@{
    # Analyze all severity levels
    Severity = @('Error', 'Warning', 'Information')

    # Rules to include
    IncludeRules = @(
        # Error prevention
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfAssignmentOperator',
        'PSPossibleIncorrectUsageOfRedirectionOperator',
        'PSMisleadingBacktick',
        'PSAvoidAssignmentToAutomaticVariable',

        # Best practices
        'PSUseApprovedVerbs',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseOutputTypeCorrectly',

        # Code quality
        'PSAvoidTrailingWhitespace',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidGlobalVars',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText',

        # Documentation
        'PSProvideCommentHelp'
    )

    # Rules to exclude with reasoning
    ExcludeRules = @(
        # Write-Host is only used in test/debug scripts, not in module functions
        'PSAvoidUsingWriteHost',

        # Some endpoints genuinely have plural nouns (e.g., VLANs, ASNs)
        'PSUseSingularNouns'
    )

    # Rule-specific settings
    Rules = @{
        # Require comment-based help for exported functions
        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'begin'
        }

        # Consistent indentation (4 spaces)
        PSUseConsistentIndentation = @{
            Enable          = $true
            IndentationSize = 4
            Kind            = 'space'
        }

        # Consistent whitespace
        PSUseConsistentWhitespace = @{
            Enable                                  = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckSeparator                          = $true
            CheckInnerBrace                         = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $false
            CheckParameter                          = $false
            IgnoreAssignmentOperatorInsideHashTable = $true
        }

        # Align assignment statements
        PSAlignAssignmentStatement = @{
            Enable         = $false
            CheckHashtable = $false
        }

        # Brace placement (same line)
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        # Compatibility rules for cross-platform support
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0', '7.4')
        }
    }
}
