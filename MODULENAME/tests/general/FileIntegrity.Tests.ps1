$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path

# Load the exceptions hashtable.
. "$PSScriptRoot\FileIntegrity.Exceptions.ps1"

function Get-FileEncoding {
	<#
	.SYNOPSIS
		Tests a file for encoding.
	
	.PARAMETER Path
		The file to test.
		
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias('FullName')]
		[string]
		$Path
	)
	
	# Get the byte content of the file.
	if ($PSVersionTable.PSVersion.Major -lt 6) {
		[byte[]]$byte = Get-Content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
	}
	else {
		[byte[]]$byte = Get-Content -AsByteStream -ReadCount 4 -TotalCount 4 -Path $Path
	}
	
	# Test which file encoding is present.
	if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) { 'UTF8 BOM' }
	elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) { 'Unicode' }
	elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) { 'UTF32' }
	elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) { 'UTF7' }
	else { 'Unknown' }
}

Describe "Verifying integrity of module files" {
	
	Context "Validating .ps1 script files" {
		
		# Get all script files in the whole module.
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -like "*.ps1" |
			Where-Object FullName -NotLike "$moduleRoot\tests\*"
		
		# Test each script file.
		foreach ($file in $allFiles) {
			$name = $file.FullName.Replace("$moduleRoot\", '')
			
			# Check if the file has utf8bom encoding.
			It "[$name] Should have UTF8 encoding with Byte Order Mark" {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
			
			$tokens = $null
			$parseErrors = $null
			$ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
			
			# Check that the file has no syntax errors.
			It "[$name] Should have no syntax errors" {
				$parseErrors | Should Be $Null
			}
			
			# Go through every banned command.
			foreach ($command in $global:BannedCommands) {
				# Check if the file being tested has exception from this test.
				if ($global:MayContainCommand["$command"] -notcontains $file.Name) {
					# The command isn't excused, so check that it doesn't use any banned command.
					It "[$name] Should not use $command" {
						$tokens | Where-Object Text -EQ $command | Should -BeNullOrEmpty
					}
				}
			}
		}
	}
	
	Context "Validating .help.txt help files" {
		# Get all help files
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -like "*.help.txt" |
			Where-Object FullName -NotLike "$moduleRoot\tests\*"
		
		# Test each help file.
		foreach ($file in $allFiles) {
			$name = $file.FullName.Replace("$moduleRoot\", '')
			# Check that the file is encoded properly.
			It "[$name] Should have UTF8 encoding" {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
		}
	}
}