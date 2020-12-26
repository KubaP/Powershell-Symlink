<#
.SYNOPSIS
	Creates the symbolic-link items.
	
.DESCRIPTION
	The `Build-Symlink` cmdlet creates the symbolic-link items on the
	filesystem. Non-existent items will be created anew, whilst existing items
	will be updated (if necessary). This cmdlet does not create any new
	symlink definitions.	
	
.PARAMETER Names
	Specifies the name(s) of the symlinks to create.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER All
	Specifies to create all symlinks.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to create a symbolic-link item on the filesystem even
	if the creation condition is false. Even using this parameter, if the
	filesystem denies access to the necessary files, this cmdlet can fail.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the
		symlinks to create.
	
.OUTPUTS
	Symlink
	
.NOTES
	This command is aliased by default to 'bsl'.
	
.EXAMPLE
	PS C:\> Build-Symlink -All
	
	Creates all of the symbolic-link items on the filesystem for all symlink
	definitions, assuming the creation condition is met.
	
.EXAMPLE
	PS C:\> Build-Symlink -Names "data","files"
	
	Creates the symbolic-link items on the filesystem for the symlink
	definitions named "data" and "files", assuming any creation conditions for
	each evaluate to true.
	
.LINK
	New-Symlink
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function Build-Symlink
{
	[Alias("bsl")]
	
	[CmdletBinding(DefaultParameterSetName = "All", SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All,
		
		[Parameter()]
		[switch]
		$Force
		
	)

	begin
	{
		# Validate that '-WhatIf'/'-Confirm' isn't used together with '-Force'.
		# This is ambiguous, so warn the user instead.
		Write-Debug "`$WhatIfPreference: $WhatIfPreference"
		Write-Debug "`$ConfirmPreference: $ConfirmPreference"
		if ($WhatIfPreference -and $Force)
		{
			Write-Error "You cannot specify both '-WhatIf' and '-Force' in the invocation for this cmdlet!"
			return
		}
		if (($ConfirmPreference -eq "Low") -and $Force)
		{
			Write-Error "You cannot specify both '-Confirm' and '-Force' in the invocation for this cmdlet!"
			return
		}
	
		# Store lists to notify user which symlinks were created/modified/etc.
		$newList = New-Object System.Collections.Generic.List[Symlink] 
		$modifiedList = New-Object System.Collections.Generic.List[Symlink]
		
		if ($All)
		{
			$linkList = Read-Symlinks
		}
		else
		{
			$linkList = Get-Symlinks -Names $Names -Verbose:$false
		}
	}
	
	process
	{
		foreach ($link in $linkList)
		{
			# Record the state to display the changes at the end.
			if (-not $link.Exists())
			{
				$newList.Add($link)
			}
			elseif ($link.GetState() -eq "NeedsDeletion" -or $link.GetState() -eq "NeedsCreation")
			{
				$modifiedList.Add($link)
			}
			
			# Build the symbolic-link item on the filesytem.
			$path = $link.FullPath()
			if ($PSCmdlet.ShouldProcess("Creating symbolic-link item at '$path'.", "Are you sure you want to create the symbolic-link item at '$path'?", "Create Symbolic-Link Prompt") -and ($newLink.ShouldExist() -or $Force))
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
							Remove-Item -Path $path -Force -Recurse -WhatIf:$false -Confirm:$false | Out-Null
						}
						catch
						{
							Write-Error "The item located at '$path' could not be deleted to make room for the symbolic-link.`nClose any programs which may be using this path and try again."
							Read-Host -Prompt "Press any key to continue..."
						}
					}
				}
				elseif ($item.Target -ne $link.FullTarget())
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
				
				New-Item -ItemType SymbolicLink -Path $link.FullPath() -Value $link.FullTarget() -Force `
					-WhatIf:$false -Confirm:$false | Out-Null
			}
		}
	}
	
	end
	{
		# By default, outputs in List formatting.
		if ($newList.Count -gt 0)
		{
			Write-Host "Created the following new symlinks:"
			Write-Output $newList
		}
		if ($modifiedList.Count -gt 0)
		{
			Write-Host "Modified the following existing symlinks:"
			Write-Output $modifiedList
		}
	}
}