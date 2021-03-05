function Delete-Existing
{
	[CmdletBinding()]
	param
	(
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Path
	)
	
	# Get the item at the path.
	$item = Get-Item -Path $Path -ErrorAction Ignore
	
	# If there is no item, return.
	if ($null -eq $item)
	{
		return $true
	}
	
	try
	{
		# Calling 'Remove-Item' on a symbolic-link will delete the original items the link points to;
		# calling 'Delete()' will only destroy the symbolic-link iteself;
		# whilst calling 'Delete()' on a folder will not delete it's contents.
		# Therefore check whether the item is a symbolic-link or not to call the appropriate method.
		if ($item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint))
		{
			$item.Delete()
		}
		else
		{
			Remove-Item -Path $Path -Force -Recurse -ErrorAction Stop -WhatIf:$false -Confirm:$false | Out-Null
		}
	}
	catch
	{
		return $false
	}
	
	return $true
}