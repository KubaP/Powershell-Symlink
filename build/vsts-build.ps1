<#
.SYNOPSIS
	Builds the source code into a module package.
	
.DESCRIPTION
	Compiles all the module source code into a package. All code gets inserted
	into the main .psm1 file.
	
.PARAMETER ApiKey
	The key for publishing to a repository (e.g. PSGallery).
	
.PARAMETER WorkingDirectory
	The root folder for the whole project, containing the git files, build
	files, module files, etc.
  ! If running on Azure, don't specify any value.
	
.PARAMETER Repository
	The repository to publish to, by default the PSGallery.
	
.PARAMETER TestRepo
	Publish to the TESTING PSGallery instead.
	
.PARAMETER SkipPublish
	Don't perform the publishing action.
	
.PARAMETER SkipArtifact
	Don't package the module into a zipped file.
	
.EXAMPLE
	PS C:\> .\build\vsts-build.ps1 -WorkingDirectory .\ -SkipPublish
	
	This is to just build and package the module locally.
	
.EXAMPLE
	PS C:\> .\build\vsts-build.ps1 -WorkingDirectory .\ -SkipArtifact
				-TestRepo -ApiKey ...
	
	This is to build and package the module to the TESTING PSGallery. Use this
	for testing purposes.
	
.EXAMPLE
	PS C:\> .\build\vsts-build.ps1 -ApiKey ...
	
	This is to build and package the module to the REAL PSGallery, and to 
	package the module as a zip (for later use in uploading to the Github
	Release page).
	
.NOTES
	
#>
param (
	[string]
	$ApiKey,
	
	[string]
	$WorkingDirectory,
	
	[string]
	$Repository = 'PSGallery',
	
	[switch]
	$TestRepo,
	
	[switch]
	$SkipPublish,
	
	[switch]
	$SkipArtifact
)

# Import helper functions.
. "$PSScriptRoot\vsts-helpers.ps1"

# Handle Working Directory paths within Azure pipelines.
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else {
		$WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
	}
}

# Make any error stop this build process.
$ErrorActionPreference = 'Stop'

# Import required modules.
WriteHeader -Message "Importing PowershellGet Module" -Colour Cyan
Import-Module "PowershellGet" -RequiredVersion "2.2.2" -Verbose
# Print the loaded module information to make it easier for error diagnostics
# on the azure shell.
Get-Module -Verbose

# Create the publish folder.
WriteHeader -Message "Creating and populating publishing directory" -Colour Cyan
Remove-Item -Path "$WorkingDirectory\publish" -Force -Recurse | Out-Null
$publishDir = New-Item -Path $WorkingDirectory -Name "publish" -ItemType Directory -Force -Verbose

# Copy the module files from the root git repository to the publish folder.
# Only copy the files which don't get "compiled", i.e. the module files
# themselves, the help documentation, and the xml definitions.
# The content of the actual code files will get compiled into the module file.
New-Item -Path $publishDir.FullName -Name "Symlink" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$WorkingDirectory\Symlink\*" -Destination "$($publishDir.FullName)\Symlink\" `
	-Recurse -Force -Exclude "tests","internal","functions" -Verbose

# Gather text data from scripts for compilation.
WriteHeader -Message "Gathering code from function files." -Colour Cyan
$text = @()
$processed = @()

# Gather stuff to run within the module before the main logic.
foreach ($line in (Get-Content "$PSScriptRoot\filesBefore.txt" | Where-Object { $_ -notlike "#*" })) {
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Resolve the paths to be relative to the publish directory.
	$basePath = Join-Path "$WorkingDirectory\Symlink" $line
	
	# Get each file specified by the current line inside of filesBefore.txt
	foreach ($entry in (Resolve-Path -Path $basePath)) {
		# Get the file, discard if it's a folder.
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		# Only process each file once.
		if ($item.FullName -in $processed) { continue }
		
		# Add the text content and mark as processed.
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}

# Gather commands of all public and internal functions.
Get-ChildItem -Path "$WorkingDirectory\Symlink\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)	
}
Get-ChildItem -Path "$WorkingDirectory\Symlink\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather stuff to run within the module after the main logic.
foreach ($line in (Get-Content "$PSScriptRoot\filesAfter.txt" | Where-Object { $_ -notlike "#*" })) {
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Resolve the paths to be relative to the publish directory.
	$basePath = Join-Path "$WorkingDirectory\Symlink" $line
		
	# Get each file specified by the current line inside of filesAfter.txt
	foreach ($entry in (Resolve-Path -Path $basePath)) {
		# Get the file, discard if it's a folder.
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		# Only process each file once.
		if ($item.FullName -in $processed) { continue }
		
		# Add the text content and mark as processed.
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}

# Update the .psm1 file with all the read-in text content.
# This is done to reduce load times for the module, if all code is within the 
# single .psm1 file.
WriteHeader -Message "Inserting the code into the module file" -Colour Cyan
$fileData = Get-Content -Path "$($publishDir.FullName)\Symlink\Symlink.psm1" -Raw
# Change the complied flag to true.
$fileData = $fileData.Replace('"<was not built>"', '"<was built>"')
# Paste the text picked up from all files into the .psm1 main file, and save.
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\Symlink\Symlink.psm1", $fileData, [System.Text.Encoding]::UTF8)

if (-not $SkipPublish) {
	if ($TestRepo) {
		# Publish to TESTING PSGallery.
		WriteHeader -Message "TEST Publishing to PSGallery" -Colour Green
		
		# Register testing repository.
		Register-PSRepository -Name "test-repo" -SourceLocation "https://www.poshtestgallery.com/api/v2" `
			-PublishLocation "https://www.poshtestgallery.com/api/v2/package" -InstallationPolicy Trusted -Verbose `
			-ErrorAction 'Continue'
		Publish-Module -Path "$($publishDir.FullName)\Symlink" -NuGetApiKey $ApiKey -Force `
			-Repository "test-repo" -Verbose
		
		WriteHeader -Message "Waiting 60 seconds before testing download" -Colour Green
		Start-Sleep -Seconds 60
		
		# Uninstall the module if it already exists, to then test the
		# installation of the module from the test PSGallery.
		WriteHeader -Message "Installing module from PSGallery" -Colour Green
		Uninstall-Module -Name "Symlink" -Force -Verbose -ErrorAction 'Continue'
		Install-Module -Name "Symlink" -Repository "test-repo" -Force -AcceptLicense -SkipPublisherCheck -Verbose
		Write-Host "Test Symlink module installed." -ForegroundColor Green
		
		# Test if the module has been downloaded and imported correctly.
		WriteHeader -Message "Importing module" -Colour Green
		Import-Module -Name "Symlink" -Verbose
		Get-Module -Verbose
		
		# Remove the testing repository.
		Unregister-PSRepository -Name "test-repo" -Verbose
	}
	else {
		# Publish to real repository.
		WriteHeader -Message "Publishing to $Repository" -Colour Green
		Publish-Module -Path "$($publishDir.FullName)\Symlink" -NuGetApiKey $ApiKey -Force `
			-Repository $Repository -Verbose
	}
}

if (-not $SkipArtifact) {
	# Get the module version number for file labelling.
	$moduleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot\..\Symlink\Symlink.psd1").ModuleVersion
	
	# Move the module contents to a version-labelled subfolder.
	WriteHeader -Message "Creating Artifact. Moving content to version subfolder" -Colour Magenta
	New-Item -ItemType Directory -Path "$($publishDir.FullName)\Symlink\" -Name "$moduleVersion" -Force | Out-Null
	Move-Item -Path "$($publishDir.FullName)\Symlink\*" `
		-Destination "$($publishDir.FullName)\Symlink\$moduleVersion\" -Exclude "*$moduleVersion*" -Force -Verbose
	
	# Create a packaged zip file of the module folder.
	WriteHeader -Message "Packaging module into archive" -Colour Magenta
	Compress-Archive -Path "$($publishDir.FullName)\Symlink" `
		-DestinationPath "$($publishDir.FullName)\Symlink-v$($moduleVersion).zip" -Verbose
	
	# Write out the module number as a azure pipeline variable for the 
	# later run publish task.
	Write-Host "##vso[task.setvariable variable=version;isOutput=true]$moduleVersion"
}
