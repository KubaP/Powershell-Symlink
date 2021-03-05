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
		$updatedList = New-Object System.Collections.Generic.List[Symlink] 
		
		if ($All)
		{
			$linkList = Read-Symlinks
		}
		else
		{
			$linkList = Read-Symlinks | Where-Object { $Names.Contains($_.Name) }
		}
	}
	
	process
	{
		foreach ($link in $linkList)
		{
			if (-not $link.ShouldExist() -or -not $Force)
			{
				# The symbolic-link isn't meant to exist, so skip it.
				Write-Verbose "The symlink named: '$($link.Name)' is not being created."
				continue
			}
			
			# Ensure the symlink's target is valid and can be pointed to.
			if ($link.GetTargetState() -eq "Invalid")
			{
				Write-Error "The symlink named: '$($link.Name)' has a target which is invalid: '$($link.FullTarget())'!`nCannot create this symlink."
				continue
			}
			
			# Check for an unknown issue.
			if ($link.GetSourceState() -eq "Unknown")
			{
				Write-Error "An unknown error has come up; this should never occur!"
				continue
			}
			
			# Check the path can be validated.
			if ($link.GetSourceState() -eq "CannotValidate")
			{
				Write-Error "Could not validate the path for the symbolic-link: '$name'! Could it contain a non-present environment variable?"
				continue
			}
			
			# Keep track of changes.
			if ($link.GetSourceState() -eq "IncorrectTarget")
			{
				$updatedList.Add($link)
			}
			else
			{
				$createdList.Add($link)
			}
			
			$expandedPath = $link.FullPath()
			if ($PSCmdlet.ShouldProcess("Creating symbolic-link item at '$expandedPath'.", "Are you sure you want to create the symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath -ErrorAction Ignore)
				{
					$result = Delete-Existing -Path $expandedPath
					if (-not $result)
					{
						Write-Error "Could not delete the existing item located at: '$expandedPath' to create the symbolic-link in its place! Could a file be in use?"
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
					New-Item -ItemType SymbolicLink -Path $link.FullPath() -Value $link.FullTarget() -Force `
						-WhatIf:$false -Confirm:$false -ErrorAction Stop | Out-Null
				}
				catch
				{
					Write-Error "The symlink named: '$($link.Name)' could not be created at the path: '$($link.FullPath())'!`nCould this path be invalid?"
					continue
				}
			}
		}
	}
	
	end
	{
		# By default, outputs in List formatting.
		if ($createdList.Count -gt 0)
		{
			Write-Host "Created the following new symbolic-links:"
			$createdList | Sort-Object -Property Name
		}
		if ($updatedList.Count -gt 0)
		{
			Write-Host "Updated the following symbolic-links:"
			$updatedList | Sort-Object -Property Name
		}
	}
}