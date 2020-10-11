<#
.SYNOPSIS
	Removes an existing symlink.
	
.DESCRIPTION
	Removes an existing symlink definition from the database. Also deletes the symlink from the filesystem.
	
.PARAMETER Names
	The name(s) of the symlink(s) to remove. This parameter supports tab-completion for the values.
	
.PARAMETER DontDeleteItem
	Don't remove the symlink item from the filesystem, i.e. keep it.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "test"
	
	Removes and deletes the symlink called "test".
	
.EXAMPLE
	PS C:\> "test", "test2" | Remove-Symlink
	
	Removes and deletes the symlinks called "test" and "test2".
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	
#>
function Remove-Symlink {
	
	[CmdletBinding()]
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
		Export-Clixml -Path $script:DataPath_Symlink -InputObject $linkList | Out-Null
			
	}
	
}