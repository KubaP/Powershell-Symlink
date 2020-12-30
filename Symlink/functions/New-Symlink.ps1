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
	
	Creates a new symlink definition named "data", and also creates the 
	symbolic-link item in the user's document folder under "Data", pointing to a
	location on the "D:\" drive.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "data" -Path ~\Documents\Data -Target D:\Files
			 -CreationCondition $script -DontCreateItem
	
	Creates a new symlink definition named "data", giving it a creation
	condition to be evaluated. However, this will not create the symbolic-link
	item on the filesystem due to the use of the '-DontCreateItem' switch.
	
.EXAMPLE
	PS C:\> New-Symlink -Name "program" -Path ~\Documents\Program
			 -Target D:\Files\my_program -MoveExistingItem
				
	Creates a new symlink definition named "program", and also creates the 
	symbolic-link item in the user's document folder under the name "Program",
	pointing to a location on the "D:\" drive. By using the '-MoveExistingItem'
	switch, the "~\Documents\Program" folder will be moved into the "D:\Files" 
	folder and renamed to "my_program".
	
.LINK
	Get-Symlink
	Set-Symlink
	Remove-Symlink
	about_Symlink
	
#>
function New-Symlink
{
	[Alias("nsl")]
	
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
		$DontCreateItem,
		
		[Parameter()]
		[switch]
		$Force
		
	)
	
	# Validate that '-WhatIf'/'-Confirm' isn't used together with '-Force'.
	# This is ambiguous, so warn the user instead.
	Write-Debug "`$WhatIfPreference: $WhatIfPreference"
	Write-Debug "`$ConfirmPreference: $ConfirmPreference"
	if ($WhatIfPreference -and $Force)
	{
		Write-Error "You cannot specify both '-WhatIf' and '-Force' in the invocation for this cmdlet!"
		return
	}
	if (($ConfirmPreference -eq "Low") -and $Force)
	{
		Write-Error "You cannot specify both '-Confirm' and '-Force' in the invocation for this cmdlet!"
		return
	}
	
	# Validate that the name isn't empty.
	Write-Verbose "Validating parameters."
	if ([system.string]::IsNullOrWhiteSpace($Name))
	{
		Write-Error "The name cannot be blank or empty!"
		return
	}
	
	$expandedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
	$expandedTarget = [System.Environment]::ExpandEnvironmentVariables($Target)
	
	# Validate that the target location exists, assuming the item isn't
	# being moved there as part of the command.
	if (-not (Test-Path -Path $expandedTarget -ErrorAction Ignore) -and -not $MoveExistingItem)
	{
		Write-Error "The target path: '$Target' points to an invalid/non-existent location!"
		return
	}
	if (-not (Test-Path -Path (Split-Path -Path $expandedTarget -Parent) -ErrorAction Ignore) `
		-and $MoveExistingItem)
	{
		Write-Error "Part of the target path: '$(Split-Path -Path $expandedTarget -Parent)' is invalid!"
		return
	}
	
	# Validate that the name isn't already taken.
	$linkList = Read-Symlinks
	$existingLink = $linkList | Where-Object { $_.Name -eq $Name }
	if ($null -ne $existingLink)
	{
		if ($Force)
		{
			Write-Verbose "Existing symlink named: '$Name' exists, but since the '-Force' switch is present, the existing symlink will be deleted."
			$existingLink | Remove-Symlink
		}
		else
		{
			Write-Error "The name: '$Name' is already taken."
			return
		}
	}
	
	if ((Test-Path -Path $expandedPath -ErrorAction Ignore) -and $MoveExistingItem -and $PSCmdlet.ShouldProcess("Moving and renaming existing item from '$expandedPath' to '$expandedTarget'.", "Are you sure you want to move and rename the existing item from '$expandedPath' to '$expandedTarget'?", "Move File Prompt")) 
	{
		# Move the item over to the target parent folder, and rename it
		# to the specified name name given in the target path.
		$fileName = Split-Path -Path $expandedPath -Leaf
		$newFileName = Split-Path -Path $expandedTarget -Leaf
		$targetFolder = Split-Path -Path $expandedTarget -Parent
		# Prevent error logging in `Move-Item` cmdlet due to same 
		# origin/destination.
		if ((Split-Path -Path $expandedPath -Parent) -ne $targetFolder)
		{
			try
			{
				Move-Item -Path $expandedPath -Destination $targetFolder -Force -ErrorAction Stop -WhatIf:$false `
					-Confirm:$false | Out-Null
			}
			catch
			{
				Write-Error "Could not move the existing item to the target destination.`nClose any programs which may be using this path and re-run the cmdlet."
				return
			}
		}
		
		try
		{
			Rename-Item -Path "$targetFolder\$filename" -NewName $newFileName -Force -ErrorAction Stop `
				-WhatIf:$false -Confirm:$false | Out-Null
		}
		catch
		{
			Write-Error "Could not rename the existing item to match the target path.`nClose any programs which may be using this path and re-run the cmdlet."
			return
		}
	}
	elseif (-not (Test-Path -Path $expandedPath -ErrorAction Ignore) -and $MoveExistingItem)
	{
		Write-Error "Cannot move the existing item from '$expandedPath' because the location is invalid."
		return
	}
	
	# Create the object and save it to the database.
	Write-Verbose "Creating new symlink object."
	if ($null -eq $CreationCondition)
	{
		$newLink = [Symlink]::new($Name, $Path, $Target)
	}
	else
	{
		$newLink = [Symlink]::new($Name, $Path, $Target, $CreationCondition)
	}
	$linkList.Add($newLink)
	if ($PSCmdlet.ShouldProcess("Saving newly-created symlink to database at '$script:DataPath'.", "Are you sure you want to save the newly-created symlink to the database at '$script:DataPath'?", "Save File Prompt"))
	{
		Export-Clixml -Path $script:DataPath -InputObject $linkList -Force -WhatIf:$false -Confirm:$false `
			| Out-Null
	}
	
	# Build the symbolic-link item on the filesytem.
	if (-not $DontCreateItem -and ($newLink.ShouldExist() -or $Force) -and $PSCmdlet.ShouldProcess("Creating symbolic-link item at '$expandedPath'.", "Are you sure you want to create the symbolic-link item at '$expandedPath'?", "Create Symbolic-Link Prompt"))
	{
		# Appropriately delete any existing items before creating the
		# symbolic-link.
		$item = Get-Item -Path $expandedPath -ErrorAction Ignore
		# Existing item may be in use and unable to be deleted, so retry until
		# the user has closed any programs using the item.
		while (Test-Path -Path $expandedPath)
		{
			try
			{
				# Calling `Remove-Item` on a symbolic-link will delete the
				# original items the link points to; calling Delete() will
				# only destroy the symbolic-link iteself, whilst calling
				# Delete() on a folder will not delete it's contents. Therefore
				# check whether the item is a symbolic-link to call the
				# appropriate method.
				if ($null -eq $item.LinkType)
				{
					Remove-Item -Path $expandedPath -Force -Recurse -ErrorAction Stop -WhatIf:$false `
						-Confirm:$false | Out-Null
				}
				else
				{
					$item.Delete()
				}
			}
			catch
			{
				Write-Error "The item located at '$expandedPath' could not be deleted to make room for the symbolic-link."
				Read-Host -Prompt "Close any programs using this path, and enter any key to retry"
			}
		}
		New-Item -ItemType SymbolicLink -Path $expandedPath -Value $expandedTarget -Force -WhatIf:$false `
			-Confirm:$false | Out-Null
	}
	
	Write-Output $newLink
}