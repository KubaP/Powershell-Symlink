<#
.SYNOPSIS
	Gets a symlink.
	
.DESCRIPTION
	Gets a symlink definition from the database.
	
.PARAMETER Names
	The name(s) of the symlink(s) to retrieve. This parameter supports tab-completion for the values.
	
.PARAMETER All
	Retrieve all of the defined symlinks.
	
.EXAMPLE
	PS C:\> Get-Symlink -Names "test"
	
	Returns the symlink object for the link called "test".
	
.EXAMPLE
	PS C:\> "test", "test2" | Get-Symlink
	
	Returns the symlink object for the links called "test" and "test2".
	
.INPUTS
	System.String[]
	
.OUTPUTS
	Symlink[]
	
.NOTES
	-Names supports tab-completion.
	
#>
function Get-Symlink {
	
	[CmdletBinding(DefaultParameterSetName = "Specific")]
	param (
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All
		
	)
	
	begin {
		# Store the retrieved symlinks, to output together at the end.
		$outputList = New-Object System.Collections.Generic.List[Symlink]
	}
	
	process {
		if (-not $All) {
			Write-Verbose "Retrieving specified symlinks: $Names."
			# Read in the existing symlinks.
			$linkList = Read-Symlinks
			
			# Iterate through all the passed in names.
			foreach ($name in $Names) {
				Write-Verbose "Processing the symlink: '$name'."
				# If the link doesn't exist, warn the user.
				$existingLink = $linkList | Where-Object { $_.Name -eq $name }
				if ($null -eq $existingLink) {
					Write-Warning "There is no symlink called: '$name'."
					continue
				}
				
				# Add the symlink object.
				$outputList.Add($existingLink)
			}
		}else {
			Write-Verbose "Retrieving all symlinks."
			# Read in the existing symlinks, and pipe them all out.
			$outputList = Read-Symlinks
		}
	}
	
	end {
		# By default, outputs in List formatting.
		$outputList | Sort-Object -Property Name
	}
	
}