﻿# Changelog
## 0.1.4 (2021-02-27)
 - Update: Format.ps1xml: Improve formatting styles to present information and the state of the symbolic-links in a clearer manner.
 - Fix: `New-Symlink`: Incorrectly throwing an error when using the *'-MoveExistingItem'* switch and when no renaming is necessary as the existing and desired item names are identical.
## 0.1.3 (2020-12-30)
 - Add: *'-Force'* for `New-Symlink`: Forces the creation of the symbolic-link even if the creation condition evaluates to false, and overwrites any existing symlink if the names collide.
 - Add: *'-Force'* for `Build-Symlink`: Forces the creation of the symbolic-link even if the creation condition evaluates to false.
 - Add: *'-Force'* for `Set-Symlink`: Forces the creation of the symbolic-link even if the creation condition evaluates to false, or overwrites any existing symlink if the names collide.
 - Add: `[Symlink]`: TargetState() method to get the status of the target field.
 - Update: Format.ps1xml: Improve formatting styles to present information more clearly and utilise colours better.
 - Update: stream_output: Improve verbose logging, remove a few unnecessary logs and add ones which were missing.
 - Update: should_process: Improve the messages and text, and add previously missing checks/logs.
 - Update: help_descriptions: Rewritten to be clearer and more consistent with the official powershell help, and to have a wider range of clearer examples, and added descriptors for the newly introduced switches.
 - Update: about_Symlink: Reformat the document layout, update descriptors to match new help_descriptions, and cleared up a few potentially unclear things.
 - Fix: *'-Value'* for `Set-Symlink`: Doesn't allow a $NULL value when setting the "Creation Condition" property.
 - Fix: `cmdlets`: Lack of many validations/checks in all cmdlets which could have led to cmdlets not working correctly 100% of the time.
 - Remove: `[Symlink]`: The CreateFile() and DeleteFile() methods. Now you must use the cmdlets for these purposes.
## 0.1.2 (2020-12-08)
 - Add: alias: Added the 'nsl', 'gls', 'ssl', 'rsl', 'bsl' aliases for each respective exported cmdlet.
 - Add: *'-MoveExistingItem'* for `Build-Symlink`: Switch to move existing item rather than deleting it. Saves time by removing need to manually move the contents to the target destination beforehand.
 - Update: Format.ps1xml: Improve formatting styles to present information more clearly and consistently. Modified custom-format view to show the in-depth properties of the object.
 - Fix: `[Symlink]`: ShortPath() and ShortTarget() methods incorrectly replacing strings when inserting environment variables.
## 0.1.1 (2020-10-17)
 - Add: should_process: Support for the *'-WhatIf'* and *'-Confirm'* switches for the `New-`, `Set-`, `Remove-`, and `Build-` cmdlets.
 - Update: about_Symlink: Add information regarding common parameters to all examples and explanations.
 - Update: help_descriptions: Extra examples for all cmdlets.
 - Update: stream_output: Improve verbose logging to make it clearer and more succinct.
 - Update: `New-Symlink`: Outputs the newly-created `[Symlink]` object at the end of execution.
 - Fix: `Build-Symlink`: Error when calling legacy method on the `[Symlink]` object.
 - Fix: stream_output: Sets the powershell $global:error variable even if a "real" logic error hasn't occurred.
## 0.1.0 (2020-10-14)
 - Add: `New-Symlink`: Allows for creating a new symlink definition, and creating the symbolic-link item on the filesystem.
 - Add: `Get-Symlink`: Allows for retrieving an existing symlink, and displaying it to the screen or piping it to other cmdlets.
 - Add: `Set-Symlink`: Allows for changing the properties on an existing symlink, and accordingly update the item on the filesystem.
 - Add: `Remove-Symlink`: Allows for deleting an existing symlink, including the item on the filesystem.
 - Add: `Build-Symlink`: Allows for creating/re-creating/updating symbolic-link items on the filesystem.
 - Add: about_Symlink: Details the feature set of this module, and how to use it along with some examples.
 - Add: help_descriptions: Contains descriptions of all cmdlets along with multiple examples for each and any important notes to know.
 - Add: tab_completion: Tab completion functionality for parameters of all cmdlets where appropriate.
 - Add: stream_output: Provides error logging, and verbose logging when using the *'-Verbose'* switch.
 - Add: `[Symlink]`: Implementation of symlink logic as a custom object with appropriate public getters/setters for properties and methods.
 - Add: Format.ps1xml: Custom formatting for the symlink object, supporting all 4 formatting views. Also included alternative formatting outputs if running in certain terminals, for enhanced readability.