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
	something
	
.PARAMETER Confirm
	something
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "data"
	
	This command will remove a symlink definition, named "data", and delete the
	symbolic-link item from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "data","files"
	
	This command will remove the symlink definitions named "data" and "files",
	and delete the symbolic-link items of both.
  ! You can pipe the names to this command instead.
	
#>
function Remove-Symlink {
	
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
	
	# Process block since this function accepts pipeline input.
	process {
		foreach ($name in $Names) {
			Write-Verbose "Processing the symlink: '$name'."
			# Read in the existing symlinks.
			$linkList = Read-Symlinks
				
			# If the link doesn't exist, warn the user.
			$existingLink = $linkList | Where-Object { $_.Name -eq $name }
			if ($null -eq $existingLink) {
				Write-Error "There is no symlink called: '$name'."
				return
			}
			
			# Delete the symlink from the filesystem.
			if (-not $DontDeleteItem) {
				Write-Verbose "Deleting the symlink item from the filesystem."
				$existingLink.DeleteFile()
			}
			
			# Remove the link from the list.
			$linkList.Remove($existingLink) | Out-Null
		}
		
		# Re-export the list.
		Write-Verbose "Re-exporting the modified database."
		Export-Clixml -Path $script:DataPath -InputObject $linkList | Out-Null
			
	}
	
}