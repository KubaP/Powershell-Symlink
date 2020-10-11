# Tab expansion assignements for commands.

<# $argCompleter_DataName = {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Import all data objects from the database file.
	$list = Read-Data
	
	# If no data, just return an empty string.
	if ($list.Count -eq 0) {
		Write-Output ""
	}
	
	# Return the names which match the currently typed in pattern.
	# This first removes any ' characters from the entered word, then performs
	# the "likeness" check, and then surrounds the word in '' quotes so that
	# any names containing spaces get properly entered.
	$list.Name | Where-Object { $_ -like "$($wordToComplete.Replace(`"`'`", `"`"))*" } | ForEach-Object { "'$_'" }
} #>

# Register-ArgumentCompleter -CommandName ... -ParameterName ... -Scriptblock ...

