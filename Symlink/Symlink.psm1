# Create some global variables.
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\Symlink.psd1").ModuleVersion
$script:DataPath = "$env:APPDATA\Powershell\Symlink\database.xml"

Write-Debug "`e[4mMODULE-WIDE VARIABLES`e[0m"
Write-Debug "Module root folder: $($script:ModuleRoot)"
Write-Debug "Module version: $($script:ModuleVersion)"
Write-Debug "Database file: $($script:DataPath)"

# Create the module data-storage folder if it doesn't exist.
if (-not (Test-Path -Path "$env:APPDATA\Powershell\Symlink" -ErrorAction Ignore)) {
	New-Item -ItemType Directory -Path "$env:APPDATA" -Name "Powershell\Symlink" -Force -ErrorAction Stop
	
	Write-Debug "Created database folder!"
}

# Detect whether at some level dot-sourcing was enforced.
# Dot-sourcing can be enforced by either:
#	- A global variable 'ModuleDebugDotSource' set in the current shell.
#	- Setting the variable to true.
$doDotSource = $global:ModuleDebugDotSource
#$doDotSource = $true # Needed to make code coverage tests work

# TODO: Rewrite this and build script so that the packaged module *only*
# TODO: contains the compiled code, and it **can't** import individual files.
# The issue (I think?) is that in the packaged module, this file contains the 
# [Symlink] class definition, and when Import-Module is run, this file is AST
# analysed for any structs which then get loaded (but this script is **not**
# ran).
#
# When a command is actually used however, this script gets run for the first
# time and then it can decide to import files individually, and then it ends up
# importing the class definition (now for the second time). And this is
# *probably* the issue.
#
# So as a fix, when building the module and packaging it, only package this
# file, and make it so that the **only** possibility is to load the compiled
# code within this file. Don't even bother shipping the individual script files.

Write-Debug "`e[4mSOURCING/LOADING INFORMATION`e[0m"
Write-Debug "`$global:ModuleDebugDotSource: $global:ModuleDebugDotSource"
Write-Debug "`$global:ModuleDebugIndividualFiles: $global:ModuleDebugIndividualFiles"

function Resolve-Path_i {
	<#
	.SYNOPSIS
		Resolves a path, gracefully handling a non-existent path.
		
	.DESCRIPTION
		Resolves a path into the full path. If the path is invalid,
		an empty string will be returned instead.
		
	.PARAMETER Path
		The path to resolve.
		
	.EXAMPLE
		PS C:\> Resolve-Path_i -Path "~\Desktop"
		
		Returns 'C:\Users\...\Desktop"

	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string]
		$Path
	)
	
	# Run the command, silencing errors.
	$resolvedPath = Resolve-Path $Path -ErrorAction Ignore
	
	# If NULL, then just return an empty string.
	if ($null -eq $resolvedPath) {
		$resolvedPath = ""
	}
	
	$resolvedPath
}
function Import-ModuleFile {
	<#
	.SYNOPSIS
		Loads files into the module on module import.
		Only used if dot-sourcing is on.
		
	.DESCRIPTION
		This helper function is used during module initialization.
		It should always be dot-sourced itself, in order to properly function.
		
	.PARAMETER Path
		The path to the file to load.
		
	.EXAMPLE
		PS C:\> . Import-ModuleFile -File $function.FullName
		
		Imports the file stored in $function according to import policy.
		
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path
	)
	
	Write-Debug "Importing file: $Path"
	
	# Get the resolved path to avoid any cross-OS issues.
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	if ($doDotSource) {
		# Load the file through dot-sourcing.
		. $resolvedPath	
		Write-Debug "Dot sourcing."
	}
	else {
		# Load the script through different method (unknown atm?).
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($resolvedPath))), $null, $null) 
	}
}

# This checks for whether this module is a "packaged" module release.
#
# A "packaged" module will have all the code put into this file (down below),
# and in that case, no more file importing needs to be done.
#
# Otherwise, if the code is still contained in seperate files within the module
# directory, they need to be imported individually.
$importIndividualFiles = $false
if ("<was not compiled>" -eq '<was not compiled>') {
	$importIndividualFiles = $true
	
	Write-Debug "Module not compiled! Importing individual files."
}

# This checks if the module is running from the original development environment.
# If it is, import the files individually anyway, even if this script contains
# the full module.
if (Test-Path (Resolve-Path_i -Path "$($script:ModuleRoot)\..\.git")) {
	$importIndividualFiles = $true
	
	Write-Debug "Detected running in project repository! Importing individual files."
}

# If a global variable 'ModuleDebugIndividualFiles' is set in the current shell,
# load the files individually anyway, even if this script contains the 
# full module.
if ($global:ModuleDebugIndividualFiles -eq $true) {
	$importIndividualFiles = $true
	
	Write-Debug "Detected `$global:ModuleDebugIndividualFiles! Importing individual files."
}

Write-Debug "`e[4mFINAL DECISION`e[0m"
Write-Debug "Dot-sourcing: $doDotSource"
Write-Debug "Importing individual files: $importIndividualFiles"

# If importing code in individual files, perform the importing.
# Otherwise, the compiled code below will be loaded.
if ($importIndividualFiles) {
	Write-Debug "IMPORTING INDIVIDUAL FILES"
	
	# Execute Pre-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\preimport.ps1"
	
	# Import all internal functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Import all public functions.
	foreach ($file in (Get-ChildItem "$ModuleRoot\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {	
		. Import-ModuleFile -Path $file.FullName
	}
	
	# Execute Post-import actions.
	. Import-ModuleFile -Path "$ModuleRoot\internal\postimport.ps1"
	
	# End execution here, do not load compiled code below (if there is any).
	return
}

Write-Debug "LOADING COMPILED CODE!"

#region Load compiled code
"<compile code into here>"

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
		return $path.Replace($env:USERPROFILE, "~")
	}
	
	[string] FullPath() {
		# Return the path after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Path)
	}
	
	[string] ShortTarget() {
		# Return the path after replacing common variable string.
		$path = $this._Target.Replace($env:APPDATA, "%APPDATA%")
		$path = $path.Replace($env:LOCALAPPDATA, "%LOCALAPPDATA%")
		return $path.Replace($env:USERPROFILE, "~")
	}
	
	[string] FullTarget() {
		# Return the target after expanding any environment variables encoded as %VAR%.
		return [System.Environment]::ExpandEnvironmentVariables($this._Target)
	}
	
	[bool] Exists() {
		# Check if the item even exists.
		if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction SilentlyContinue)) {
			return $false
		}
		# Checks if the symlink item and has the correct target.
		if ((Get-Item -Path $this.FullPath() -ErrorAction SilentlyContinue).Target -eq $this.FullTarget()) {
			return $true
		}else {
			return $false
		}
	}
	
	<# [bool] NeedsModification() {
		# Checks if the symlink is in the state it should be in.
		if ($this.Exists() -ne $this.ShouldExist()) {
			return $true
		}else {
			return $false
		}
	} #>
	
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
	
	# TODO: Refactor this method to use the new class methods.
	[void] CreateFile() {
		# If the symlink condition isn't met, skip creating it.
		if ($this.ShouldExist() -eq $false) {
			Write-Verbose "Skipping the symlink: '$($this.Name)', as the creation condition is false."
			return
		}
		
		$target = (Get-Item -Path $this.FullPath() -ErrorAction SilentlyContinue).Target
		if ($null -eq (Get-Item -Path $this.FullPath() -ErrorAction SilentlyContinue)) {
			# There is no existing item or symlink, so just create the new symlink.
			Write-Verbose "Creating new symlink item."
		} else {
			if ([System.String]::IsNullOrWhiteSpace($target)) {
				# There is an existing item, so remove it.
				Write-Verbose "Creating new symlink item. Deleting existing folder/file first."
				try {
					Remove-Item -Path $this.FullPath() -Force -Recurse
				}
				catch {
					Write-Warning "The existing item could not be deleted. It may be in use by another program."
					Write-Warning "Please close any programs which are accessing files via this folder/file."
					Read-Host -Prompt "Press any key to continue..."
					Remove-Item -Path $this.FullPath() -Force -Recurse
				}
			}elseif ($target -ne $this.FullTarget()) {
				# There is an existing symlink, so remove it.
				# Must be done by calling the 'Delete()' method, rather than 'Remove-Item'.
				Write-Verbose "Changing the symlink item target (deleting and re-creating)."
				try {
					(Get-Item -Path $this.FullPath()).Delete()
				}
				catch {
					Write-Warning "The symlink could not be deleted. It may be in use by another program."
					Write-Warning "Please close any programs which are accessing files via this symlink."
					Read-Host -Prompt "Press any key to continue..."
					(Get-Item -Path $this.FullPath()).Delete()
				}
			}elseif ($target -eq $this.FullTarget()) {
				# There is an existing symlink and it points to the correct target.
				Write-Verbose "No change required."
			}
		}
		
		# Create the new symlink.
		New-Item -ItemType SymbolicLink -Force -Path $this.FullPath() -Value $this.FullTarget() | Out-Null
	}
	
	[void] DeleteFile() {
		# Check that the actual symlink item exists first.
		Write-Verbose "Deleting the symlink file: '$($this.Name)'."
		if ($this.Exists()) {
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
		}else {
			Write-Warning "Trying to delete symlink: '$($this.Name)' which doesn't exist on the filesystem."
		}
	}
}
#endregion Load compiled code