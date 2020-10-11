# Create some global variables.
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = (Import-PowerShellDataFile -Path "$($script:ModuleRoot)\<MODULENAME>.psd1").ModuleVersion
$script:DataPath = "$env:APPDATA\Powershell\<MODULENAME>"

# Create the module data-storage folder if it doesn't exist.
if (-not (Test-Path -Path $script:DataPath -ErrorAction Ignore)) {
	New-Item -ItemType Directory -Path "$env:APPDATA" -Name "Powershell\<MODULENAME>" -Force -ErrorAction Stop
}

# Detect whether at some level dot-sourcing was enforced.
# Dot-sourcing can be enforced by either:
#	- A global variable 'ModuleDebugDotSource' set in the current shell.
#	- Setting the variable to true.
$script:doDotSource = $global:ModuleDebugDotSource
$script:doDotSource = $true # Needed to make code coverage tests work

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
	
	# Get the resolved path to avoid any cross-OS issues.
	$resolvedPath = $ExecutionContext.SessionState.Path.GetResolvedPSPathFromPSPath($Path).ProviderPath
	if ($doDotSource) {
		# Load the file through dot-sourcing.
		. $resolvedPath	
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
if ("<was not compiled>" -eq '<was not compiled>') {
	$importIndividualFiles = $true
}

# This checks if the module is running from the original development environment.
# If it is, import the files individually anyway, even if this script contains
# the full module.
if (Test-Path (Resolve-Path_i -Path "$($script:ModuleRoot)\..\.git")) {
	$importIndividualFiles = $true
}

# If a global variable 'ModuleDebugIndividualFiles' is set in the current shell,
# load the files individually anyway, even if this script contains the 
# full module.
$importIndividualFiles = $global:ModuleDebugIndividualFiles

# If importing code in individual files, perform the importing.
# Otherwise, the compiled code below will be loaded.
if ($importIndividualFiles) {
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

#region Load compiled code
"<compile code into here>"
#endregion Load compiled code