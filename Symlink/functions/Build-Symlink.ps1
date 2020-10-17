<#
.SYNOPSIS
	Builds all of the symbolic-links.
	
.DESCRIPTION
	Creates the symbolic-link items on the filesystem. Non-existent items will
	be created, whilst existing items will be updated (if necessary).
	
.PARAMETER Names
	The name(s)/identifier(s) of the symlinks to create. Multiple values
	are accepted to build multiple links at once.
  ! This parameter tab-completes valid symlink names.
	
.PARAMETER All
	Specifies to create all symlinks.
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	
.EXAMPLE
	PS C:\> Build-Symlink -All
	
	This command will go through all of the symlink definitions, and create 
	the symbolic-link items on the filesystem, assuming the creation condition
	for them is met.
	
.EXAMPLE
	PS C:\> Build-Symlink -Names "data","files"
	
	This command will only go through the symlinks given in, and create the
	items on the filesystem.
  ! You can pipe the names to this command instead.
	
#>
function Build-Symlink {
	
	[CmdletBinding(DefaultParameterSetName = "All")]
	param (
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All
		
	)
	
	begin {
		# Store lists to notify user which symlinks were created/modified/etc.
		$newList = New-Object System.Collections.Generic.List[Symlink] 
		$modifiedList = New-Object System.Collections.Generic.List[Symlink]
	}
	
	process {
		if ($All) {
			# Read in all of the existing symlinks.
			$linkList = Read-Symlinks
			
			foreach ($link in $linkList) {
				Write-Verbose "Creating the symbolic-link item for: '$($link.Name)'."
				
				# Record the state for displaying at the end.
				if ($link.Exists() -eq $false) {
					$newList.Add($link)
				}
				elseif ($link.State() -eq "NeedsDeletion" -or $link.State() -eq "NeedsCreation") {
					$modifiedList.Add($link)
				}
				
				# Create the symlink item on the filesystem.
				$link.CreateFile()
			}
		}
		else {
			# Read in the specified symlinks.
			$linkList = Get-Symlink -Names $Names -Verbose:$false
			
			foreach ($link in $linkList) {
				Write-Verbose "Creating the symbolic-link item for: '$($link.Name)'."
				
				# Record the state for displaying at the end.
				if ($link.Exists() -eq $false) {
					$newList.Add($link)
				}
				elseif ($link.State() -eq "NeedsDeletion" -or $link.State() -eq "NeedsCreation") {
					$modifiedList.Add($link)
				}
				
				# Create the symlink item on the filesystem.
				$link.CreateFile()
			}
		}
	}
	
	end {
		# By default, outputs in List formatting.
		if ($newList.Count -gt 0) {
			Write-Host "Created the following new symlinks:"
			Write-Output $newList
		}
		if ($modifiedList.Count -gt 0) {
			Write-Host "Modified the following existing symlinks:"
			Write-Output $modifiedList
		}
	}
}