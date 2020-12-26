# Changelog
## 0.1.2 (2020-12-08)
 - New: alias: Added the 'nsl', 'gls', 'ssl', 'rsl', 'bsl' aliases for each respective exported cmdlet.
 - New: *'-MoveExistingItem'* for `Build-Symlink`: Switch to move existing item rather than deleting it. Saves time by removing need to manually move the contents to the target destination beforehand.
 - Update: Format.ps1xml: Improve formatting styles to present information more clearly and consistently. Modified custom-format view to show the in-depth properties of the object.
 - Fix: `[Symlink]`: ShortPath and ShortTarget methods incorrectly replacing strings when inserting environment variables.
## 0.1.1 (2020-10-17)
 - New: should_process: Support for the *'-WhatIf'* and *'-Confirm'* switches for the `New-`, `Set-`, `Remove-`, and `Build-` cmdlets.
 - Update: about_Symlink: Add information regarding common parameters to all examples and explanations.
 - Update: help_descriptions: Extra examples for all cmdlets.
 - Update: stream_output: Improve verbose logging to make it clearer and more succinct.
 - Update: `New-Symlink`: Outputs the newly-created `[Symlink]` object at the end of execution.
 - Fix: `Build-Symlink`: Error when calling legacy method on the `[Symlink]` object.
 - Fix: stream_output: Sets the powershell $global:error variable even if a "real" logic error hasn't occurred.
## 0.1.0 (2020-10-14)
 - New: `New-Symlink`: Allows for creating a new symlink definition, and creating the symbolic-link item on the filesystem.
 - New: `Get-Symlink`: Allows for retrieving an existing symlink, and displaying it to the screen or piping it to other cmdlets.
 - New: `Set-Symlink`: Allows for changing the properties on an existing symlink, and accordingly update the item on the filesystem.
 - New: `Remove-Symlink`: Allows for deleting an existing symlink, including the item on the filesystem.
 - New: `Build-Symlink`: Allows for creating/re-creating/updating symbolic-link items on the filesystem.
 - New: about_Symlink: Details the feature set of this module, and how to use it along with some examples.
 - New: help_descriptions: Contains descriptions of all cmdlets along with multiple examples for each and any important notes to know.
 - New: tab_completion: Tab completion functionality for parameters of all cmdlets where appropriate.
 - New: stream_output: Provides error logging, and verbose logging when using the *'-Verbose'* switch.
 - New: `[Symlink]`: Implementation of symlink logic as a custom object with appropriate public getters/setters for properties and methods.
 - New: Format.ps1xml: Custom formatting for the symlink object, supporting all 4 formatting views. Also included alternative formatting outputs if running in certain terminals, for enhanced readability.