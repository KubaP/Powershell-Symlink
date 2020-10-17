enum SymlinkState {
	True
	False
	NeedsCreation
	NeedsDeletion
	Error
}

class Symlink {
	[string]$Name
	hidden [string]$_Path
	hidden [string]$_Target
	hidden [scriptblock]$_Condition
		
	# Constructor with no creation condition.
	Symlink([string]$name, [string]$path, [string]$target) {
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $null
	}
	
	# Constructor with a creation condition.
	Symlink([string]$name, [string]$path, [string]$target, [scriptblock]$condition) {
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $condition
	}
	
	[string] ShortPath() {
		# Return the path after replacing common variable string.
		$path = $this._Path.Replace($env:APPDATA, "%APPDATA%")
		$path = $path.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
		$path = $path.Replace($env:USERPROFILE, "~")
		return $path
	}
	
	[string] FullPath() {
		# Return the path after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Path)
	}
	
	[string] ShortTarget() {
		# Return the path after replacing common variable string.
		$path = $this._Target.Replace($env:APPDATA, "%APPDATA%")
		$path = $path.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
		$path = $path.Replace($env:USERPROFILE, "~")
		return $path
	}
	
	[string] FullTarget() {
		# Return the target after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Target)
	}
	
	[bool] Exists() {
		# Check if the item even exists.
		if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction Ignore)) {
			return $false
		}
		# Checks if the symlink item and has the correct target.
		if ((Get-Item -Path $this.FullPath() -ErrorAction Ignore).Target -eq $this.FullTarget()) {
			return $true
		}else {
			return $false
		}
	}
	
	[bool] ShouldExist() {
		# If the condition is null, i.e. no condition,
		# assume true by default.
		if ($null -eq $this._Condition) { return $true }
		
		# An if check is here just in case the creation condition doesn't
		# return a boolean, which could cause issues down the line.
		# This is done because the scriptblock can't be validated whether
		# it always returns true/false, since it is not a "proper" method with
		# typed returns.
		if (Invoke-Command -ScriptBlock $this._Condition) {
			return $true
		}
		return $false
	}
	
	[SymlinkState] State() {
		# Return the appropiate state depending on whether the symlink
		# exists and whether it should exist.
		if ($this.Exists() -and $this.ShouldExist()) {
			return [SymlinkState]::True
		}elseif ($this.Exists() -and -not $this.ShouldExist()) {
			return [SymlinkState]::NeedsDeletion
		}elseif (-not $this.Exists() -and $this.ShouldExist()) {
			return [SymlinkState]::NeedsCreation
		}elseif (-not $this.Exists() -and -not $this.ShouldExist()) {
			return [SymlinkState]::False
		}
		return [SymlinkState]::Error
	}
	
	[void] CreateFile() {
		switch ($this.State()) {
			"True" {
				# There is an existing symlink and it points to the correct target.
				Write-Verbose "Existing symbolic-link item is correct. No change required."
				return
			}
			{ $_ -in "NeedsDeletion","False" } {
				# If the symlink condition isn't met, skip creating it.
				Write-Verbose "Skipping the creation of a symbolic-link item, as the creation condition is false."
				return
			}
			"NeedsCreation" {
				# Determine whether there is an item at the location, and if so,
				# whether it's a normal item or a symlink, as they require
				# slightly different logic, and different verbose logging.
				$target = (Get-Item -Path $this.FullPath() -ErrorAction Ignore).Target
				
				if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction Ignore)) {
					# There is no existing item or symlink, so just create the new symlink.
					Write-Verbose "Creating new symbolic-link item on the filesystem."
				}
				elseif ([System.String]::IsNullOrWhiteSpace($target)) {
					# There is an existing item, so remove it.
					Write-Verbose "Creating new symbolic-link item on the filesystem. Deleting existing folder/file first."
					try {
						Remove-Item -Path $this.FullPath() -Force -Recurse
					}
					catch {
						Write-Warning "The existing item could not be deleted. It may be in use by another program."
						Write-Warning "Please close any programs which are accessing files via this folder/file."
						Read-Host -Prompt "Press any key to continue..."
						Remove-Item -Path $this.FullPath() -Force -Recurse
					}
				}
				elseif ($target -ne $this.FullTarget()) {
					# There is an existing symlink, so remove it.
					# Must be done by calling the 'Delete()' method, rather than 'Remove-Item'.
					Write-Verbose "Changing the symbolic-link item target (deleting and re-creating)."
					try {
						(Get-Item -Path $this.FullPath()).Delete()
					}
					catch {
						Write-Warning "The symlink could not be deleted. It may be in use by another program."
						Write-Warning "Please close any programs which are accessing files via this symlink."
						Read-Host -Prompt "Press any key to continue..."
						(Get-Item -Path $this.FullPath()).Delete()
					}
				}
				
				# Create the new symlink.
				New-Item -ItemType SymbolicLink -Force -Path $this.FullPath() -Value $this.FullTarget() | Out-Null
			}
		}
	}
	
	[void] DeleteFile() {
		# Check that the actual symlink item exists first.
		if ($this.Exists()) {
			Write-Verbose "Deleting the symbolic-link item from the filesystem."
			# Loop until the symlink item can be successfuly deleted.
			$state = $true
			while ($state -eq $true) {
				try {
					(Get-Item -Path $this.FullPath()).Delete()
				}
				catch {
					Write-Warning "The symlink: '$($this.Name)' could not be deleted. It may be in use by another program."
					Write-Warning "Please close any programs which are accessing files via this symlink."
					Read-Host -Prompt "Press any key to continue..."
				}
				$state = $this.Exists()
			}
		}
	}
}