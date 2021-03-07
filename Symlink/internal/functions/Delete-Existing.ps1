<#
.SYNOPSIS
	Deletes an existing item from the filesystem safetly.
	
.DESCRIPTION
	Deletes an existing item from the filesystem safetly.
	
.PARAMETER Path
	The path of the item to attempt to delete.
	
.EXAMPLE
	PS C:\> $return = Delete-Existing -Path "~\link1"
	
	Attempts to delete the item at "~\link1".
	
.INPUTS
	None
	
.OUTPUTS
	Boolean
		Whether the operation was completed successfully, and the item is now
		gone from the filesystem.
		
.NOTES
	If the item doesn't exist, this will return $true.
	If the item was successfully deleted, this will return $true.
	If the item couldn't be deleted because an exception was thrown, this will
	return $false.
	
#>
function Delete-Existing
{
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
	[CmdletBinding()]
	[OutputType([Boolean])]
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