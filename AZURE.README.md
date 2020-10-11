# Azure pipelines set-up

1. Create devCI pipeline

    branch: development

    Windows Powershell Job
        Powershell job - Prerequisites
            Path: build/vsts-prerequisites.ps1
        Powershell job - Validate
            Path: build/vsts-validate.ps1
        Publish Test Results
            Format: NUnit
            Title: Powershell 5.1 Tests
            Run: Even if failed, even if cancelled
            
    Use powershell core for all tasks \/
    Powershell Core Job
        Powershell job - Prerequisites
            Path: build/vsts-prerequisites.ps1
        Powershell job - Validate
            Path: build/vsts-validate.ps1
        Publish Test Results
            Format: NUnit
            Title: Powershell 5.1 Tests
            Run: Even if failed, even if cancelled
        Publish Code Coverage
            File: $(System.DefaultWorkingDirectory)/**/CodeCov-*.xml
            Source path: $(System.DefaultWorkingDirectory)/
            Run: Even if failed, even if cancelled
            
    Triggers
        Enable CI for development branch
        

2. Create devPR pipeline

    Same as above but

    Triggers
        Enable PR for development branch.
        Disable fork option
    
    
3. Create masterRP pipeline

    Same as above but, use master branch for all
    

4. Create featureCI pipeline

    Same as devCI but 
    
    Triggers
        Enable CI for feature/* branch
        
    
5. Create release pipeline

    Artifact
        Github repo
        Branch: master
        Version: Latest from default branch
        
    Stage Build
        Powershell job - Build Prerequisites
            Path: $(System.DefaultWorkingDirectory)/_KubaP_Powershell-ProgramManager/build/vsts-build-prerequisites.ps1
            Use Powershell Core
        Powershell job - Build
            Path: $(System.DefaultWorkingDirectory)/_KubaP_Powershell-ProgramManager/build/vsts-build.ps1
            User powershell core
            Output Variables: BuildOutput
        Github Create Release
            Repo: github repo
            Source: User specific tag
            Tag: v$(BuildOutput.version)
            Title: Symlink v$(BuildOutput.version)
            Assets: $(System.DefaultWorkingDirectory)/_KubaP_Powershell-Symlink/publish/Symlink-v$(BuildOutput.version).zip
            Add changelog - NO
            Prerelease - YES
            
            
    Pipeline Variables
        system.debug = true
        ApiKey = # generate new api key from gallery