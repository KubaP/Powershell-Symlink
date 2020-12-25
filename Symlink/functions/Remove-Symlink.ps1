<#
.SYNOPSIS
	Deletes a specified symlink item.
	
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
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
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
			Write-Verbose "Removing the symlink: '$name'."
			# If the link doesn't exist, warn the user.
			$existingLink = $linkList | Where-Object { $_.Name -eq $name }
			if ($null -eq $existingLink)
			{
				Write-Warning "There is no symlink called: '$name'."
				continue
			}
			
			# Delete the symlink from the filesystem.
			if (-not $DontDeleteItem -and $PSCmdlet.ShouldProcess($existingLink.FullPath(), "Delete Symbolic-Link"))
			{
				$existingLink.DeleteFile()
			}
			
			# Remove the link from the list.
			$linkList.Remove($existingLink) | Out-Null
		}
		
		# Re-export the list.
		if ($PSCmdlet.ShouldProcess("$script:DataPath", "Overwrite database with modified one"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false | Out-Null
		}
	}
}