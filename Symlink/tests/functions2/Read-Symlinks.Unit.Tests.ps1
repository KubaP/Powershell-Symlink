BeforeAll `
{
	# Import the specific requirements for this test.
	. "$PSScriptRoot\..\..\internal\classes\Symlink.ps1"
	. "$PSScriptRoot\..\..\internal\functions\Read-Symlinks.ps1"
}

Describe "Read-Symlinks" -Tag "Internal", "Unit" `
{
	Context "Valid data" -Tag "Valid" `
	{
		It "1 object" `
		{
			$script:DataPath = "$PSScriptRoot\..\data\database-valid-1.xml"
			$objs = Read-Symlinks
			$objs.Count | Should -Be 1 -Because "there is only 1 defined symlink in this data set"
			
			$obj = $objs[0]
			$obj.Name | Should -Be "test"
			$obj._Path | Should -Be "C:\Users\Kuba\Desktop\src1"
			$obj._Target | Should -Be "C:\Users\Kuba\Desktop\target1"
			$obj._Condition | Should -BeNullOrEmpty
		}
		
		It "Multiple objects" `
		{
			$script:DataPath = "$PSScriptRoot\..\data\database-valid-3.xml"
			$objs = Read-Symlinks
			$objs.Count | Should -Be 3 -Because "there are 3 defined symlinks in this data set"
			
			$obj = $objs[0]
			$obj.Name | Should -Be "test"
			$obj._Path | Should -Be "C:\Users\Kuba\Desktop\src1"
			$obj._Target | Should -Be "C:\Users\Kuba\Desktop\target1"
			$obj._Condition | Should -BeNullOrEmpty
			
			$obj = $objs[1]
			$obj.Name | Should -Be "test2"
			$obj._Path | Should -Be "C:\Users\Kuba\Desktop\src1"
			$obj._Target | Should -Be "C:\Users\Kuba\Desktop\target3"
			$obj._Condition.ToString() | Should -Be "return `$true"
			
			$obj = $objs[2]
			$obj.Name | Should -Be "test3"
			$obj._Path | Should -Be "C:\Users\Kuba\Desktop\src1"
			$obj._Target | Should -Be "C:\Users\Kuba\Desktop\target3"
			$obj._Condition.ToString() | Should -Be "return `$false"
		}
	}
	
	Context "Invalid data" -Tag "Invalid" `
	{
		It "Invalid formatting" `
		{
			$script:DataPath = "$PSScriptRoot\..\data\database-invalid-formatting.xml"
			$objs = Read-Symlinks -ErrorAction SilentlyContinue -ErrorVariable err
			
			# Its $err[2] because when the `Import-Clixml` cmdlet errors, it adds its errors to the $err log output.
			# The error has to be printed, i.e. cannot do '-ErrorAction Ignore' because otherwise the try-catch
			# block will not catch the error.
			$err[2] | Should -Not -BeNullOrEmpty -Because "an error should be thrown"
			$err[2].Exception.Message | Should -Match "Could not load the .xml database file. Could it be corrupted?"
			
			$objs | Should -BeNullOrEmpty -Because "the function should have returned early"
		}
		
		It "Invalid object; lack of '<_>'" -Foreach @("Name", "Path", "Target", "Condition") `
		{
			$script:DataPath = "$PSScriptRoot\..\data\database-invalid-object-$_.xml"
			$objs = Read-Symlinks -ErrorAction SilentlyContinue -ErrorVariable err
			
			$err | Should -Not -BeNullOrEmpty -Because "an error should be thrown"
			$err.Exception.Message | Should -Match "A \[Symlink\] object does not have a $_ property. Could the file have been modified externally?"
			
			$objs | Should -BeNullOrEmpty
		}
	}
}