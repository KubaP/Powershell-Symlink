<#
.SYNOPSIS
	Sets a property of a symlink.
	
.DESCRIPTION
	Changes the property of a symlink to a new value.
	
.PARAMETER Name
	The name/identifier of the symlink to edit.
  ! This parameter tab-completes valid symlink names.

.PARAMETER Property
	The property to edit on this symlink. Valid values include:
	"Name", "Path", "Target", and "CreationCondition".
  ! This parameter tab-completes valid options.
	
.PARAMETER Value
	The new value for the property to take.
	
.PARAMETER WhatIf
	wip
	
.PARAMETER Confirm
	wip
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	
	For detailed help regarding the 'Creation Condition' scriptblock, see
	the help at: about_Symlink.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Name" -Value "WORK"
	
	This command will change the name of the symlink called "data", to the new
	name of "WORK". From now on, there is no symlink named "data" anymore.
	
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