<#
.SYNOPSIS
	Removes an symlink.
	
.DESCRIPTION
	Deletes symlink definition(s) from the database, and also deletes the 
	symbolic-link item from the filesystem.
	
.PARAMETER Names
	The name(s)/identifier(s) of the symlinks to remove. Multiple values
	are accepted to retrieve the data of multiple links.
  ! This parameter tab-completes valid symlink names.
	
.PARAMETER DontDeleteItem
	Skips the deletion of the symbolic-link item on the filesystem. The
	link will remain afterwads.
	
.PARAMETER WhatIf
	Prints what actions would have been done in a proper run, but doesn't
	perform any of them.
	
.PARAMETER Confirm
	Prompts for user input for every "altering"/changing action.
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	This command is aliased to 'rsl'.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data"
	
	This command will remove a symlink definition, named "data", and delete the
	symbolic-link item from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "data","files"
	
	This command will remove the symlink definitions named "data" and "files",
	and delete the symbolic-link items of both.
  ! You can pipe the names to this command instead.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data" -DontDeleteItem
	
	This command will remove a symlink definition, named "data", but it will
	keep the symbolic-link item on the filesystem.
	
#>
function Remove-Symlink {
	[Alias("rsl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 1)]
		[switch]
		$DontDeleteItem
		
	)
	
	process {
		# Read in the existing symlinks.
		$linkList = Read-Symlinks
		
		foreach ($name in $Names) {
			Write-Verbose "Removing the symlink: '$name'."
			# If the link doesn't exist, warn the user.
			$existingLink = $linkList | Where-Object { $_.Name -eq $name }
			if ($null -eq $existingLink) {
				Write-Warning "There is no symlink called: '$name'."
				continue
			}
			
			# Delete the symlink from the filesystem.
			if (-not $DontDeleteItem -and $PSCmdlet.ShouldProcess($existingLink.FullPath(), "Delete Symbolic-Link")) {
				$existingLink.DeleteFile()
			}
			
			# Remove the link from the list.
			$linkList.Remove($existingLink) | Out-Null
		}
		
		# Re-export the list.
		if ($PSCmdlet.ShouldProcess("$script:DataPath", "Overwrite database with modified one")) {
			Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false | Out-Null
		}
	}
}