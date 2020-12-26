<#
.SYNOPSIS
	Changes a value of a symlink item.
	
.DESCRIPTION
	The `Set-Symlink` cmdlet changes the value of a symlink.
	
.PARAMETER Name
	Specifies the name of the symlink to be changed.
	
 [!]This parameter will autocompleted to valid names for a symlink.

.PARAMETER Property
	Specifies the name of the property to change.
	
 [!]This parameter will autocompleted to the following: "Name", "Path",
	"Target", "CreationCondition".
	
.PARAMETER Value
	Specifies the new value of the property being changed.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.INPUTS
	System.String
		You can pipe the name of the symlink to change.
	
.OUTPUTS
	None
	
.NOTES
	For detailed help regarding the creation condition scriptblock, see
	the "CREATION CONDITION SCRIPTBLOCK" section in help at: 'about_Symlink'.
	
	This command is aliased by default to 'ssl'.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Name" -Value "WORK"
	
	Changes the name of a symlink definition named "data", to the new name
	of "WORK". From now on, there is not symlink named "data" anymore, and that
	name is free for future use.
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Path" -Value "~\Desktop\Files"
	
	Changes the path of the symlink definition named "data", to a new value
	located in the user's desktop folder. The old symbolic-link item at the
	previous location will be deleted from the filesystem, and a new item will
	be created at the new location.

.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "Target" -Value "D:\new\target"
	
	Changes the target of the symlink definition named "data", to a new value
	on the "D:\" drive. The existing symbolic-link item on the filesystem will
	have its target updated to this new value, (technically involves deleting
	and re-creating the item since the target cannot be modified).
	
.EXAMPLE
	PS C:\> Set-Symlink -Name "data" -Property "CreationCondition" 
			 -Value { return $false }
			 
	Changes the creation condition of the symlink definition named "data", to
	a new scriptblock which always returns $FALSE. This will not delete the
	existing symbolic-link item on the filesystem, even though if the condition
	was evaluated now, it would return false.
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function Set-Symlink
{
	[Alias("ssl")]
	
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		# Tab completion.
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[ValidateSet("Name", "Path", "Target", "CreationCondition")]
		[string]
		$Property,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[AllowNull()]
		$Value
		
	)
	
	process
	{
		# Read in the existing symlinks.
		$linkList = Read-Symlinks
		
		Write-Verbose "Changing the symlink: '$Name'."
		# If the link doesn't exist, warn the user.
		$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
		if ($null -eq $existingLink)
		{
			Write-Error "There is no symlink called: '$Name'."
			return
		}
		
		# Modify the property values.
		if ($Property -eq "Name")
		{
			Write-Verbose "Changing the name to: '$Value'."
			
			# Validate that the new name is valid.
			if ([System.String]::IsNullOrWhiteSpace($Name))
			{
				Write-Error "The name cannot be blank or empty!"
				return
			}
			# Validate that the new name isn't already taken.
			$clashLink = $linkList | Where-Object { $_.Name -eq $Value }
			if ($null -ne $clashLink)
			{
				Write-Error "The name: '$Value' is already taken!"
				return
			}
			
			$existingLink.Name = $Value
		}
		elseif ($Property -eq "Path")
		{
			Write-Verbose "Changing the path to: '$Value'."
			# First delete the symlink at the original path.
			if ($PSCmdlet.ShouldProcess($existingLink.FullPath(), "Delete Symbolic-Link"))
			{
				$existingLink.DeleteFile()
			}
			
			# Then change the path property, and re-create the symlink
			# at the new location.
			# TODO: Check the path isnt null.
			$existingLink._Path = $Value
			if ($PSCmdlet.ShouldProcess($existingLink.FullPath(), "Create Symbolic-Link"))
			{
				$existingLink.CreateFile()
			}
		}
		elseif ($Property -eq "Target")
		{
			Write-Verbose "Changing the target to: '$Value'."
			
			# Validate that the target exists.
			if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Value)) `
					-ErrorAction Ignore))
			{
				Write-Error "The target path: '$Value' points to an invalid location!"
				return
			}
			
			# Change the target property, and edit the existing symlink (re-create).
			$existingLink._Target = $Value
			if ($PSCmdlet.ShouldProcess($existingLink.FullPath(), "Update Symbolic-Link target"))
			{
				$existingLink.CreateFile()
			}
		}
		elseif ($Property -eq "CreationCondition")
		{
			Write-Verbose "Changing the creation condition."
			
			$existingLink._Condition = $Value
			# TODO: Operate if condition result is different from previous state.
		}
		
		# Re-export the list.
		if ($PSCmdlet.ShouldProcess("$script:DataPath", "Overwrite database with modified one"))
		{
			Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false | Out-Null
		}
	}
}