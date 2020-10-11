param (
	# Key for publishing to PSGallery.
	$ApiKey,
	
	# The root folder for the whole project, containing the git files, build files, module files etc.
	# If running locally, specify it to the project root folder.
	# If running on Azure, don't specify anything.
	$WorkingDirectory,
	
	# Repository to publish to. By default it's the PSGallery.
	$Repository = 'PSGallery',
	
	# Publish to the testing PSGallery instead.
	[switch]
	$TestRepo,
	
	# Build only, don't publish.
	[switch]
	$SkipPublish,
	
	# Build but don't create artifacts.
	[switch]
	$SkipArtifact
	
)

# Handle Working Directory paths within Azure pipelines.
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else {
		$WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
	}
}

# Import required modules.
Write-Host "Importing required modules." -ForegroundColor Cyan
Import-Module "PowershellGet" -RequiredVersion "2.2.2" -Verbose
# Print the loaded module information to make it easier for error diagnostics
# on the azure shell.
Get-Module -Verbose

# Prepare the publish folder.
Write-Host "Creating and populating publishing directory." -ForegroundColor Cyan
Remove-Item -Path "$WorkingDirectory\publish" -Force -Recurse
$publishDir = New-Item -Path $WorkingDirectory -Name "publish" -ItemType Directory -Force

# Copy the module files from the root git repository to the publish folder.
New-Item -Path $publishDir.FullName -Name "<MODULENAME>" -ItemType Directory -Force | Out-Null
Copy-Item -Path "$($WorkingDirectory)\<MODULENAME>\*" -Destination "$($publishDir.FullName)\<MODULENAME>\" `
	-Recurse -Force -Exclude "*tests*"

# Gather text data from scripts to compile.
$text = @()
$processed = @()

# Gather stuff to run within the module before the main logic.
foreach ($line in (Get-Content "$($PSScriptRoot)\filesBefore.txt" | Where-Object { $_ -notlike "#*" })) {
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Resolve the paths to be relative to the publish directory.
	$basePath = Join-Path "$($publishDir.FullName)\<MODULENAME>" $line
	
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
Get-ChildItem -Path "$($publishDir.FullName)\<MODULENAME>\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)	
}
Get-ChildItem -Path "$($publishDir.FullName)\<MODULENAME>\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather stuff to run within the module after the main logic.
foreach ($line in (Get-Content "$($PSScriptRoot)\filesAfter.txt" | Where-Object { $_ -notlike "#*" })) {
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	# Resolve the paths to be relative to the publish directory.
	$basePath = Join-Path "$($publishDir.FullName)\<MODULENAME>" $line
		
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
$fileData = Get-Content -Path "$($publishDir.FullName)\<MODULENAME>\<MODULENAME>.psm1" -Raw
# Change the complied flag to true.
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
# Paste the text picked up from all files into the .psm1 main file, and save.
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\<MODULENAME>\<MODULENAME>.psm1", $fileData, [System.Text.Encoding]::UTF8)

if (-not $SkipPublish) {
	if ($TestRepo) {
		# Publish to TESTING PSGallery.
		Write-Host "Publishing the <MODULENAME> module to TEST PSGallery." -ForegroundColor Cyan
		
		# Register testing repository.
		Register-PSRepository -Name "test-repo" -SourceLocation "https://www.poshtestgallery.com/api/v2" `
			-PublishLocation "https://www.poshtestgallery.com/api/v2/package" -InstallationPolicy Trusted -Verbose
		Publish-Module -Path "$($publishDir.FullName)\<MODULENAME>" -NuGetApiKey $ApiKey -Force `
			-Repository "test-repo" -Verbose
		
		Write-Host "Published package to test repo. Waiting 30 seconds." -ForegroundColor Cyan
		Start-Sleep -Seconds 30
		
		# Uninstall module if it already exists, to then test the installation 
		# of the module from the test PSGallery.
		Uninstall-Module -Name "<MODULENAME>" -Force -Verbose
		Install-Module -Name "<MODULENAME>" -Repository "test-repo" -Force -AcceptLicense -SkipPublisherCheck -Verbose
		Write-Host "Test <MODULENAME> module installed."
		
		# Remove the testing repository.
		Unregister-PSRepository -Name "test-repo" -Verbose
	}
	else {
		# Publish to real repository.
		Write-Host "Publishing the <MODULENAME> module to $($Repository)." -ForegroundColor Cyan
		Publish-Module -Path "$($publishDir.FullName)\<MODULENAME>" -NuGetApiKey $ApiKey -Force `
			-Repository $Repository -Verbose
	}
}

if (-not $SkipArtifact) {
	# Get the module version number for file labelling.
	$moduleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot\..\<MODULENAME>\<MODULENAME>.psd1").ModuleVersion
	
	# Move the module contents to a version labelled folder structure.
	New-Item -ItemType Directory -Path "$($publishDir.FullName)\<MODULENAME>\" -Name "$moduleVersion" -Force
	Move-Item -Path "$($publishDir.FullName)\<MODULENAME>\*" `
		-Destination "$($publishDir.FullName)\<MODULENAME>\$moduleVersion\" -Exclude "*$moduleVersion*" -Force -Verbose
	
	# Create a packaged zip file of the module.
	Write-Host "Packaging module to archive." -ForegroundColor Cyan
	Compress-Archive -Path "$($publishDir.FullName)\<MODULENAME>" `
		-DestinationPath "$($publishDir.FullName)\<MODULENAME>-v$($moduleVersion).zip" -Verbose
	
	# Write out the module number as a azure pipeline variable for publish task.
	Write-Host "##vso[task.setvariable variable=version;isOutput=true]$moduleVersion"
}
