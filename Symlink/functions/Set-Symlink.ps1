<#
.SYNOPSIS
	Sets a new value for a property in a symlink definition.
	
.DESCRIPTION
	Sets a property of an existing symlink definition to a new value.
	
.PARAMETER Name
	The name of the symlink to modify. This parameter supports tab-completion for the values.

.PARAMETER Property
	The property of the symlink to modify. Valid values are Name, Path, Target, and CreationCondition.
	
.PARAMETER Value
	The new value for the property.
	
.PARAMETER WhatIf
	something
	
.PARAMETER Confirm
	something
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "test" -Property "Name" -Value "hello"
	
	Changes the name of the "test" symlink to the value of "hello". From now on, the symlink
	"test" doesn't exist.
	
.EXAMPLE
	PS C:\> Get-Symlink -Name "test" | Set-Symlink -Property "Path" -Value "~\Desktop\link"
	
	Changes the path of the symlink called "test" to a new folder on the desktop. This will delete
	the original symlink item and create the re-create it at the new path.
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the 'Creation Condition' for a symlink, see the help at: about_System_symlinks.
	
#>
function Set-Symlink {
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[ValidateSet("Name", "Path", "Target", "CreationCondition")]
		[string]
		$Property,
		
		[Parameter(Position = 2, Mandatory = $true)]
		$Value
		
	)
	
	process {
		Write-Verbose "Processing the symlink: '$Name'."
		# Read in the existing symlinks.
		$linkList = Read-Symlinks
		
		# If the link doesn't exist, warn the user.
		$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $existingLink) {
			Write-Error "There is no symlink called: '$Name'."
			return
		}
		
		# Modify the property values.
		if ($Property -eq "Name") {
			Write-Verbose "Changing the name to: '$Value'."
			
			# Validate that the new name is valid.
			if ([system.string]::IsNullOrWhiteSpace($Name)) {
				Write-Error "The name cannot be blank or empty!"
				return
			}
			# Validate that the new name isn't already taken.
			$clashLink = $linkList | Where-Object { $_.Name -eq $Value }
			if ($null -ne $clashLink) {
				Write-Error "The name: '$Value' is already taken."
				return
			}
			
			$existingLink.Name = $Value
			
		}elseif ($Property -eq "Path") {
			Write-Verbose "Changing the path to: '$Path'."
			# First delete the symlink at the original path.
			$existingLink.DeleteFile()
			
			# Then change the path property, and re-create the symlink
			# at the new location.
			$existingLink._Path = $Value
			$existingLink.CreateFile()
			
		}elseif ($Property -eq "Target") {
			Write-Verbose "Changing the target to: '$Value'."
			
			# Validate that the target exists.
			if ((Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Value))) -eq $false) {
				Write-Error "The target path: '$Value' points to an invalid location!"
				return
			}
			
			# Change the target property, and edit the existing symlink (re-create).
			$existingLink._Target = $Value
			$existingLink.CreateFile()
			
		}elseif ($Property -eq "CreationCondition") {
			Write-Verbose "Changing the creation condition."
			$existingLink._Condition = $Value
			
			# TODO: Operate if condition result is different from previous state.
		}
		
		# Re-export the list.
		Write-Verbose "Re-exporting the modified database."
		Export-Clixml -Path $script:DataPath -InputObject $linkList | Out-Null
	}
	
}