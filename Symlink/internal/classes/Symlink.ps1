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
	
	[bool] IsValidPathDirectory()
	{
		# Remove the leaf of the path, as that part is the name the symbolic-link should take,
		# and the link may not be created. This does not invalidate the parent path however, as the parent path
		# must be valid for the link to exist in the first place.
		$parentPath = Split-Path -Path $this.FullPath() -Parent
		
		# Now test that this path to the parent is valid. If this path is valid, then the symbolic link
		# item can be successfully created.
		return Test-Path -Path $parentPath
	}
	
	[bool] IsValidTarget()
	{
		# Test that the target is valid. If any of the parent folders do not exist, or if any environmental 
		# variables are used which do not exist, this will return false.
		return Test-Path -Path $this.FullTarget()
	}
	
	[string] GetSourceState()
	{
		if (-not $this.IsValidPathDirectory())
		{
			# Part of the path for where the symbolic-link exists cannot be resolved correctly, either because of
			# missing folders or because of a use of an environment variable not present on the system.
			# Since the path cannot be validated, its unknown if the symbolic link item exists correctly or not.
			return "CannotValidate"
		}
		
		if (-not (Get-Item -Path $this.FullPath() -ErrorAction Ignore))
		{
			# The parent part of the path is valid, but the actual symbolic-link item does not exist.
			return "Nonexistent"
		}
		
		if (-not $this.IsValidTarget())
		{
			# The target is invalid, so the symbolic-link item exists but it's unknown if the target it points to
			# doesn't exist or if the target it points to cannot be resolved.
			return "UnknownTarget"
		}
		
		if ((Get-Item -Path $this.FullPath()).Target -eq $this.FullTarget())
		{
			# The target of the symbolic-link matches the stored target.
			return "Existent"
		}
		else
		{
			# The target of the symbolic-link does not match the stored target (may have changed).
			return "IncorrectTarget"
		}
		
		return "Unknown"
	}
	
	[string] GetTargetState()
	{
		if (-not $this.IsValidTarget())
		{
			# The target path cannot be resolved, because either the folders don't properly exist, or because the
			# system lacks an environmental variable for resolving.
			return "Invalid"
		}
		
		return "Valid"
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
}