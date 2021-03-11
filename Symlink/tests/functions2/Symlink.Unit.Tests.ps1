BeforeDiscovery `
{
	# Generate all the possible permutations for the test cases.
	$names = @("test", "", "@#''__/\<>[]...*+-/=?|")
	
	# src1 -> target1
	# src2 -> --target3--
	# --src--
	# %test% -> TestDrive:\
	$srcs = @(
		@{ Path = "TestDrive:\src1"; Short = "TestDrive:\src1"; Full = "TestDrive:\src1"; ValidDir = $true },
		@{ Path = "TestDrive:\src2"; Short = "TestDrive:\src2"; Full = "TestDrive:\src2"; ValidDir = $true },
		@{ Path = "TestDrive:\src"; Short = "TestDrive:\src"; Full = "TestDrive:\src"; ValidDir = $true },
		@{ Path = "C:\Test\src"; Short = "C:\Test\src"; Full = "C:\Test\src"; ValidDir = $false },
		@{ Path = "%none%\src"; Short = "%none%\src"; Full = "%none%\src"; ValidDir = $false }
		@{ Path = "%test%\src1"; Short = "%test%\src1"; Full = "TestDrive:\src1"; ValidDir = $true },
		@{ Path = "NoDrive:\src1"; Short = "NoDrive:\src1"; Full = "NoDrive:\src1"; ValidDir = $false },
		
		@{ Path = "$env:APPDATA\src1"; Short = "%APPDATA%\src1"; Full = "$env:APPDATA\src1"; ValidDir = $true },
		@{ Path = "$env:LOCALAPPDATA\src1"; Short = "%LOCALAPPDATA%\src1"; Full = "$env:LOCALAPPDATA\src1"; ValidDir = $true },
		@{ Path = "$env:HOME\src1"; Short = "~\src1"; Full = "$env:HOME\src1"; ValidDir = $true }
	)
	$targets = @(
		@{ Path = "TestDrive:\target1"; Short = "TestDrive:\target1"; Full = "TestDrive:\target1"; Valid = $true },
		@{ Path = "TestDrive:\target2"; Short = "TestDrive:\target2"; Full = "TestDrive:\target2"; Valid = $true },
		@{ Path = "TestDrive:\target3"; Short = "TestDrive:\target3"; Full = "TestDrive:\target3"; Valid = $false },
		
		@{ Path = "%test%\target1"; Short = "%test%\target1"; Full = "TestDrive:\target1"; Valid = $true },
		@{ Path = "%test%\target2"; Short = "%test%\target2"; Full = "TestDrive:\target2"; Valid = $true },
		@{ Path = "%test%\target3"; Short = "%test%\target3"; Full = "TestDrive:\target3"; Valid = $false },
		
		@{ Path = "%none%\target1"; Short = "%none%\target1"; Full = "%none%\target1"; Valid = $false },
		@{ Path = "%none%\target2"; Short = "%none%\target2"; Full = "%none%\target2"; Valid = $false },
		@{ Path = "%none%\target3"; Short = "%none%\target3"; Full = "%none%\target3"; Valid = $false },
		
		@{ Path = "NoDrive:\target1"; Short = "NoDrive:\target1"; Full = "NoDrive:\target1"; Valid = $false },
		@{ Path = "NoDrive:\target2"; Short = "NoDrive:\target2"; Full = "NoDrive:\target2"; Valid = $false },
		@{ Path = "NoDrive:\target3"; Short = "NoDrive:\target3"; Full = "NoDrive:\target3"; Valid = $false },
		
		@{ Path = "$env:APPDATA\target1"; Short = "%APPDATA%\target1"; Full = "$env:APPDATA\target1"; Valid = $false },
		@{ Path = "$env:LOCALAPPDATA\target2"; Short = "%LOCALAPPDATA%\target2"; Full = "$env:LOCALAPPDATA\target2"; Valid = $false },
		@{ Path = "$env:HOME\target3"; Short = "~\target3"; Full = "$env:HOME\target3"; Valid = $false }
	)
	
	$itemCombinations = @(
		@{ Src = $srcs[0]; Target = $targets[0]; SrcState = "Existent"; TargetState = "Valid" },
		@{ Src = $srcs[0]; Target = $targets[1]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[0]; Target = $targets[2]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[0]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[1]; Target = $targets[1]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[1]; Target = $targets[2]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[0]; SrcState = "Nonexistent"; TargetState = "Valid" },
		@{ Src = $srcs[2]; Target = $targets[1]; SrcState = "Nonexistent"; TargetState = "Valid" },
		@{ Src = $srcs[2]; Target = $targets[2]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[0]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[3]; Target = $targets[1]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[3]; Target = $targets[2]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[0]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[4]; Target = $targets[1]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[4]; Target = $targets[2]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[0]; SrcState = "Existent"; TargetState = "Valid" },
		@{ Src = $srcs[5]; Target = $targets[1]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[5]; Target = $targets[2]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[0]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[6]; Target = $targets[1]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[6]; Target = $targets[2]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		
		@{ Src = $srcs[7]; Target = $targets[12]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[7]; Target = $targets[13]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[7]; Target = $targets[14]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[8]; Target = $targets[12]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[8]; Target = $targets[13]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[8]; Target = $targets[14]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[9]; Target = $targets[12]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[9]; Target = $targets[13]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[9]; Target = $targets[14]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		
		@{ Src = $srcs[0]; Target = $targets[3]; SrcState = "Existent"; TargetState = "Valid" },
		@{ Src = $srcs[0]; Target = $targets[4]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[0]; Target = $targets[5]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[3]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[1]; Target = $targets[4]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[1]; Target = $targets[5]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[3]; SrcState = "Nonexistent"; TargetState = "Valid" },
		@{ Src = $srcs[2]; Target = $targets[4]; SrcState = "Nonexistent"; TargetState = "Valid" },
		@{ Src = $srcs[2]; Target = $targets[5]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[3]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[3]; Target = $targets[4]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[3]; Target = $targets[5]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[3]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[4]; Target = $targets[4]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[4]; Target = $targets[5]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[3]; SrcState = "Existent"; TargetState = "Valid" },
		@{ Src = $srcs[5]; Target = $targets[4]; SrcState = "IncorrectTarget"; TargetState = "Valid" },
		@{ Src = $srcs[5]; Target = $targets[5]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[3]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[6]; Target = $targets[4]; SrcState = "CannotValidate"; TargetState = "Valid" },
		@{ Src = $srcs[6]; Target = $targets[5]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		
		@{ Src = $srcs[0]; Target = $targets[6]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[0]; Target = $targets[7]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[0]; Target = $targets[8]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[6]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[7]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[8]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[6]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[7]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[8]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[6]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[7]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[8]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[6]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[7]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[8]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[6]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[7]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[8]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[6]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[7]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[8]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		
		@{ Src = $srcs[0]; Target = $targets[9]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[0]; Target = $targets[10]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[0]; Target = $targets[11]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[9]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[10]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[1]; Target = $targets[11]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[9]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[10]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[2]; Target = $targets[11]; SrcState = "Nonexistent"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[9]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[10]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[3]; Target = $targets[11]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[9]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[10]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[4]; Target = $targets[11]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[9]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[10]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[5]; Target = $targets[11]; SrcState = "UnknownTarget"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[9]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[10]; SrcState = "CannotValidate"; TargetState = "Invalid" },
		@{ Src = $srcs[6]; Target = $targets[11]; SrcState = "CannotValidate"; TargetState = "Invalid" }
	)
	
	$conditions = @($null, { return $true }, { return $false })
	
	$testCases = @()
	
	# Generate all the possible permutations for the test cases.
	foreach ($name in $names)
	{
		foreach ($combination in $itemCombinations)
		{
			foreach ($condition in $conditions)
			{
				$testCases += @{
					Name = $name
					Path = $combination.Src.Path
					ShortPath = $combination.Src.Short
					FullPath = $combination.Src.Full
					ValidPath = $combination.Src.ValidDir
					SourceState = $combination.SrcState
					Target = $combination.Target.Path
					ShortTarget = $combination.Target.Short
					FullTarget = $combination.Target.Full
					ValidTarget = $combination.Target.Valid
					TargetState = $combination.TargetState
					Condition = $condition
				}
			}
		}
	}
}

BeforeAll `
{
	# Instead of importing the module, which will not give access to the class itself, dot source the class to
	# have access to the type to allow for unit testing.
	. "$PSScriptRoot\..\..\internal\classes\Symlink.ps1"
}

Describe "[Symlink]" -Tag "Internal", "Unit" `
{
	Context "Valid signature" -Tag "Valid", "NoIssue" -Foreach $testCases `
	{
		BeforeAll `
		{
			New-Item -Path "TestDrive:\" -Name "target1" -ItemType Directory
			New-Item -Path "TestDrive:\" -Name "target2" -ItemType Directory
			New-Item -Path "TestDrive:\" -Name "target3" -ItemType Directory
			New-Item -Path "TestDrive:\" -Name "src1" -Value (Convert-Path "TestDrive:\target1") -ItemType SymbolicLink
			New-Item -Path "TestDrive:\" -Name "src2" -Value (Convert-Path "TestDrive:\target3") -ItemType SymbolicLink
			Remove-Item -Path "TestDrive:\target3" -Force
			
			$env:TEST = "TestDrive:"
		}
		
		It "3-argument Constructor" `
		{
			$obj = [Symlink]::new($name, $path, $target)
			
			# Ensure the object was correctly initialised.
			$obj.Name | Should -Be $name
			$obj._Path | Should -Be $path
			$obj._Target | Should -Be $target
			$obj._Condition | Should -BeNullOrEmpty
			
			# Ensure that the methods of the object are returning correct results.
			$obj.ShortPath() | Should -Be $shortPath
			$obj.ShortTarget() | Should -Be $shortTarget
			$obj.FullPath() | Should -Be $fullpath
			$obj.FullTarget() | Should -Be $fullTarget
			$obj.IsValidPathDirectory() | Should -Be $validPath
			$obj.IsValidTarget() | Should -Be $validTarget
			$obj.GetSourceState() | Should -Be $sourceState
			$obj.GetTargetState() | Should -Be $targetState
			$obj.ShouldExist() | Should -Be $true -Because "no condition was specified"
		}
		
		It "4-argument Constructor" `
		{
			$obj = [Symlink]::new($name, $path, $target, $condition)

			# Ensure the object was correctly initialised.
			$obj.Name | Should -Be $name
			$obj._Path | Should -Be $path
			$obj._Target | Should -Be $target
			$obj._Condition | Should -Be $condition
			
			# Ensure that the methods of the object are returning correct results.
			$obj.ShortPath() | Should -Be $shortPath
			$obj.ShortTarget() | Should -Be $shortTarget
			$obj.FullPath() | Should -Be $fullpath
			$obj.FullTarget() | Should -Be $fullTarget
			$obj.IsValidPathDirectory() | Should -Be $validPath
			$obj.IsValidTarget() | Should -Be $validTarget
			$obj.GetSourceState() | Should -Be $sourceState
			$obj.GetTargetState() | Should -Be $targetState
			if (-not $condition)
			{
				$obj.ShouldExist() | Should -Be $true -Because "no condition was specified"
			}
			else
			{
				if (Invoke-Command -ScriptBlock $condition)
				{
					$obj.ShouldExist() | Should -Be $true
				}
				else
				{
					$obj.ShouldExist() | Should -Be $false
				}	
			}
		}
		
		AfterAll `
		{
			Remove-Item -Path "Env:\TEST"
		}
	}
	
	Context "Invalid Signature" -Tag "Invalid", "HaltingIssue" `
	{
		Context "0-argument constructor" `
		{
			It "Empty" `
			{
				try
				{
					$obj = [Symlink]::new()
				}
				catch
				{
					$_ | Should -Not -BeNullOrEmpty -Because "this is an invalid constructor"
				}
				finally
				{
					$obj | Should -BeNullOrEmpty -Because "this is an invalid constructor"
				}
			}
		}
		
		Context "1-argument constructor" `
		{
			It "Correct Types" `
			{
				try
				{
					$obj = [Symlink]::new("test")
				}
				catch
				{
					$_ | Should -Not -BeNullOrEmpty -Because "this is an invalid constructor"
				}
				finally
				{
					$obj | Should -BeNullOrEmpty -Because "this is an invalid constructor"
				}
			}
			
			It "Incorrect Types" `
			{
				try
				{
					$obj = [Symlink]::new(213)
				}
				catch
				{
					$_ | Should -Not -BeNullOrEmpty -Because "this is an invalid constructor"
				}
				finally
				{
					$obj | Should -BeNullOrEmpty -Because "this is an invalid constructor"
				}
			}
		}
		
		Context "2-argument constructor" `
		{
			It "Correct Types" `
			{
				try
				{
					$obj = [Symlink]::new("test", "some\path")
				}
				catch
				{
					$_ | Should -Not -BeNullOrEmpty -Because "this is an invalid constructor"
				}
				finally
				{
					$obj | Should -BeNullOrEmpty -Because "this is an invalid constructor"
				}
			}
			
			It "Incorrect Types" `
			{
				try
				{
					$obj = [Symlink]::new(213, { return $true })
				}
				catch
				{
					$_ | Should -Not -BeNullOrEmpty -Because "this is an invalid constructor"
				}
				finally
				{
					$obj | Should -BeNullOrEmpty -Because "this is an invalid constructor"
				}
			}
		}
	}
}
