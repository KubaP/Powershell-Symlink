Describe "Validating the module manifest" {
	# Get the module manifest and load it into variable.
	$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
	$manifest = ((Get-Content "$moduleRoot\<MODULENAME>.psd1") -join "`n") | Invoke-Expression
	
	# Check that function files are correctly referenced in manifest.
	Context "Basic resources validation" {
		# Get all script files and check that the manifest matches the file locations.
		$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
		
		It "Exports all functions in the public folder" {
			$functions = (Compare-Object -ReferenceObject $files.BaseName `
				-DifferenceObject $manifest.FunctionsToExport | Where-Object SideIndicator -Like '<=').InputObject
			$functions | Should -BeNullOrEmpty
		}
		
		It "Exports no function that isn't also present in the public folder" {
			$functions = (Compare-Object -ReferenceObject $files.BaseName `
				-DifferenceObject $manifest.FunctionsToExport | Where-Object SideIndicator -Like '=>').InputObject
			$functions | Should -BeNullOrEmpty
		}
		
		It "Exports none of its internal functions" {
			$files = Get-ChildItem "$moduleRoot\internal\functions" -Recurse -File -Filter "*.ps1"
			$files | Where-Object BaseName -In $manifest.FunctionsToExport | Should -BeNullOrEmpty	
		}
	}
	
	# Check every other file is correctly referenced in manifest.
	Context "Individual file validation" {
		
		It "The root module file exists" {
			Test-Path "$moduleRoot\$($manifest.RootModule)" | Should -Be $true
		}
		
		# Make sure any format xml definitions exist.
		foreach ($format in $manifest.FormatsToProcess) {
			It "The file $format should exist" {
				Test-Path "$moduleRoot\$format" | Should -Be $true
			}
		}
		
		# Make sure any type xml definitions exist.
		foreach ($type in $manifest.TypesToProcess) {
			It "The file $type should exist" {
				Test-Path "$moduleRoot\$type" | Should -Be $true
			}		
		}
		
		# Make sure any referenced assemblies exist.
		foreach ($assembly in $manifest.RequiredAssemblies) {
            if ($assembly -like "*.dll") {
                It "The file $assembly should exist" {
					Test-Path "$moduleRoot\$assembly" | Should -Be $true
				}
			}
			else {
                It "The file $assembly should load from the GAC" {
					{ Add-Type -AssemblyName $assembly } | Should -Not -Throw
				}
            }
        }
		
		# Make sure tags don't include spaces.
		foreach ($tag in $manifest.PrivateData.PSData.Tags) {
			It "Tags should have no spaces in name" {
				$tag -match " " | Should -Be $false
			}
		}
	}
}