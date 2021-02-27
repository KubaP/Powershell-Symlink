# Add all things you want to run before importing the main code.

# Load classes/enums.
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\classes" -Filter "*.ps1" -Recurse `
	-ErrorAction Ignore))
{
	. Import-ModuleFile -Path $file.FullName
}
