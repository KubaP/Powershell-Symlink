<#
.SYNOPSIS
	Creates a new symlink.
	
.DESCRIPTION
	Creates a new symlink definition in the database, and then creates the
	symbolic-link item on the filesystem.
	
.PARAMETER Name
	The name/identifier of this symlink (must be unique).
	
.PARAMETER Path
	The location of the symbolic-link item on the filesystem. If any parent
	folders defined in this path don't exist, they will be created.
	
.PARAMETER Target
	The location which the symbolic-link will point to. This defines whether
	the link points to a folder or file.
	
.PARAMETER CreationCondition
	A scriptblock which decides whether the symbolic-link is actually 
	created or not. This does not affect the creation of the symlink
	definition within the database. For more details about this, see the
	help at: about_Symlink.
	
.PARAMETER DontCreateItem
	Skips the creation of the symbolic-link item on the filesystem.
	
.PARAMETER WhatIf
	wip
	
.PARAMETER Confirm
	wip
	
.INPUTS
	None
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the 'Creation Condition' scriptblock, see
	the help at: about_Symlink.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
	
	This command will create a new symlink definition, named "data", and a
	symbolic-link located in the user's document folder under a folder also
	named "data", pointing to a folder on the D:\ drive.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
				-CreationCondition $script -DontCreateItem
	
	This command will create a new symlink definition, named "data", but it
	will not create the symbolic-link on the filesystem. A creation condition
	is also defined, which will be evaluated when the 'Build-Symlink' command
	is run in the future.
	
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
	
	Write-Verbose "Validating name."
	# Validate that the name isn't empty.
	if ([System.String]::IsNullOrWhiteSpace($Name)) {
		Write-Error "The name cannot be blank or empty!"
		return
	}
	
	# Validate that the target location exists.
	if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Target)) `
			-ErrorAction Ignore)) {
		Write-Error "The target path: '$Target' points to an invalid/non-existent location!"
		return
	}
	
	# Read in the existing symlink collection.
	$linkList = Read-Symlinks
	
	# Validate that the name isn't already taken.
	$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
	if ($null -ne $existingLink) {
		Write-Error "The name: '$Name' is already taken!"
		return
	}
	
	Write-Verbose "Creating new symlink object."
	# Create the new symlink object.
	if ($null -eq $CreationCondition) {
		$newLink = [Symlink]::new($Name, $Path, $Target)
	}
	else {
		$newLink = [Symlink]::new($Name, $Path, $Target, $CreationCondition)
	}
	# Add the new link to the list, and then re-export the list.
	$linkList.Add($newLink)
	Write-Verbose "Re-exporting the modified database."
	Export-Clixml -Path $script:DataPath -InputObject $linkList | Out-Null
	
	# Build the symlink item on the filesytem.
	if (-not $DontCreateItem) {
		$newLink.CreateFile()
	}
}