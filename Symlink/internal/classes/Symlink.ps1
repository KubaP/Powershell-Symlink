function ShortenPath([string] $path)
{
	return $path.Replace("$env:APPDATA\", "%APPDATA%\").Replace("$env:LOCALAPPDATA\", "%LOCALAPPDATA%\").Replace("$env:USERPROFILE\", "~\").Replace("$env:HOME\", "~\")
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
		return ShortenPath($this._Path)
	}
	
	[string] FullPath()
	{
		# Return the path after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Path)
	}
	
	[string] ShortTarget()
	{
		# Return the path after replacing common variable string.
		return ShortenPath($this._Target)
	}
	
	[string] FullTarget()
	{
		# Return the target after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Target)
	}
	
	[bool] IsValidPathDirectory()
	{
		# Remove the leaf of the path, as that part is the name the symbolic-link should take,
		# and the link may not yet be created. This does not invalidate the parent path however, as the parent path
		# must be valid for the link to exist in the first place.
		$parentPath = Split-Path -Path $this.FullPath() -Parent
		
		# Now test that the parent path is valid. Firstly, convert a relative path to an absolute one, i.e.
		#	if a PSDrive "Test" exists with a root at "C:\Users\Kuba\Desktop",
		#	convert "Test\link" to "C:\Users\Kuba\Desktop\link"
		# The conversion (using 'Convert-Path') must be done in a try-catch since if a PSDrive doesn't exist,
		# the cmdlet will throw an error, and that would cause 'Test-Path' to thrown an error, which in turn
		# wouldn't return the a correct boolean value.
		try
		{
			$parentPath = Convert-Path -Path $parentPath -ErrorAction Stop
		}
		catch
		{
			return $false
		}
		return (Test-Path -Path $parentPath)
	}
	
	[bool] IsValidTarget()
	{
		# Test that the target is valid. If any of the parent folders do not exist, or if any environmental 
		# variables are used which do not exist, this will return false.
		# Firstly however, convert the path to an absolute one (see above for explanation).
		try
		{
			$targetPath = Convert-Path -Path $this.FullTarget() -ErrorAction Stop
		}
		catch
		{
			return $false
		}
		return (Test-Path -Path $targetPath)
	}
	
	[string] GetSourceState()
	{
		if (-not $this.IsValidPathDirectory())
		{
			# Part of the path for where the symbolic-link exists cannot be resolved correctly, either because of
			# missing folders, or because of a use of an environment variable not present on the system,
			# or bacause of a use of a PSDrive which cannot be converted to an absolute path (i.e. doesn't exist).
			# Since the path cannot be validated, its unknown if the symbolic link item exists correctly or not.
			return "CannotValidate"
		}
		
		# As the parent directory path was successfully validated, we now need to convert the entire path
		# (in case it does require conversion). The issue is that the symbolic-link item may not exist, which will
		# make 'Convert-Path' fail. Therefore, we need to only convert the parent portion of the path, and then
		# join it back together.
		$parent = Split-Path -Path $this.FullPath() -Parent
		$leaf = Split-Path -Path $this.FullPath() -Leaf
		$parent = Convert-Path -Path $parent
		$path = Join-Path -Path $parent -ChildPath $leaf
		
		if (-not (Get-Item -Path $path -ErrorAction Ignore))
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
		
		if ((Get-Item -Path $path).Target -eq (Convert-Path -Path $this.FullTarget()))
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