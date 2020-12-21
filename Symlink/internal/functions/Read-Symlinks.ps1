<#
.SYNOPSIS
	Read the symlink objects in.
	
.DESCRIPTION
	Deserialise the symlink objects from the database file.
	
.EXAMPLE
	PS C:\> $list = $Read-Symlinks
	
	Reads all of the symlink objects into a variable, for maniuplation.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[Symlink]
	
.NOTES
	
#>
function Read-Symlinks
{
	# Create an empty symlink list.
	$linkList = New-Object -TypeName System.Collections.Generic.List[Symlink]
	
	# If the file doesn't exist, skip any importing.
	if (Test-Path -Path $script:DataPath -ErrorAction SilentlyContinue)
	{
		# Read the xml data in.
		$xmlData = Import-Clixml -Path $script:DataPath
		
		# Iterate through all the objects.
		foreach ($item in $xmlData)
		{
			# Rather than extracting the deserialised objects, which would create a mess
			# of serialised and non-serialised objects, create new identical copies from scratch.
			if ($item.pstypenames[0] -eq "Deserialized.Symlink")
			{
				
				# Create using the appropiate constructor.
				$link = if ($null -eq $item._Condition)
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target)
				}else
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target, [scriptblock]::Create($item._Condition))
				}
				
				$linkList.Add($link)
			}
		}
	}
	
	# Return the list as a <List> object, rather than as an array (ps converts by default).
	Write-Output $linkList -NoEnumerate
}
