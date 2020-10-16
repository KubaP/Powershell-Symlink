<#
.SYNOPSIS
	Gets the details of a symlink.
	
.DESCRIPTION
	Retrieves the details of symlink definition(s).
	
.PARAMETER Names
	The name(s)/identifier(s) of the symlinks to retrieve. Multiple values
	are accepted to retrieve the data of multiple links.
  ! This parameter tab-completes valid symlink names.
	
.PARAMETER All
	Specifies to retrieve details for all symlinks.
	
.INPUTS
	System.String[]
	
.OUTPUTS
	Symlink[]
	
.NOTES
	-Names supports tab-completion.
	
.EXAMPLE
	PS C:\> Get-Symlink -Names "data"
	
	This command will retrieve the details of the symlink named "data", and
	output the information to the screen.
	
.EXAMPLE
	PS C:\> Get-Symlink -Names "data","files"
	
	This command will retrieve the details of the symlinks named "data" and 
	"files", and output both to the screen, one after another.
  ! You can pipe the names to this command instead.
	
.EXAMPLE
	PS C:\> Get-Symlink -All
		
	This command will retrieve the details of all symlinks, and output the
	information to the screen.
	
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