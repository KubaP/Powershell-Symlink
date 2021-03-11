<#
.SYNOPSIS
	Reads all of the defined symlink objects.
	
.DESCRIPTION
	Reads all of the defined symlink objects.
	
.EXAMPLE
	PS C:\> $list = Read-Symlinks
	
	Reads all of the symlink objects into a variable, for later manipulation.
	
.INPUTS
	None
	
.OUTPUTS
	System.Collections.Generic.List[Symlink]
	
.NOTES
	
#>
function Read-Symlinks
{
	[CmdletBinding()]
	param ()
	
	# Create an empty list.
	$linkList = New-Object -TypeName System.Collections.Generic.List[Symlink]
	
	# If the file doesn't exist, skip any importing.
	if (Test-Path -Path $script:DataPath -ErrorAction Ignore)
	{
		# Read the xml data in.
		try
		{
			$xmlData = Import-Clixml -Path $script:DataPath -ErrorAction Stop
		}
		catch
		{
			Write-Error "Could not load the .xml database file. Could it be corrupted?`n$($_.Exception.Message)"
			return
		}
		
		# Iterate through all the objects.
		foreach ($item in $xmlData)
		{
			# Rather than extracting the deserialised objects, which would create a mess of serialised and
			# non-serialised objects, create new identical copies from scratch.
			if ($item.pstypenames[0] -eq "Deserialized.Symlink")
			{
				# Ensure that the object has all the necessary properties defined,
				# and that the file hasn't been modified.
				if (-not ($item.PSObject.Properties.Name -contains "Name"))
				{
					Write-Error "A [Symlink] object does not have a name property. Could the file have been modified externally?"
					return
				}
				if (-not ($item.PSObject.Properties.Name -contains "_Path"))
				{
					Write-Error "A [Symlink] object does not have a path property. Could the file have been modified externally?"
					return
				}
				if (-not ($item.PSObject.Properties.Name -contains "_Target"))
				{
					Write-Error "A [Symlink] object does not have a target property. Could the file have been modified externally?"
					return
				}
				if (-not ($item.PSObject.Properties.Name -contains "_Condition"))
				{
					Write-Error "A [Symlink] object does not have a condition property. Could the file have been modified externally?"
					return
				}
				
				# Create using the appropiate constructor.
				$link = if ($null -eq $item._Condition)
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target)
				}
				else
				{
					[Symlink]::new($item.Name, $item._Path, $item._Target, [scriptblock]::Create($item._Condition))
				}
				
				$linkList.Add($link)
			}
		}
	}
	
	# Return the list as a <List> object, rather than as an array, (ps converts by default).
	Write-Output $linkList -NoEnumerate
}
