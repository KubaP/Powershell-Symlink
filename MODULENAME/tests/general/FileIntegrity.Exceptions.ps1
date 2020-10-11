# List of forbidden commands.
$global:BannedCommands = @(	
	# Use CIM instead where possible.
	'Get-WmiObject',
	'Invoke-WmiMethod',
	'Register-WmiEvent',
	'Remove-WmiObject',
	'Set-WmiInstance'
)

<#
	Contains list of exceptions for banned cmdlets.
	Insert the file names of files that may contain them.
	
	Example:
	"Write-Host"  = @('Write-PSFHostColor.ps1','Write-PSFMessage.ps1')
#>
$global:MayContainCommand = @{
	
}