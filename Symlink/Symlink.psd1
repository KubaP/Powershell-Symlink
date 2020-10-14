@{
	# Script module or binary module file associated with this manifest
	RootModule = 'Symlink.psm1'
	
	# Version number of this module.
	ModuleVersion = '0.1.0'
	
	# ID used to uniquely identify this module
	GUID = '7849ff1f-d264-4a49-8de2-9c01e79a22a9'
	
	# Author of this module
	Author = 'KubaP'
	
	# Company or vendor of this module
	CompanyName = ''
	
	# Copyright statement for this module
	Copyright = 'Copyright (c) 2020 KubaP'
	
	# Description of the functionality provided by this module
	Description = 'Easy and central management of symbolic links on the filesystem, with many advanced features.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '6.0'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	<#!
	RequiredModules = @(
		@{ ModuleName='name'; ModuleVersion='1.0.0' }
	)#>
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\Symlink.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\Symlink.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\Symlink.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport = @(
		"New-Symlink",
		"Get-Symlink",
		"Set-Symlink",
		"Remove-Symlink",
		"Build-Symlink"
	)
	
	# Cmdlets to export from this module
	CmdletsToExport = ''
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = ''
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			# TODO: Add Mac/Linux tags once module confirmed working on those platforms.
			# TODO: Add PS_Desktop tag once module confirmed working on powershell 5.1.
			Tags = @("Windows","Symlink","Symbolic_Link","PSEdition_Core")
			
			# A URL to the license for this module.
			LicenseUri = 'https://www.gnu.org/licenses/gpl-3.0.en.html'
			
			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/KubaP/Powershell-Symlink'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/KubaP/Powershell-Symlink/blob/master/Symlink/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}