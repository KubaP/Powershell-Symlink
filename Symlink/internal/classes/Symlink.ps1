enum SymlinkState
{
	Exists
	NotExists
	NeedsCreation
	NeedsDeletion
	Error
}

class Symlink
{
	[string]$Name
	hidden [string]$_Path
	hidden [string]$_Target
	hidden [scriptblock]$_Condition
		
	# Constructor with no creation condition.
	Symlink([string]$name, [string]$path, [string]$target)
	{
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $null
	}
	
	# Constructor with a creation condition.
	Symlink([string]$name, [string]$path, [string]$target, [scriptblock]$condition)
	{
		$this.Name = $name
		$this._Path = $path
		$this._Target = $target
		$this._Condition = $condition
	}
	
	[string] ShortPath()
	{
		# Return the path after replacing common variable string.
		$path = $this._Path.Replace("$env:APPDATA\", "%APPDATA%\")
		$path = $path.Replace("$env:LOCALAPPDATA\", "%LOCALAPPDATA%\")
		$path = $path.Replace("$env:USERPROFILE\", "~\")
		return $path
	}
	
	[string] FullPath()
	{
		# Return the path after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Path)
	}
	
	[string] ShortTarget()
	{
		# Return the path after replacing common variable string.
		$path = $this._Target.Replace($env:APPDATA, "%APPDATA%")
		$path = $path.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
		$path = $path.Replace($env:USERPROFILE, "~")
		return $path
	}
	
	[string] FullTarget()
	{
		# Return the target after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Target)
	}
	
	[bool] Exists()
	{
		# Check if the item even exists.
		if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction Ignore))
		{
			return $false
		}
		# Checks if the symlink item exists and has the correct target.
		if ((Get-Item -Path $this.FullPath() -ErrorAction Ignore).Target -eq $this.FullTarget())
		{
			return $true
		}
		else
		{
			return $false
		}
	}
	
	[bool] ShouldExist()
	{
		# If the condition is null, i.e. no condition,
		# assume true by default.
		if ($null -eq $this._Condition) { return $true }
		
		# An if check is here just in case the creation condition doesn't
		# return a boolean, which could cause issues down the line.
		# This is done because the scriptblock can't be validated whether
		# it always returns true/false, since it is not a "proper" method with
		# typed returns.
		if (Invoke-Command -ScriptBlock $this._Condition)
		{
			return $true
		}
		return $false
	}
	
	[SymlinkState] GetState()
	{
		# Return the appropiate state depending on whether the symlink
		# exists and whether it should exist.
		if ($this.Exists() -and $this.ShouldExist())
		{
			return [SymlinkState]::Exists
		}
		elseif ($this.Exists() -and -not $this.ShouldExist()) 
		{
			return [SymlinkState]::NeedsDeletion
		}
		elseif (-not $this.Exists() -and $this.ShouldExist())
		{
			return [SymlinkState]::NeedsCreation
		}
		elseif (-not $this.Exists() -and -not $this.ShouldExist())
		{
			return [SymlinkState]::NotExists
		}
		return [SymlinkState]::Error
	}
}