# 1.0.8030.24604

## $Env:PATH management
Function Add-DirectoryToPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [string] $path,
        [string] $variable = "PATH",

        [switch] $clear,
        [switch] $force,
        [switch] $prepend,
        [switch] $whatIf
    )

    BEGIN {

        ## normalize paths

        $count = 0

        $paths = @()

        if (-not $clear.IsPresent) {

            $environ = Invoke-Expression "`$Env:$variable"
            $environ.Split(";") | ForEach-Object {
                if ($_.Length -gt 0) {
                    $count = $count + 1
                    $paths += $_.ToLowerInvariant()
                }
            }

            Write-Verbose "Currently $($count) entries in `$env:$variable"
        }

        Function Array-Contains {
            param(
                [string[]] $array,
                [string] $item
            )

            $any = $array | Where-Object -FilterScript {
                $_ -eq $item
            }

            Write-Output ($null -ne $any)
        }
    }

    PROCESS {

        ## Using [IO.Directory]::Exists() instead of Test-Path for performance purposes

        ##$path = $path -replace "^(.*);+$", "`$1"
        ##$path = $path -replace "^(.*)\\$", "`$1"
        if ([IO.Directory]::Exists($path) -or $force.IsPresent) {

            #$path = (Resolve-Path -Path $path).Path
            $path = $path.Trim()

            $newPath = $path.ToLowerInvariant()
            if (-not (Array-Contains -Array $paths -Item $newPath)) {
                if ($whatIf.IsPresent) {
                    Write-Host $path
                }

                if ($prepend.IsPresent) { $paths = , $path + $paths }
                else { $paths += $path }

                Write-Verbose "Adding $($path) to `$env:$variable"
            }
        }
        else {

            Write-Host "Invalid entry in `$Env:$($variable): ``$path``" -ForegroundColor Yellow

        }
    }

    END {

        ## re-create PATH environment variable

        $separator = [IO.Path]::PathSeparator
        $joinedPaths = [string]::Join($separator, $paths)

        if ($whatIf.IsPresent) {
            Write-Output $joinedPaths
        }
        else {
            Invoke-Expression " `$env:$variable = `"$joinedPaths`" "
        }
    }

}

## Well-known profiles script
Function Get-DefaultProfile {
    $___profile = Join-Path -Path (Split-Path -Path $profile -Parent) -ChildPath "profile.ps1"
    Write-Output $___profile
}
Function Remove-DefaultProfile {
    $___profile = Get-DefaultProfile
    if (Test-Path $___profile) { 
        Write-Host "Removing default profile file." -ForegroundColor Yellow
        Remove-Item $___profile -Force
    }
}

## 

if (-not (Get-Module -Name Pwsh-Profile -ListAvailable)) {
    Write-Host "Missing required 'Pwsh-Profile' module." -ForegroundColor Yellow
    Write-Host "Please, install this module once using the following command:" -ForegroundColor Yellow
    Write-Host "  Install-Module -Name Pwsh-Profile -Repository PSGallery -Scope CurrentUser -Force" -ForegroundColor DarkGray

    return
} else {

    $update8030 = Join-Path -Path (Get-CachedPowerShellProfileFolder) -ChildPath "pwsh_profile_8030"
    if (-not (Test-Path $update8030)){
        $online = Find-Module -Name Pwsh-Profile -Repository PSGallery
        $current = Get-module -Name Pwsh-Profile -ListAvailable
        if ($online.Version -gt $current.Version) {
            Write-Host "Required 'Pwsh-Profile' module has updates." -ForegroundColor Yellow
            Write-Host "Please, update this module using the following command:" -ForegroundColor Yellow
            Write-Host "  Update-Module -Name Pwsh-Profile -Force" -ForegroundColor DarkGray
        }
        Set-Content -Path $update8030 -Value $null
    }
}

CheckFor-ProfileUpdate | Out-Null
Load-Profile "profiles" -Quiet
