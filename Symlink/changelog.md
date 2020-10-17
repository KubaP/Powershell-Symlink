# Changelog
## 0.1.1 (2020-10-17)
 - Update: about_pages: Add information regarding common parameters.
 - Update: help_descriptions: Extra examples for all commands.
 - Update: output: Improve verbose logging to make it clearer and more succinct.
 - Fix: Build-Symlink: Error when calling now-removed method on the \[Symlink\] object.
 - Add: should_process: Support for most commands to use the -WhatIf and -Confirm switches.
 - Update: New-Symlink: Outputs the newly-created \[Symlink\] object at the end.
 - Fix: error_status: Only sets the $error variable if a true error has occured.
## 0.1.0 (2020-10-14)
 - Added: New-Symlink: Allows for defining a new symlink object, and creating it on the filesystem.
 - Added: Get-Symlink: Allows for retrieving an existing symlink object, and displaying it to the screen or piping it to other commands.
 - Added: Set-Symlink: Allows for changing the properties on an existing symlink object, and accordingly updates the item on the filesystem.
 - Added: Remove-Symlink: Allows for deleting an existing symlink, including the item on the filesystem.
 - Added: Build-Symlink: Allows for creating/re-creating/updating symlink items on the filesystem.
 - Added: about_pages: Includes all details regarding command invocations, general module information, and key data points.
 - Added: help_descriptions: Thorough descriptions of all commands along with multiple examples and important notes.
 - Added: tab_completion: Tab completion functionality for all commands for appropriate parameters.
 - Added: \[Symlink\]: Implementation of symlink logic as part of a custom object with appropriate public getters/setters for properties and methods.
 - Added: Format.ps1xml: Custom formatting for the symlink object, supporting all 4 formatting views. Also included alternative formatting outputs if running in certain terminals, for enhanced readability.