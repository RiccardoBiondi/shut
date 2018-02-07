#!/usr/bin/env pwsh

Function install_blender
{
    Param (
            [String] $url,
            [String] $path,
            [Bool] $add2path,
            [Parameter(Mandatory=$false, ValueFromRemainingArguments=$false)]
            [String[]] $modules
            )
    Push-Location
    Set-Location $path

    Write-Host download blender from $url
    $out_dir = $url.split('/')[-1]
    $ver = $out_dir.split('-')[1]
    $out = $out_dir.Substring(0, $out_dir.Length - 4) # remove extension (.zip)

    $Job = Start-BitsTransfer -Source $url -Asynchronous
    while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) `
    { sleep 5;} # Poll for status, sleep for 5 seconds, or perform an action.

    Switch($Job.JobState)
    {
        "Transferred" {Complete-BitsTransfer -BitsJob $Job}
        "Error" {$Job | Format-List } # List the errors.
        default {"Other action"} #  Perform corrective action.
    }

    Write-Host unzip $out_dir
    Expand-Archive $out_dir -DestinationPath blender
    Remove-Item $out_dir -Force -Recurse -ErrorAction SilentlyContinue
    Set-Location blender
    $dir_name = Get-ChildItem blender* -Name

    If( $add2path )
    {
        $Documents = [Environment]::GetFolderPath('MyDocuments')
        -join('$env:PATH = $env:PATH', " + `";$PWD\blender\$dir_name`"") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
    }
    $env:PATH = $env:PATH + ";$PWD\blender\$dir_name"

    $url = "https://bootstrap.pypa.io/get-pip.py"
    Set-Location $dir_name/$ver/python/bin
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
    $bpy = Get-ChildItem "python*.exe" -Name
    & ./$bpy get-pip.py
    Remove-Item get-pip.py -Force -ErrorAction SilentlyContinue

    Set-Location ..\Scripts\

    Foreach ( $i in $modules )
    {
        ./pip.exe install $i
    }

    Pop-Location
}

