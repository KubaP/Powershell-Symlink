<#
.SYNOPSIS
	Creates a new symlink.
	
.DESCRIPTION
	Creates a new symlink definition in the database, and then creates the symlink on the filesystem.
	
.PARAMETER Name
	The human-readable name of this symlink (seperate from the actual path).
	
.PARAMETER Path
	The path of the symlink location. The absence of a file extension creates a symlink folder. A specified
	file extension creates a symlink file.
	
.PARAMETER Target
	The target directory or file which ths symlink points to.
	
.PARAMETER CreationCondition
	A scriptblock which contains logic to decide if the symlink should be built or not. This scriptblock
	should return either $true or $false values. For more information, see the help at: about_System_symlinks.
	
.PARAMETER DontCreateItem
	Don't create the symlink item on the filesystem.
	
.PARAMETER WhatIf
	something
	
.PARAMETER Confirm
	something
	
.EXAMPLE
	PS C:\> New-Symlink -Name "PowerToys" -Path "~\Appdata\Local\Microsoft\PowerToys"
		-Target "D:\Programs\Data\PowerToys"
	
	Creates a symlink in the local appdata folder pointing to a seperate data folder on the D:\ drive.
	
.INPUTS
	None
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the 'Creation Condition' for a symlink, see the help at: about_System_symlinks.
	
#>
function New-Symlink {
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[string]
		$Target,
		
		[Parameter(Position = 3)]
		[scriptblock]
		$CreationCondition,
		
		[Parameter(Position = 4)]
		[switch]
		$DontCreateItem
		
	)
	
	# Validate that the name is valid.
	if ([system.string]::IsNullOrWhiteSpace($Name)) {
		Write-Error "The name cannot be blank or empty!"
		return
	}
	
	# Validate that the target exists.
	if ((Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Target)) -ErrorAction SilentlyContinue)`
		-eq $false) {
		Write-Error "The target path: '$Target' points to an invalid location!"
		return
	}
	
	# Read in the existing symlinks.
	[System.Collections.Generic.List[Symlink]]$linkList = Read-Symlinks

	# Validate that the name isn't already taken.
	$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
	if ($null -ne $existingLink) {
		Write-Error "The name: '$Name' is already taken."
		return
	}
	
	Write-Verbose "Creating new symlink object."
	# Create the new symlink object.
	if ($null -eq $CreationCondition) {
		$newLink = [Symlink]::new($Name, $Path, $Target)
	}else {
		$newLink = [Symlink]::new($Name, $Path, $Target, $CreationCondition)
	}
	# Add the new link to the list, and then re-export the list.
	$linkList.Add($newLink)
	Write-Verbose "Re-exporting the modified database."
	Export-Clixml -Path $script:DataPath_Symlink -InputObject $linkList | Out-Null
	
	# Build the symlink item on the filesytem.
	if (-not $DontCreateItem) {
		Write-Verbose "Creating the symlink item on the filesytem."
		$newLink.CreateFile()
	}
}