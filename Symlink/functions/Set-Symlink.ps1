<#
.SYNOPSIS
	Changes a value of a symlink item.
	
.DESCRIPTION
	The `Set-Symlink` cmdlet changes the value of a symlink.
	
.PARAMETER Name
	Specifies the name of the symlink to be changed.
	
 [!]This parameter will autocompleted to valid names for a symlink.

.PARAMETER Property
	Specifies the name of the property to change.
	
 [!]This parameter will autocompleted to the following: "Name", "Path",
	"Target", "CreationCondition".
	
.PARAMETER Value
	Specifies the new value of the property being changed.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to change the name of a symlink even if it overwrites an
	existing one, or forces this cmdlet to create a symbolic-link item on the
	filesystem even if the creation condition evaluates to false.
	
	Even using this parameter, if the filesystem denies access to the necessary
	files, this cmdlet can fail.
	
.INPUTS
	System.String
		You can pipe the name of the symlink to change.
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the creation condition scriptblock, see
	the "CREATION CONDITION SCRIPTBLOCK" section in help at: 'about_Symlink'.
	
	This command is aliased by default to 'ssl'.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Name" -Value "WORK"
	
	Changes the name of a symlink definition named "data", to the new name
	of "WORK". From now on, there is not symlink named "data" anymore, and that
	name is free for future use.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Path" -Value "~\Desktop\Files"
	
	Changes the path of the symlink definition named "data", to a new value
	located in the user's desktop folder. The old symbolic-link item at the
	previous location will be deleted from the filesystem, and a new item will
	be created at the new location.

.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Target" -Value "D:\new\target"
	
	Changes the target of the symlink definition named "data", to a new value
	on the "D:\" drive. The existing symbolic-link item on the filesystem will
	have its target updated to this new value, (technically involves deleting
	and re-creating the item since the target cannot be modified).
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "CreationCondition" 
			 -Value { return $false }
			 
	Changes the creation condition of the symlink definition named "data", to
	a new scriptblock which always returns $FALSE. This will not delete the
	existing symbolic-link item on the filesystem, even though if the condition
	was evaluated now, it would return false.
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function Set-Symlink
{
	[Alias("ssl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[ValidateSet("Name", "Path", "Target", "CreationCondition")]
		[string]
		$Property,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowNull()]
		$Value,
		
		[Parameter()]
		[switch]
		$Force
		
	)
	
	process
	{
		# If the link doesn't exist, warn the user.
		$linkList = Read-Symlinks
		$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $existingLink)
		{
			Write-Error "There is no symlink named: '$Name'!"
			return
		}
		
		# Modify the property values.
		Write-Verbose "Validating parameters."
		if ($Property -eq "Name")
		{
			# Validate that the new name is valid.
			if ([system.string]::IsNullOrWhiteSpace($Name))
			{
				Write-Error "The new name cannot be blank or empty!"
				return
			}
			# Validate that the new name isn't already taken.
			$clashLink = $linkList | Where-Object { $_.Name -eq $Value }
			if ($null -ne $clashLink)
			{
				if ($Force)
				{
					Write-Verbose "Existing symlink named: '$Value' exists, but since the '-Force' switch is present, the existing symlink will be deleted."
					$clashLink | Remove-Symlink
				}
				else
				{
					Write-Error "The name: '$Value' is already taken!"
					return
				}
			}
			
			$linkList = Read-Symlinks
			$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
			
			$existingLink.Name = $Value
		}
		elseif ($Property -eq "Path")
		{
			# Ensure the symbolic-link can be created at the new path.
			if (-not (Test-Path -Path $Value))
			{
				Write-Error "The new path is invalid!`nCannot re-create this symlink."
			}
			
			# Ensure the symlink's target is valid and can be pointed to.
			if ($existingLink.GetTargetState() -eq "Invalid")
			{
				Write-Error "The symlink has a target which is invalid: '$($existingLink.FullTarget())'!`nCannot re-create this symlink."
				continue
			}
			
			# Check for an unknown issue.
			if ($existingLink.GetSourceState() -eq "Unknown")
			{
				Write-Error "An unknown error has come up; this should never occur!"
				continue
			}
			
			# Check the path can be validated.
			if ($existingLink.GetSourceState() -eq "CannotValidate")
			{
				Write-Error "Could not validate the path for the symlink! Could it contain a non-present environment variable?"
				continue
			}
			
			if (-not $existingLink.ShouldExist() -or -not $Force)
			{
				# The symbolic-link isn't meant to exist, so skip it.
				Write-Warning "The symlink path is being updated, but it will not be re-created."
				continue
			}
			
			# Store the previous path of the symbolic-link, to be able to delete the old content as a way
			# of "moving" the symbolic-link.
			$oldPath = $existingLink.FullPath()
			
			# Update the symlink values.
			$existingLink._Path = $Value
			
			# If the symbolic-link is going to be re-created, delete the old one first.
			if (($existingLink.ShouldExist() -or $Force) -and $PSCmdlet.ShouldProcess("Moving existing symbolic-link to '$Value'.", "Are you sure you want to move the existing symbolic-link to '$Value'?", "Move Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $oldPath -ErrorAction Ignore)
				{
					$result = Delete-Existing -Path $oldPath
					if (-not $result)
					{
						Write-Error "Could not delete the existing item located at: '$oldPath'! Could a file be in use?"
						Read-Host -Prompt "Press any key to retry..."
					}
				}
				
				try
				{
					# There is no real way to check if the path is fully valid, especially since this invocation
					# is meant to create any missing parent folders. A path can contain % symbols as valid
					# characters, so 'C:\%test%\link' can be as valid as '%windir%\link'.
					# Only way to ensure nothing goes wrong is by attempting to perform this creation, and then
					# if the path truly cannot be resolved, then this will catch the error.
					New-Item -ItemType SymbolicLink -Path $existingLink.FullPath() -Value $existingLink.FullTarget() `
						-Force -WhatIf:$false -Confirm:$false | Out-Null
				}
				catch
				{
					Write-Error "The symlink could not be moved to the new path: '$($existingLink.FullPath())'!`nCould this path be invalid?"
					continue
				}
			}
		}
		elseif ($Property -eq "Target")
		{
			# Ensure that the new target exists.
			if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Value)) -ErrorAction Ignore))
			{
				Write-Error "The new target path: '$Value' is invalid!"
				return
			}
			
			# Check for an unknown issue.
			if ($existingLink.GetSourceState() -eq "Unknown")
			{
				Write-Error "An unknown error has come up; this should never occur!"
				continue
			}
			
			# Check the path can be validated.
			if ($existingLink.GetSourceState() -eq "CannotValidate")
			{
				Write-Error "Could not validate the path for the symlink! Could it contain a non-present environment variable?"
				continue
			}
			
			if (-not $existingLink.ShouldExist() -or -not $Force)
			{
				# The symbolic-link isn't meant to exist, so skip it.
				Write-Warning "The symlink target is being updated, but it will not be re-created."
				continue
			}
			
			# Update the symlink value.
			$existingLink._Target = $Value
			
			$expandedPath = $existingLink.FullPath()
			if (($existingLink.ShouldExist() -or $Force) -and $PSCmdlet.ShouldProcess("Updating the target of the symbolic-link at '$expandedPath'.", "Are you sure you want to update the target of the outdated symbolic-link at '$expandedPath'?", "Updating Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath -ErrorAction Ignore)
				{
					$result = Delete-Existing -Path $expandedPath
					if (-not $result)
					{
						Write-Error "Could not delete the existing item located at: '$expandedPath'! Could a file be in use?"
						Read-Host -Prompt "Press any key to retry..."
					}
				}
				
				try
				{
					# There is no real way to check if the path is fully valid, especially since this invocation
					# is meant to create any missing parent folders. A path can contain % symbols as valid
					# characters, so 'C:\%test%\link' can be as valid as '%windir%\link'.
					# Only way to ensure nothing goes wrong is by attempting to perform this creation, and then
					# if the path truly cannot be resolved, then this will catch the error.
					New-Item -ItemType SymbolicLink -Path $existingLink.FullPath() -Value $existingLink.FullTarget() `
						-Force -WhatIf:$false -Confirm:$false | Out-Null
				}
				catch
				{
					Write-Error "The symlink could not be moved to the new path: '$($existingLink.FullPath())'!`nCould this path be invalid?"
					continue
				}
			}
		}
		elseif ($Property -eq "CreationCondition")
		{
			$existingLink._Condition = $Value
		}
		
		if ($PSCmdlet.ShouldProcess("Updating database at '$script:DataPath' with the changes.", "Are you sure you want to update the database at '$script:DataPath' with the changes?", "Save File Prompt"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false `
				| Out-Null
		}
	}
}