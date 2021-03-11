BeforeAll `
{
}

Import-Module -Name "$PSScriptRoot\..\..\Symlink.psd1" -Force

Describe "Get-Symlink" -Tag "Acceptance" `
{
	InModuleScope Symlink `
	{
		BeforeAll `
		{
			# Set-up the temporary data path.
			$script:DataPath = "$PSScriptRoot\..\data\database-valid-3.xml"
		}
		
		Context "Valid parameters" -Tag "Valid" `
		{
			It "Name '<_>'" -Foreach @("test", "test2", "Atest3") `
			{
				$obj = Get-Symlink -Name $_
				# Ensure only one object is outputted, and it's of the correct type.
				$obj | Should -Not -BeNullOrEmpty
				$obj.GetType() | Should -Be "Symlink"
				$obj.Name | Should -Be $_
			}
			
			It "Names 'test, test2, Atest3'" `
			{
				$objs = Get-Symlink -Names "test", "test2", "Atest3"
				$objs | Should -Not -BeNullOrEmpty
				$objs.Length | Should -Be 3 -Because "multiple names are provided"
				# Ensure all the objects are of the correct type.
				foreach ($obj in $objs)
				{
					$obj.GetType() | Should -Be "Symlink"
				}
				# Ensure the output is correctly sorted by name.
				$objs[0].Name | Should -Be "Atest3"
				$objs[1].Name | Should -Be "test"
				$objs[2].Name | Should -Be "test2"
			}
			
			It "All" `
			{
				$objs = Get-Symlink -All
				$objs | Should -Not -BeNullOrEmpty
				$objs.Length | Should -Be 3 -Because "multiple names are provided"
				# Ensure all the objects are of the correct type.
				foreach ($obj in $objs)
				{
					$obj.GetType() | Should -Be "Symlink"
				}
				# Ensure the output is correctly sorted by name.
				$objs[0].Name | Should -Be "Atest3"
				$objs[1].Name | Should -Be "test"
				$objs[2].Name | Should -Be "test2"
			}
		}
		
		Context "Invalid parameters" -Tag "Invalid" `
		{
			It "Name '<_>'" -Foreach @("testasd", "@~::__+_+__+\``n", " ") `
			{
				Mock Write-Warning {}
				$obj = Get-Symlink -Name $_
				$obj | Should -BeNullOrEmpty
				
				Assert-MockCalled -CommandName "Write-Warning" -Times 1 -ParameterFilter {$Message -eq "There is no symlink named: '$_'."}
			}
			
			It "No name" `
			{
				try
				{
					$obj = Get-Symlink -Names $null
				}
				catch
				{
					$err = $_
				}
				$err | Should -Not -BeNullOrEmpty
				$err.Exception.Message | Should -Be "Cannot bind argument to parameter 'Names' because it is null."
			}
			
			It "Name and All" `
			{
				try
				{
					$obj = Get-Symlink -Names "test" -All
				}
				catch
				{
					$err = $_
				}
				$err | Should -Not -BeNullOrEmpty
				$err.Exception.Message | Should -Be "Parameter set cannot be resolved using the specified named parameters. One or more parameters issued cannot be used together or an insufficient number of parameters were provided."
			}
		}
		
		It "Verifying parameters" `
		{
			(Get-Command "Get-Symlink").Parameters["Names"].Attributes.Mandatory | Should -Be $true
			(Get-Command "Get-Symlink").Parameters["Names"].Attributes.Position | Should -Be 0
			(Get-Command "Get-Symlink").Parameters["Names"].Attributes.ValueFromPipelineByPropertyName | Should -Be $true
			
			(Get-Command "Get-Symlink").Parameters["All"].Attributes.Mandatory | Should -Be $true
			(Get-Command "Get-Symlink").Parameters["All"].Attributes.Position | Should -Be 0
		}
	}
}