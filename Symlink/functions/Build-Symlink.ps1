<#
.SYNOPSIS
	Builds all of the symlinks.
	
.DESCRIPTION
	Builds the symlinks on the filesystem. New symlinks will be created whilst modified symlinks
	will be updated.
	
.PARAMETER Names
	The name(s) of the symlink(s) to build. This parameter supports tab-completion for the values.
	
.PARAMETER All
	Build all of the defined symlinks.
	
.EXAMPLE
	PS C:\> Build-Symlinks -All
	
	Builds all of the symlinks.
	
.EXAMPLE
	PS C:\> Build-Symlinks -Names "test", "test2"
	
	Builds only the symlinks called "test" and "test2".
	
.INPUTS
	Symlink[]
	System.String[]
	
.OUTPUTS
	None
	
.NOTES
	-Names supports tab-completion.
	
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
		$newList = New-Object System.Collections.Generic.List[psobject] 
		$modifiedList = New-Object System.Collections.Generic.List[psobject]
	}
	
	process {
		if ($All) {
			Write-Verbose "Creating all symlink items on the filesystem."
			
			# Read in all of the existing symlinks.
			$linkList = Read-Symlinks
			
			foreach ($link in $linkList) {
				Write-Verbose "Processing the symlink: '$($link.Name)'."
				
				if ($link.Exists() -eq $false) {
					$newList.Add($link)
				}elseif ($link.NeedsModification()) {
					$modifiedList.Add($link)
				}
				
				# Create the symlink item on the filesystem.
				$link.CreateFile()
			}
		}else {
			Write-Verbose "Creating specified symlink items: '$Names' on the filesystem"
			
			# Read in the specified symlinks.
			$linkList = Get-Symlink -Names $Names -Verbose:$false
			
			foreach ($link in $linkList) {
				Write-Verbose "Processing the symlink: '$($link.Name)'."
				
				if ($link.Exists() -eq $false) {
					$newList.Add($link)
				}elseif ($link.NeedsModification()) {
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