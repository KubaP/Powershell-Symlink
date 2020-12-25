<#
.SYNOPSIS
	Creates a new symlink.
	
.DESCRIPTION
	The `New-Symlink` cmdlet creates a new symlink definition, and optionally
	also creates the symbolic-link item on the filesystem.
	
.PARAMETER Name
	Specifies the name of the symlink to be created; must be unique.
	
.PARAMETER Path
	Specifies the path of the location of the symbolic-link item. If any parent
	folders in this path don't exist, they will be created.
	
.PARAMETER Target
	Specifies the path of the target which the symbolic-link item points to.
	This also defines whether the symbolic-link points to a directory or a file.
	
.PARAMETER CreationCondition
	Specifies a scriptblock to be used for this symlink. This scriptblock
	decides whether the symbolic-link item should be created on the filesystem.
	For detailed help, see the "CREATION CONDITION SCRIPTBLOCK" section in 
	the help at: 'about_Symlink'.
	
.PARAMETER DontCreateItem
	Prevents the creation of the symbolic-link item on the filesystem.
	(The symlink definition will still be created).
	
.PARAMETER MoveExistingItem
	Specifies to move an already existing directory/file at the specifies path.
	This item will be moved to the specified target path rather than being
	deleted.
	
.PARAMETER WhatIf
	Shows what would happen if the cmdlet runs. The cmdlet does not run.
	
.PARAMETER Confirm
	Prompts you for confirmation before running any state-altering actions
	in this cmdlet.
	
.PARAMETER Force
	Forces this cmdlet to create an symlink that writes over an existing one.
	Even using this parameter, if the filesystem denies access to the
	necessary files, this cmdlet can fail.
	
.INPUTS
	None
	
.OUTPUTS
	Symlink
	
.NOTES
	For detailed help regarding the creation condition scriptblock, see
	the "CREATION CONDITION SCRIPTBLOCK" section in help at: 'about_Symlink'.
	
	This command is aliased by default to 'nsl'.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
	
	This command will create a new symlink definition, named "data", and a
	symbolic-link located in the user's document folder under a folder also
	named "data", pointing to a folder on the D:\ drive.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
				-CreationCondition $script -DontCreateItem
	
	This command will create a new symlink definition, named "data", but it
	will not create the symbolic-link on the filesystem. A creation condition
	is also defined, which will be evaluated when the 'Build-Symlink' command
	is run in the future.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "program" -Path ~\Documents\Program
				-Target D:\Files\my_program -MoveExistingItem
				
	This command will first move the folder 'Program' from '~\Documents' to 
	'D:\Files', and then rename it to 'my_program'. Then the symbolic-link will
	be created.
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function New-Symlink
{
	[Alias("nsl")]
	# TODO: Add -Force switch to ignore the creation condition
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Position = 2, Mandatory = $true)]
		[string]
		$Target,
		
		[Parameter(Position = 3)]
		[scriptblock]
		$CreationCondition,
		
		[Parameter(Position = 4)]
		[switch]
		$MoveExistingItem,
		
		[Parameter(Position = 5)]
		[switch]
		$DontCreateItem
		
	)
	
	Write-Verbose "Validating name."
	# Validate that the name isn't empty.
	if ([System.String]::IsNullOrWhiteSpace($Name))
	{
		Write-Error "The name cannot be blank or empty!"
		return
	}
	
	# Validate that the target location exists.
	if (-not (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($Target)) `
			-ErrorAction Ignore) -and -not $MoveExistingItem)
	{
		Write-Error "The target path: '$Target' points to an invalid/non-existent location!"
		return
	}
	
	# Read in the existing symlink collection.
	$linkList = Read-Symlinks
	
	# Validate that the name isn't already taken.
	$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
	if ($null -ne $existingLink)
	{
		Write-Error "The name: '$Name' is already taken!"
		return
	}
	
	Write-Verbose "Creating new symlink object."
	# Create the new symlink object.
	if ($null -eq $CreationCondition)
	{
		$newLink = [Symlink]::new($Name, $Path, $Target)
	}
	else
	{
		$newLink = [Symlink]::new($Name, $Path, $Target, $CreationCondition)
	}
	# Add the new link to the list, and then re-export the list.
	$linkList.Add($newLink)
	if ($PSCmdlet.ShouldProcess("$script:DataPath", "Overwrite database with modified one"))
	{
		Export-Clixml -Path $script:DataPath -InputObject $linkList -WhatIf:$false -Confirm:$false | Out-Null
	}
	
	# Potentially move the existing item.
	if ((Test-Path -Path $Path) -and $MoveExistingItem)
	{
		if ($PSCmdlet.ShouldProcess("$Path", "Move existing item"))
		{
			# If the item needs renaming, split the filepaths to construct the
			# valid filepath.
			$finalPath = [System.Environment]::ExpandEnvironmentVariables($Target)
			$finalContainer = Split-Path -Path $finalPath -Parent
			$finalName = Split-Path -Path $finalPath -Leaf
			$existingPath = $Path
			$existingContainer = Split-Path -Path $existingPath -Parent
			$existingName = Split-Path -Path $existingPath -Leaf
			
			# Only rename the item if it needs to be called differently.
			if ($existingName -ne $finalName)
			{
				Rename-Item -Path $existingPath -NewName $finalName -WhatIf:$false -Confirm:$false
				$existingPath = Join-Path -Path $existingContainer -ChildPath $finalName
			}
			Move-Item -Path $existingPath -Destination $finalContainer -WhatIf:$false -Confirm:$false
		}
	}
	
	# Build the symlink item on the filesytem.
	if (-not $DontCreateItem -and $PSCmdlet.ShouldProcess($newLink.FullPath(), "Create Symbolic-Link"))
	{
		$newLink.CreateFile()
	}
	
	Write-Output $newLink
}