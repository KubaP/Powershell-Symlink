function WriteHeader
{
	param
	(
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Message,
		
		[Parameter(Position = 1)]
		[string]
		[ValidateSet("Red", "Green", "Blue", "Cyan", "Magenta", "Yellow", "Bold", "Black")]
		$Colour
	)
	
	# Store the colour to be able to revert back to it.
	$previousColour = [System.Console]::ForegroundColor
	
	# Set the appropriate foreground text colour.
	switch ($Colour)
	{
		"Red" 		{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Red }
		"Green" 	{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Green }
		"Blue" 		{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Blue }
		"Cyan" 		{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Cyan }
		"Magenta" 	{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Magenta }
		"Yellow" 	{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Yellow }
		"Bold" 		{ [System.Console]::ForegroundColor = [System.ConsoleColor]::White }
		"Black" 	{ [System.Console]::ForegroundColor = [System.ConsoleColor]::Black }
	}
	
	# Add some extra spacing to either side of the message.
	$length = $Message.Length + 2
	
	# Write the top border.
	Write-Host "+" -NoNewline
	for ($i = 0; $i -lt $length; $i++)
	{
		Write-Host "-" -NoNewline
	}
	Write-Host "+"
	
	# Write the text.
	Write-Host "| " -NoNewline
	Write-Host $Message -NoNewline
	Write-Host " |"
	
	# Write the bottom border.
	Write-Host "+" -NoNewline
	for ($i = 0; $i -lt $length; $i++)
	{
		Write-Host "-" -NoNewline
	}
	Write-Host "+"
	
	# Set the colour back to "normal".
	[System.Console]::ForegroundColor = $previousColour
}