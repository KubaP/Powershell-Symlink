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
		$Value
		
	)
	
	process
	{
		# If the link doesn't exist, warn the user.
		$linkList = Read-Symlinks
		$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $existingLink)
		{
			Write-Error "There is no symlink named: '$Name'."
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
				Write-Error "The name: '$Value' is already taken!"
				return
			}
			
			$existingLink.Name = $Value
		}
		elseif ($Property -eq "Path")
		{
			# Validate the new path isn't empty.
			if ([System.String]::IsNullOrWhiteSpace($Value))
			{
				Write-Error "The new path cannot be blank or empty!"
				return
			}
			
			# Firstly, delete the symlink at the original path.
			$path = $existingLink.FullPath()
			$item = Get-Item -Path $path
			if ($existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting symbolic-link at '$path'.", "Are you sure you want to delete the symbolic-link at '$path'?", "Delete Symbolic-Link Prompt"))
			{
				# Loop until the item can be deleted, as it may be in use by
				# another process.
				while (Test-Path -Path $path)
				{
					try
					{
						# Call this method to prevent deleting a symlink from
						# deleting the original contents it points to.
						$item.Delete()
					}
					catch
					{
						Write-Error "The symbolic-link located at '$path' could not be deleted.`nClose any programs which may be using this path and try again."
						Read-Host -Prompt "Press any key to continue..."
					}
				}
			}
			
			# Then change the path property, and re-create the symlink at the
			# new location, taking into account that there may be existing
			# items at the new path.
			$existingLink._Path = $Value
			$path = $existingLink.FullPath()
			if ($PSCmdlet.ShouldProcess("Creating symbolic-link item at '$path'.", "Are you sure you want to create the symbolic-link item at '$path'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the
				# symbolic-link.
				$item = Get-Item -Path $path -ErrorAction Ignore
				if ($null -eq $item.LinkType)
				{
					# Delete existing folder/file.
					# Loop until the item can be deleted, as it may be in use by another
					# process.
					while (Test-Path -Path $path)
					{
						try
						{
							Remove-Item -Path $path -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						catch
						{
							Write-Error "The item located at '$path' could not be deleted to make room for the symbolic-link.`nClose any programs which may be using this path and try again."
							Read-Host -Prompt "Press any key to continue..."
						}
					}
				}
				elseif ($item.Target -ne $existingLink.FullTarget())
				{
					# Delete existing symbolic-link which has a different target.
					# Loop until the item can be deleted, as it may be in use by another
					# process.
					while (Test-Path -Path $path)
					{
						try
						{
							# Call this method to prevent deleting a symlink from
							# deleting the original contents it points to.
							$item.Delete()
						}
						catch
						{
							Write-Error "The item located at '$path' could not be deleted to make room for the symbolic-link.`nClose any programs which may be using this path and try again."
							Read-Host -Prompt "Press any key to continue..."
						}
					}
				}
				
				New-Item -ItemType SymbolicLink -Path $path -Value $existingLink.FullTarget() -Force `
					-WhatIf:$false -Confirm:$false | Out-Null
			}
		}
		elseif ($Property -eq "Target")
		{
			# Validate that the target exists.
			if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Value)) `
					-ErrorAction Ignore))
			{
				Write-Error "The new target path: '$Value' points to an invalid location!"
				return
			}
			
			# Firstly, delete the symlink with the old target.
			$path = $existingLink.FullPath()
			$item = Get-Item -Path $path
			if ($existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting symbolic-link at '$path'.", "Are you sure you want to delete the symbolic-link at '$path'?", "Delete Symbolic-Link Prompt"))
			{
				# Loop until the item can be deleted, as it may be in use by
				# another process.
				while (Test-Path -Path $path)
				{
					try
					{
						# Call this method to prevent deleting a symlink from
						# deleting the original contents it points to.
						$item.Delete()
					}
					catch
					{
						Write-Error "The symbolic-link located at '$path' could not be deleted.`nClose any programs which may be using this path and try again."
						Read-Host -Prompt "Press any key to continue..."
					}
				}
			}
			
			# Then change the target property, and re-create the symlink at the
			# with the new target, taking into account that there may be
			# existing items at the new path.
			$existingLink._Target = $Value
			$path = $existingLink.FullPath()
			if ($PSCmdlet.ShouldProcess("Creating symbolic-link item at '$path'.", "Are you sure you want to create the symbolic-link item at '$path'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the
				# symbolic-link.
				$item = Get-Item -Path $path -ErrorAction Ignore
				if ($null -eq $item.LinkType)
				{
					# Delete existing folder/file.
					# Loop until the item can be deleted, as it may be in use by another
					# process.
					while (Test-Path -Path $path)
					{
						try
						{
							Remove-Item -Path $path -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						catch
						{
							Write-Error "The item located at '$path' could not be deleted to make room for the symbolic-link.`nClose any programs which may be using this path and try again."
							Read-Host -Prompt "Press any key to continue..."
						}
					}
				}
				elseif ($item.Target -ne $existingLink.FullTarget())
				{
					# Delete existing symbolic-link which has a different target.
					# Loop until the item can be deleted, as it may be in use by another
					# process.
					while (Test-Path -Path $path)
					{
						try
						{
							# Call this method to prevent deleting a symlink from
							# deleting the original contents it points to.
							$item.Delete()
						}
						catch
						{
							Write-Error "The item located at '$path' could not be deleted to make room for the symbolic-link.`nClose any programs which may be using this path and try again."
							Read-Host -Prompt "Press any key to continue..."
						}
					}
				}
				
				New-Item -ItemType SymbolicLink -Path $existingLink.FullPath() -Value $existingLink.FullTarget() `
					-Force -WhatIf:$false -Confirm:$false | Out-Null
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