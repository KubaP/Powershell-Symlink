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
	if the creation condition evaluates to false.
	
	Even using this parameter, if the filesystem denies access to the necessary
	files, this cmdlet can fail.
	
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
	
		# Store lists to notify user which symlinks were created.
		$createdList = New-Object System.Collections.Generic.List[Symlink] 
		
		if ($All)
		{
			$linkList = Read-Symlinks
		}
		else
		{
			$linkList = Get-Symlink -Names $Names -Verbose:$false
		}
	}
	
	process
	{
		foreach ($link in $linkList)
		{
			# Check if the symlink should be created, but it has an invalid target,
			# as in such a case it must be skipped.
			if (($link.ShouldExist() -or $Force) -and ($link.TargetState() -ne "Valid"))
			{
				Write-Error "The symlink named '$($link.Name)' has a target which is invalid/non-existent!`nAborting creation of this symlink."
				continue
			}
			
			# Build the symbolic-link item on the filesytem.
			$expandedPath = $link.FullPath()
			if (($link.ShouldExist() -or $Force) -and ($link.TargetState() -eq "Valid") -and $PSCmdlet.ShouldProcess("Creating symbolic-link item at '$expandedPath'.", "Are you sure you want to create the symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
			{
				# Appropriately delete any existing items before creating the symbolic-link.
				$item = Get-Item -Path $expandedPath -ErrorAction Ignore
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points
						# to; calling 'Delete()' will only destroy the symbolic-link iteself,
						# whilst calling 'Delete()' on a folder will not delete it's contents. Therefore check
						# whether the item is a symbolic-link to call the appropriate method.
						if ($null -eq $item.LinkType)
						{
							Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
								-Confirm:$false | Out-Null
						}
						else
						{
							$item.Delete()
						}
					}
					catch
					{
						Write-Error "The item located at '$expandedPath' could not be deleted to make room for the symbolic-link."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
				
				New-Item -ItemType SymbolicLink -Path $link.FullPath() -Value $link.FullTarget() -Force `
					-WhatIf:$false -Confirm:$false | Out-Null
				
				$createdList.Add($link)
			}
		}
	}
	
	end
	{
		# By default, outputs in List formatting.
		if ($createdList.Count -gt 0)
		{
			Write-Host "Created the following new symlinks:"
			Write-Output $createdList
		}
	}
}