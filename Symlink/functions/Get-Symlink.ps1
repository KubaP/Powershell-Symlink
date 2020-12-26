<#
.SYNOPSIS
	Gets the specified symlink item.
	
.DESCRIPTION
	The `Get-Symlink` cmdlet gets one or more symlinks, specified by their
	name(s).
	
.PARAMETER Names
	Specifies the name(s) of the items to get.
	
 [!]This parameter will autocomplete to valid symlink names.
	
.PARAMETER All
	Specifies to get all symlinks.
	
.INPUTS
	System.String[]
		You can pipe one or more strings containing the names of the
		symlinks to get.
	
.OUTPUTS
	Symlink
	
.NOTES
	This command is aliased by default to 'gsl'.
	
.EXAMPLE
	PS C:\> Get-Symlink -Names "data","files"
	
	Gets the symlink definitions named "data" and "video", and pipes them out
	to the screen, by default formatted in a list.
	
.EXAMPLE
	PS C:\> Get-Symlink -All
	
	Gets all symlink definitions, and pipes them out to the screen, by default
	formatted in a list.
	
.EXAMPLE
	PS C:\> Get-Symlink "data" | Build-Symlink
	
	Gets the symlink definition named "data", and then pipes it to the
	`Build-Symlink` cmdlet to create the symbolic-link item on the filesystem.
	
.LINK
	New-Symlink
	Set-Symlink
	Remove-Symlink
	Build-Symlink
	about_Symlink
	
#>
function Get-Symlink
{
	[Alias("gsl")]
	
	[CmdletBinding(DefaultParameterSetName = "Specific")]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline, ParameterSetName = "Specific")]
		[Alias("Name")]
		[string[]]
		$Names,
		
		[Parameter(Position = 0, Mandatory = $true, ParameterSetName = "All")]
		[switch]
		$All
		
	)
	
	begin
	{
		# Store the retrieved symlinks, to output together in one go at the end.
		$outputList = New-Object System.Collections.Generic.List[Symlink]
	}
	
	process
	{
		if (-not $All)
		{
			# Read in the existing symlinks.
			$linkList = Read-Symlinks
			
			# Iterate through all the passed in names.
			foreach ($name in $Names)
			{
				Write-Verbose "Retrieving the symlink: '$name'."
				# If the link doesn't exist, warn the user.
				$existingLink = $linkList | Where-Object { $_.Name -eq $name }
				if ($null -eq $existingLink)
				{
					Write-Warning "There is no symlink called: '$name'."
					continue
				}
				
				# Add the symlink object.
				$outputList.Add($existingLink)
			}
		}
		else
		{
			Write-Verbose "Retrieving all symlinks."
			# Read in all of the symlinks.
			$outputList = Read-Symlinks
		}
	}
	
	end
	{
		# By default, outputs in List formatting.
		$outputList | Sort-Object -Property Name
	}
}