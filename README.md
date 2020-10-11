# <MODULENAME>
Brief overview

Who module is aimed at

<br>

[![Azure DevOps builds](https://img.shields.io/azure-devops/build/KubaP999/3d9148d2-04d0-4835-b7cb-7bf89bdbf11b/7?label=latest%20build&logo=azure-pipelines)](https://dev.azure.com/KubaP999/ProgramManager/_build/latest?definitionId=7&branchName=development)
[![Azure DevOps coverage](https://img.shields.io/azure-devops/coverage/KubaP999/ProgramManager/7?logo=codecov&logoColor=white)](https://dev.azure.com/KubaP999/ProgramManager/_build/latest?definitionId=7&branchName=development)
[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/ProgramManager?logo=powershell&logoColor=white)](https://www.powershellgallery.com/packages/<ModuleName>)
![PowerShell Gallery Platform](https://img.shields.io/powershellgallery/p/ProgramManager?logo=windows)
[![License](https://img.shields.io/badge/license-GPLv3-blue)](./LICENSE)
Update the img urls

## Getting Started
### Installation
In order to get started with the latest build, simply download the module from the [PSGallery](https://www.powershellgallery.com/packages/<ModuleName>), or install it from powershell by running:
```powershell
Install-Module <ModuleName>
```
Installing this module does not mean that it is loaded automatically on start-up. Powershell supports loading modules on-the-fly since v3, however the first time you run a command it can be a bit slow to tab-complete parameters or values. If you would like to load this module on shell start-up, add the following line to `~/Documents/Powershell/Profile.ps1` :
```powershell
Import-Module <ModuleName>
```

### Requirements
This module requires minimum `Powershell 5.1`. Works with `Pwsh 6+` as well.
\[OR\]
This module requires minimum `Powershell 6`.

This module works on **Windows** only.
\[OR\]
This module works on `Windows`, `MacOS`, and `Linux`. 

⚠Only Windows is currently tested though.

## Usage
Usage instructions/ overview of commands

### Extra features
#### Tab completion
The functions support advanced tab-completion for values:
- Any `...` parameters support tab-completion.
- The `...` parameter supports tab-completion once a `...` is given in.

#### Custom scriptblock support
When adding a new package, you can pass in a scriptblock for `...`,`...` or `...`. These scriptblocks will execute during ...

For details, see `about_<MODULENAME>_scriptblocks`.

#### -WhatIf and -Confirm support
All functions in this module support these parameters when appropiate.

Use `-WhatIf` to see what changes a function will do.
Use `-Confirm` to require a prompt for every major change.

## Build Instructions
### Prerequisites
Install the following:
- Powershell Core 6.2.1
- Pester 4.9.0
- PSScriptAnalyzer 1.18.3

### Clone the git repo
```
git clone https://github.com/KubaP/Powershell-<MODULENAME>.git
```

### Run the build scripts

Run the following commands in this order:
```powershell
& .\build\vsts-prerequisites.ps1
& .\build\vsts-validate.ps1
& .\build\vsts-build.ps1 -WorkingDirectory .\ -SkipPublish
```
The built module will be located in the `.\publish` folder.

## Support
If there is a bug/issue please file it on the github issue tracker.

## Contributing
If you have a suggestion, create a new `Github Issue` detailing the idea.

Feel free to make pull requests if you have an improvement. Only submit a single feature at a time, and make sure that the code is cleanly formatted, readable, and well commented.

## License 
This project is licensed under the GPLv3 license - see [LICENSE.md](./LICENSE) file for details.

## Acknowledgements
Any acknowledgements...