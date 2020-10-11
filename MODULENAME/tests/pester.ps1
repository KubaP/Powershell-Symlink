param (
	# Whether to run general tests.
	$TestGeneral = $true,
	
	# Whether to run individual function tests.
	$TestFunctions = $true,
	
	# Controls how much verbose output pester shows during running.
	# WARNING: Running Invoke-Pester with -Show 'None' doesn't generate a code
	# coverage report properly; seems like a bug.
	[ValidateSet('Default', 'Passed', 'Failed', 'Pending', 'Skipped', 'Inconclusive', 'Describe', 'Context', 'Summary', 'Header', 'Fails', 'All')]
	$Show = "Describe",
	
	# TODO: re-add filter logic
	# Files to include.
	$Include = "*",
	
	# File to exclude.
	$Exclude = ""
)

# Remove and re-import the module.
Write-Host "Starting tests. Importing the module." -ForegroundColor Cyan
Remove-Module <MODULENAME> -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\<MODULENAME>.psd1" -Verbose
Import-Module "$PSScriptRoot\..\<MODULENAME>.psm1" -Force -Verbose

# Create the test results directory.
Write-Host "Creating the test result folder." -ForegroundColor Cyan
New-Item -Path "$PSScriptRoot\..\.." -Name "TestResults" -ItemType Directory -Force | Out-Null

# Keep count of test statistics.
$totalFailed = 0
$totalRun = 0
$failedTestResults = @()

# Run general tests.
# Since some of these tests run on the whole codebase, code coverage results
# would be pointless so they're not done
if ($TestGeneral) {
	Write-Host "Running general tests." -ForegroundColor Cyan
	
	# Run through every test file located in \general\
	foreach ($file in (Get-ChildItem "$PSScriptRoot\general" | Where-Object Name -like "*.Tests.ps1")) {
		Write-Host "`tExecuting $($file.Name)."
		
		# Run the tests and save pester output to variable.
		$TestOutputFile = "$PSScriptRoot\..\..\TestResults\TEST-General-$($file.BaseName).xml"
		$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru -OutputFile $TestOutputFile `
			-OutputFormat NUnitXml
		
		foreach ($result in $results) {
			# Add the test results to counter.
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			
			# If a test fails, add it to the list.
			$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
				$name = $_.Name
				$failedTestResults += [pscustomobject]@{
					Name	 = "It $name"
					Describe = $_.Describe
					Context  = $_.Context
					Result   = $_.Result
					Message  = $_.FailureMessage
				}
			}
		}
	}
}

# Run individual function test.
if ($TestFunctions -eq $true) {
	Write-Host "Running individual tests." -ForegroundColor Cyan
		
	# Get list of all functions being tested, for code coverage calculations
	$functionFiles = Get-ChildItem -Path "$PSScriptRoot\..\functions\" -Recurse -Include "*.ps1"
	$functionFiles += Get-ChildItem -Path "$PSScriptRoot\..\internal\functions\" -Recurse -Include "*.ps1"
	
	# Run all function tests.
	$results = Invoke-Pester -Script "$PSScriptRoot\functions\*" -PassThru -Show $Show `
		-CodeCoverage $functionFiles.FullName -CodeCoverageOutputFile "$PSScriptRoot\..\..\TestResults\CodeCov-Functions.xml" `
			-OutputFile "$PSScriptRoot\..\..\TestResults\TEST-Functions.xml" -OutputFormat NUnitXml
	
	foreach ($result in $results) {
		# Add the test results to counter.
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		
		# If a test fails, add it to the list.
		$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
			$name = $_.Name
			$failedTestResults += [pscustomobject]@{
				Name	 = "It $name"
				Describe = $_.Describe
				Context  = $_.Context
				Result   = $_.Result
				Message  = $_.FailureMessage
			}
		}
	}
}

# Show all failed test results in detail.
$failedTestResults | Sort-Object Describe, Context, Name, Result, Message | Format-List

# Display a message at the end.
if ($totalFailed -eq 0) {
	Write-Host "All $totalRun tests executed without a single failure." -ForegroundColor Green
}else { 
	Write-Host "$totalFailed tests out of $totalRun tests failed!" -ForegroundColor Red
}

# Throw an error if any tests failed/
if ($totalFailed -gt 0) {
	throw "$totalFailed / $totalRun tests failed!"
}