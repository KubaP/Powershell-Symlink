# Tab expansion assignements for commands.

$argCompleter_SymlinkName =
{
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
	
	# Import all objects from the database file.
	$linkList = Read-Symlinks
	
	if ($linkList.Count -eq 0)
	{
		Write-Output ""
	}
	
	# Return the names which match the currently typed in pattern.
	# This first strips the string of any quotation marks, then matches it to 
	# the valid names, and then inserts the quotation marks again.
	# This is necessary so that strings with spaces have quotes, otherwise
	# they will not be treated as one parameter.
	$linkList.Name | Where-Object { $_ -like "$($wordToComplete.Replace(`"`'`", `"`"))*" } | ForEach-Object { "'$_'" }
	
}

Register-ArgumentCompleter -CommandName Get-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Set-Symlink -ParameterName Name -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Remove-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName
Register-ArgumentCompleter -CommandName Build-Symlink -ParameterName Names -ScriptBlock $argCompleter_SymlinkName