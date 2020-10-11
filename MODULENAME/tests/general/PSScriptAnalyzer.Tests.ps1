[CmdletBinding()]
Param (
	
	# Skips all PSScriptAnalyzer tests.
	[switch]
	$SkipTest,
	
	# Paths in which the files to be tested are located.
	# By default, tests all public and internal functions.
	[string[]]
	$CommandPath = @("$PSScriptRoot\..\..\functions", "$PSScriptRoot\..\..\internal\functions")
	
)

if ($SkipTest) { return }

$list = New-Object System.Collections.ArrayList

Describe 'Invoking PSScriptAnalyzer against commandbase' {
	
	# Get all script files to be tested.
	$commandFiles = Get-ChildItem -Path $CommandPath -Recurse | Where-Object Name -like "*.ps1"
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule
	
	foreach ($file in $commandFiles) {
		Context "Analyzing $($file.BaseName)" {
			# Run psscriptanalyzer on each file.
			$analysis = Invoke-ScriptAnalyzer -Path $file.FullName `
				-ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess, PSAvoidUsingWriteHost
			
			# Check that the file passes all rules.
			foreach ($rule in $scriptAnalyzerRules) {
				It "Should pass $rule" {
					If ($analysis.RuleName -contains $rule) {
						$analysis | Where-Object RuleName -EQ $rule -OutVariable failures |
							ForEach-Object { $list.Add($_) }						
						1 | Should Be 0
					}else {
						0 | Should Be 0
					}
				}
			}
		}
	}
}

$list | Out-Default