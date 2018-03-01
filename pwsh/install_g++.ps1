#!/usr/bin/env pwsh

. ".\install_cmake.ps1"

Function get_g++
{
    Param (
            [Bool] $add2path
            )
    $url_gcc = "https://sourceforge.net/projects/msys2/files/Base/i686/msys2-base-i686-20161025.tar.xz"
    Write-Host download g++ from $url_gcc
    $Job = Start-BitsTransfer -Source $url_gcc -Asynchronous
    while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) `
    { sleep 5;} # Poll for status, sleep for 5 seconds, or perform an action.

    Switch($Job.JobState) {
        "Transferred" {Complete-BitsTransfer -BitsJob $Job}
        "Error" {$Job | Format-List } # List the errors.
        default {"Other action"} #  Perform corrective action.
    }

    If( -Not (Get-Command cmake -ErrorAction SilentlyContinue) ){ # cmake not installed
        install_cmake -add2path $true -confirm "-y"
    }
    cmake -E tar zxf msys2-base-i686-20161025.tar.xz
    Remove-Item msys2-base-i686-20161025.tar.xz -Force -Recurse -ErrorAction SilentlyContinue
    Set-Location msys32
    ./msys2_shell.cmd
    Start-Sleep -s 60
    ./usr/bin/pacman -Syuu --noconfirm
    ./usr/bin/pacman -S --noconfirm --needed base-devel mingw-w64-i686-toolchain #mingw-w64-x86_64-toolchain
    
    If( $add2path ) {
        $Documents = [Environment]::GetFolderPath('MyDocuments')
        -join('$env:PATH = $env:PATH', " + `";$PWD\mingw32\bin\;$PWD\usr\bin\`"") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
        -join('Set-Variable -Name "CC" -Value ', "'$PWD\mingw32\bin\gcc.exe'") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
        -join('Set-Variable -Name "CXX" -Value ', "'$PWD\mingw32\bin\g++.exe'") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
    }
    $env:PATH = $env:PATH + ";$PWD\mingw32\bin\;$PWD\usr\bin\"
    Set-Variable -Name "CC" -Value "$PWD\mingw32\bin\gcc.exe"
    Set-Variable -Name "CXX" -Value "$PWD\mingw32\bin\g++.exe"
    
    Set-Location ..
}

Function install_g++
{
    Param(
            [Bool] $add2path,
            [Parameter(Mandatory=$false)] [String] $confirm = ""
        )

    Write-Host "g++ identification: " -NoNewLine
    $gcc = Get-Command g++ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
    If( $gcc -eq $null){$version = ""}
    Else{$version = & g++ "--version"}
    If( $gcc -eq $null ){ # g++ not found
        Write-Host "NOT FOUND" -ForegroundColor Red
        If( $confirm -eq "-y" -Or $confirm -eq "-Y" -Or $confirm -eq "yes" ){ get_g++ -add2path $add2path -path $path}
        Else{
            $CONFIRM = Read-Host -Prompt "Do you want install it? [y/n]"
            If($CONFIRM -eq 'N' -Or $CONFIRM -eq 'n') { Write-Host "Abort" -ForegroundColor Red }
            Else{ get_g++ -add2path $add2path -path $path}
        }
    }
    ElseIf( $version.split(' ')[6].split('.')[0] -lt 4 ){ # version too old
        Write-Host "g++ version too old for OpenMP 4" -ForegroundColor Red
        If( $confirm -eq "-y" -Or $confirm -eq "-Y" -Or $confirm -eq "yes" ){ get_g++ -add2path $add2path -path $path }
        Else{
            $CONFIRM = Read-Host -Prompt "Do you want install it? [y/n]"
            If($CONFIRM -eq 'N' -Or $CONFIRM -eq 'n') { Write-Host "Abort" -ForegroundColor Red}
            Else{ 
                get_g++ -add2path $add2path -path $path
                $env:PATH = $env:PATH - ";$gcc"
                -join('$env:PATH = $env:PATH', " - `";$gcc`"") | Out-File -FilePath "$Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Append -Encoding ASCII
            }
        }
    }
    Else{ Write-Host "FOUND" -ForegroundColor Green}

}