#!/usr/bin/env pwsh

Function install_pip
{
    Param (
            [Parameter(Mandatory=$true, Position=0)]
            [String] $path
            )
    Push-Location
    Set-Location $path

    $url = "https://bootstrap.pypa.io/get-pip.py"
    Write-Host "Download get-pip from https://bootstrap.pypa.io/get-pip.py"
    $Job = Start-BitsTransfer -Source $url -Asynchronous
    while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) `
    { sleep 5;} # Poll for status, sleep for 5 seconds, or perform an action.

    Switch($Job.JobState)
    {
        "Transferred" {Complete-BitsTransfer -BitsJob $Job}
        "Error" {$Job | Format-List } # List the errors.
        default {"Other action"} #  Perform corrective action.
    }

    Write-Host "Run get-pip"
    If( -Not (Get-Command python -ErrorAction SilentlyContinue) ){ Write-Host "python NOT FOUND"; exit}
    Else{ python $PWD\get-pip.py }
    
    Pop-Location
}
