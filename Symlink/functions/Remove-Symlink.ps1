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
			
			# Check for an unknown issue.
			if ($existingLink.GetSourceState() -eq "Unknown")
			{
				Write-Error "An unknown error has come up; this should never occur!"
				continue
			}
			
			# If deleting the symbolic-link item, ensure that the path can be validated,
			# otherwise it makes no sense to try to delete it.
			if (-not $DontDeleteItem -and ($existingLink.GetSourceState() -eq "CannotValidate"))
			{
				Write-Error "Could not validate the path for the symbolic-link: '$name'! Could it contain a non-present environment variable?"
				continue
			}
			
			# Check if the symbolic-link doesn't exist.
			if ($existingLink.GetSourceState() -eq "NonExistent")
			{
				Write-Verbose "The symbolic-link: '$name' is not present on the filesystem. Skipping its deletion."
			}
			
			# Ensure that the symbolic-link does exist on the filesystem.
			$doesExist = ($existingLink.GetSourceState() -eq "Existent") -or ($existingLink.GetSourceState() -eq "UnknownTarget") -or ($existingLink.GetSourceState() -eq "IncorrectTarget")
			# Get the item.
			$expandedPath = $existingLink.FullPath()
			$item = Get-Item -Path $expandedPath -ErrorAction Ignore
			if (-not $DontDeleteItem -and $doesExist -and $PSCmdlet.ShouldProcess("Deleting symbolic-link at '$expandedPath'.", "Are you sure you want to delete the symbolic-link at '$expandedPath'?", "Delete Symbolic-Link Prompt"))
			{
				# Existing item may be in use and unable to be deleted, so retry until the user has closed
				# any programs using the item.
				while (Test-Path -Path $expandedPath -ErrorAction Ignore)
				{
					$result = Delete-Existing -Path $expandedPath
					if (-not $result)
					{
						Write-Error "Could not delete the symbolic-link: '$name' located at: '$expandedPath'! Could a file be in use?"
						Read-Host -Prompt "Press any key to retry..."
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