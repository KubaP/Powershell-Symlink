# Changelog
## 0.1.1 (2020-10-17)
 - Add: should_process: Support for most commands to use the -WhatIf and -Confirm switches.
 - Update: about_pages: Add information regarding common parameters.
 - Update: help_descriptions: Extra examples for all commands.
 - Update: stream_output: Improve verbose logging to make it clearer and more succinct.
 - Update: New-Symlink: Outputs the newly-created \[Symlink\] object at the end.
 - Fix: Build-Symlink: Error when calling now-removed method on the \[Symlink\] object.
 - Fix: stream_output: Only sets the $error variable if a "true" error has occurred.
## 0.1.0 (2020-10-14)
 - Add: New-Symlink: Allows for defining a new symlink object, and creating it on the filesystem.
 - Add: Get-Symlink: Allows for retrieving an existing symlink object, and displaying it to the screen or piping it to other commands.
 - Add: Set-Symlink: Allows for changing the properties on an existing symlink object, and accordingly updates the item on the filesystem.
 - Add: Remove-Symlink: Allows for deleting an existing symlink, including the item on the filesystem.
 - Add: Build-Symlink: Allows for creating/re-creating/updating symlink items on the filesystem.
 - Add: about_pages: Includes all details regarding command invocations, general module information, and key data points.
 - Add: help_descriptions: Thorough descriptions of all commands along with multiple examples and important notes.
 - Add: tab_completion: Tab completion functionality for all commands for appropriate parameters.
 - Add: \[Symlink\]: Implementation of symlink logic as part of a custom object with appropriate public getters/setters for properties and methods.
 - Add: Format.ps1xml: Custom formatting for the symlink object, supporting all 4 formatting views. Also included alternative formatting outputs if running in certain terminals, for enhanced readability.