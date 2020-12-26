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
	# TODO: Add -Force switch to ignore the creation condition
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
		$All
		
	)
	
	begin
	{
		# Store lists to notify user which symlinks were created/modified/etc.
		$newList = New-Object System.Collections.Generic.List[Symlink] 
		$modifiedList = New-Object System.Collections.Generic.List[Symlink]
	}
	
	process
	{
		if ($All)
		{
			# Read in all of the existing symlinks.
			$linkList = Read-Symlinks
			
			foreach ($link in $linkList)
			{
				Write-Verbose "Creating the symbolic-link item for: '$($link.Name)'."
				
				# Record the state for displaying at the end.
				if ($link.Exists() -eq $false)
				{
					$newList.Add($link)
				}
				elseif ($link.State() -eq "NeedsDeletion" -or $link.State() -eq "NeedsCreation")
				{
					$modifiedList.Add($link)
				}
				
				# Create the symlink item on the filesystem.
				if ($PSCmdlet.ShouldProcess($link.FullPath(), "Create Symbolic-Link"))
				{
					$link.CreateFile()
				}
			}
		}
		else
		{
			# Read in the specified symlinks.
			$linkList = Get-Symlink -Names $Names -Verbose:$false
			
			foreach ($link in $linkList)
			{
				Write-Verbose "Creating the symbolic-link item for: '$($link.Name)'."
				
				# Record the state for displaying at the end.
				if ($link.Exists() -eq $false)
				{
					$newList.Add($link)
				}
				elseif ($link.State() -eq "NeedsDeletion" -or $link.State() -eq "NeedsCreation")
				{
					$modifiedList.Add($link)
				}
				
				# Create the symlink item on the filesystem.
				if ($PSCmdlet.ShouldProcess($link.FullPath(), "Create Symbolic-Link"))
				{
					$link.CreateFile()
				}
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