<#
.SYNOPSIS
	Deletes a specified symlink item(s).
	
.DESCRIPTION
	The `Remove-YoutubeDlItem` cmdlet deletes one or more symlinks, specified
	by their name(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to delete.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER DontDeleteItem
	Prevents the deletion of the symbolic-link item from the filesystem.
	(The symlink definition will still be deleted).
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the symlinks
		to delete.
	
.OUTPUTS
	None
	
.NOTES
	This command is aliased by default to 'rsl'.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data"
	
	Deletes the symlink definition named "data", and deletes the symbolic-link
	item from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Names "data","files"
	
	Deletes the symlink definitions named "data" and "files", and their 
	symbolic-link items from the filesystem.
	
.EXAMPLE
	PS C:\> Remove-Symlink -Name "data" -DontDeleteItem
	
	Deletes the symlink definition named "data", but does not delete the
	symbolic-link item from the filesystem; that remains unchanged.
	
.LINK
	New-Symlink
	Get-Symlink
	Set-Symlink
	about_Symlink
	
#>
function Remove-Symlink
{
	[Alias("rsl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 1)]
		[switch]
		$DontDeleteItem
		
	)
	
	process
	{
		# Read in the existing symlinks.
		$linkList = Read-Symlinks
		
		foreach ($name in $Names)
		{
			# If the link doesn't exist, warn the user.
			$existingLink = $linkList | Where-Object { $_.Name -eq $name }
			if ($null -eq $existingLink)
			{
				Write-Error "There is no symlink named: '$name'."
				continue
			}
			
			# Delete the symlink from the filesystem.
			$expandedPath = $existingLink.FullPath()
			$item = Get-Item -Path $expandedPath -ErrorAction Ignore
			if (-not $DontDeleteItem -and $existingLink.Exists() -and $PSCmdlet.ShouldProcess("Deleting symbolic-link at '$expandedPath'.", "Are you sure you want to delete the symbolic-link at '$expandedPath'?", "Delete Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until
				# the user has closed any programs using the item.
				while (Test-Path -Path $expandedPath)
				{
					try
					{
						# Calling `Remove-Item` on a symbolic-link will delete
						# the original items the link points to; calling
						# Delete() will only destroy the symbolic-link iteself.
						$item.Delete()
					}
					catch
					{
						Write-Error "The symbolic-link located at '$expandedPath' could not be deleted."
						Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
					}
				}
			}
			
			# Remove the link from the list.
			Write-Verbose "Deleting the symlink object."
			$linkList.Remove($existingLink) | Out-Null
		}
		
		# Save the modified database.
		if ($PSCmdlet.ShouldProcess("Updating database at '$script:DataPath' with the changes (deletions).", "Are you sure you want to update the database at '$script:DataPath' with the changes (deletions)?", "Save File Prompt"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -Force -WhatIf:$false `
				-Confirm:$false | Out-Null
		}
	}
}