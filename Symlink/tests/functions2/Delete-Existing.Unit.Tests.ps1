BeforeAll `
{
	# Import the specific requirements for this test.
	. "$PSScriptRoot\..\..\internal\functions\Delete-Existing.ps1"
}

Describe "Delete-Existing" -Tag "Internal", "Unit" `
{
	BeforeEach `
	{
		New-Item -Path "TestDrive:\" -Name "target1" -ItemType Directory
		"This is a string" | Out-File -FilePath "TestDrive:\file1"
		"This is a string" | Out-File -FilePath "TestDrive:\target1\file1"
		New-Item -Path "TestDrive:\" -Name "src1" -Value (Convert-Path -Path "TestDrive:\target1") -ItemType SymbolicLink
	}
	
	It "Non-blocking" -Tag "Valid", "NoIssue" -Foreach @(
		@{Path = "TestDrive:\src1"},
		@{Path = "TestDrive:\file1"},
		@{Path = "TestDrive:\src2"},
		@{Path = "TestDrive:\target1"}
	) `
	{
		$return = Delete-Existing -Path $path
		$return | Should -Be $true
		(Test-Path -Path $path) | Should -Be $false
	}
	
	It "Blocking" -Tag "Valid", "HaltingIssue" -Foreach @(
		#@{Path = "TestDrive:\src1"; File = "TestDrive:\src1\file1"}, # Opening a file through a symlink; can still delete symlink itself though.
		@{Path = "TestDrive:\file1"; File = "TestDrive:\file1"},
		@{Path = "TestDrive:\target1"; File = "TestDrive:\target1\file1"}
	) `
	{
		# Open the file (permanently).
		$fs = [System.IO.File]::Open((Convert-Path -Path $file), "Open", "ReadWrite", "None")
		$return = Delete-Existing -Path $path
		$return | Should -Be $false -Because "the item is open"
		# Free-up the file.
		$fs.Close()
		(Test-Path -Path $path) | Should -Be $true
	}
	
	AfterEach `
	{
		Remove-Item -Path "TestDrive:\target1" -Force -Recurse -ErrorAction Ignore
		Remove-Item -Path "TestDrive:\file1" -Force -Recurse -ErrorAction Ignore
		if (Test-Path -Path "TestDrive:\src1")
		{
			(Get-Item -Path "TestDrive:\src1").Delete()
		}
	}
}