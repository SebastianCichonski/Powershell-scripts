<#
.SYNOPSIS
    Skrypt do tworzenia udziałów dla użytkowników na podstawie nazwy konta.

.DESCRIPTION
    Problem: Utworzyć dla wszystkich użytkowników z AD udział którego nazwa będzie odpowiadał nazwie konta użytkownika.
    Skrypt pobiera nazwę konta użytkownika tworzy katalog odpowiadający tej nazwie, udostępnia i nadaje uprawnienia.
    Dla konta 'jan.kowalski' utworzony zostanie katalog 'jan.kowalski' z uprawnieniami: 
    NTFS - jan.kowalski/FullControl, SYSTEM/FullControl (ewentualnie Administrator/Read)
    Share - jan.kowalski/FullControl

    Każdemu użytkownikowi można podpiąć jego uział za pomocą GPO: User Configuration -> Preferences -> Drive Maps -> New Mapped Drive, w pole Location
    podajemy \\serwer\ścieżka do kotalogu z udziałami\%LogonUser% 


.PARAMETER OUPath
    Ścieżka do jednostki organizacyjnej AD w której znajdują się konta użytkowników (OU mogą być zagnieżdzone). Parametr wymagany.

.PARAMETER Domain
    Nazwa domeny (Pierwszy człon nazwy). Parametr wymagany.

.PARAMETER DestPath
    Ścieżka do katalogu w którym utworzone zostaną udziały. Parametr wymagany.

.PARAMETER Log
    Ścieżka do katalogu w którym zapisany będzie log z wykonania skryptu. Parametr opcjonalny.

.PARAMETER Admin
    Parametr określający nazwę konta administratora, skrypt wywołany z tym parametrem dodatkowo nada uprawnienia NTFS-ReadOnly
    dla podanego konta administratora. Parametr opcjonalny.

.INPUTS
    None.

.OUTPUTS
    Plik logu (New-SRUsersShare_2024-02-10_23.22.10.log) w formacie:

    2024-02-10_23.22.10 [INFO] > Log started
    2024-02-10_23.22.31 [SUCCESS] > [jan.kowalski] Creating directory.
    2024-02-10_23.22.31 [INFO] > [jan.kowalski] Share alredy exists.
    2024-02-10_23.22.31 [SUCCESS] > [anna.nowak] Creating directory.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Creating share and add permission.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Remove share permissions for a group: Everyone.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Disable NTFS inheritance.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Full Control for anna.nowak.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Full for SYSTEM.
    2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Read for Administrator.
    ...

.NOTES
    Version:        1.1
    Author:         Sebastian Cichoński
    Creation Date:  12.2023
    Projecturi:     
  
.EXAMPLE
  New-SRUsersShare.ps1 -OUPath "OU=Users,OU=HR,DC=lab,DC=com" -Domain "lab"
   -DestPath "\\serwer\users" -LogPath "C:\ps_script\logs"
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory)]
    [string] $OUPath,

    [Parameter(Mandatory)]
    [string] $Domain,

    [Parameter(Mandatory)]
    [alias("DestPath")]
    [ValidateScript({ Test-Path $_ -PathType  "Container" })]
    [string] $path,

    
    [alias("Log")]
    [ValidateScript({ Test-Path $_ -PathType "Container"})]
    [string] $LogPath,

    #[Parameter]
    [string] $Admin = $false
)

function Get-LongDate {
    Get-Date -Format "yyyy-MM-dd_HH.mm.ss"
}
function Write-Log {
    param (
        [Parameter()]
        [string]$Type,
        [string]$Value
    )
    if($Type -eq "Err") {
        Write-Host -ForegroundColor Red "[ERROR] $(Get-LongDate) $Value "
        if($LogPath) {
            Add-Content -Path $Log  -Encoding Ascii -Value "$(Get-LongDate) [ERROR] > $Value"
        }
    }
    if($Type -eq "Succ") {
        Write-Host -ForegroundColor green "[SUCCESS] $(Get-LongDate) $Value "
        if($LogPath) {
            Add-Content -Path $Log  -Encoding Ascii -Value "$(Get-LongDate) [SUCCESS] > $Value"
        }
    }
    if($Type -eq "Info") {
        Write-Host "[INFO] $(Get-LongDate) $Value "
        if($LogPath) {
            Add-Content -Path $Log  -Encoding Ascii -Value "$(Get-LongDate) [INFO] > $Value"
        }
    }
}

function Test-Share {
    param (
        [Parameter()]
        [string] $Name
    )
    $share = (Get-SmbShare -Name $Name -ErrorAction SilentlyContinue).Name
    if($share -eq $Name){
        return $true
    }
    else {
        return $false
    }  
}

if($LogPath) {
    $LogDate = Get-LongDate
    $Log = "$LogPath\New-SRUsersShare_$LogDate.log"
    if(Test-Path -Path $Log) {
        Clear-Content -Path $Log
    }
    Add-Content -Path $Log -Encoding Ascii -Value "$(Get-LongDate) [INFO] > Log started"
}

<#Instalowanie modu³u#>
Install-Module -Name NTFSSecurity -Force  -WarningAction SilentlyContinue

<#Pobieranie kont u¿ytkowników#>
try {
    $users = Get-ADUser -Filter "Enabled -eq 'True'" -SearchBase $OUPath | Select-Object -ExpandProperty SamAccountName
}
catch {
    Write-Log -Type 'Err' -Value "Not found OU: $OUPath"
}

foreach($user in $users) {

    Write-Host
    $directoryPath = "$path\$user"
    $account = "$Domain\$user"
    $shareTest

    if(Test-Path -Path $directoryPath) {
        Write-Log -Type 'Succ' -Value "[$user] Directory alredy exists."
    }
    else{
        New-Item -Name $user -Path $path -ItemType Directory | Out-Null
        Write-Log -Type 'Succ' -Value "[$user] Creating directory."

        if(-not (Test-Share -Name $user)){
            <#Tworzenie udziaÅ‚u#>
            $NSS = @{
                Name        = "$user"
                Path        = "$directoryPath"
                FullAccess  = "$account"
            }
            New-SmbShare @NSS | Out-Null
            Write-Log -Type 'Info' -Value "[$user] Creating share and add permission."

            <#Usuwanie dostêpu do udzia³u dla grupy Everyone#>
            $RSA = @{
                Name        = "$user"
                AccountName = "Wszyscy"
                Confirm     = $false
            }
            Write-Log -Type 'Info' -Value "[$user] Remove share permissions for a group: Everyone."
            Revoke-SmbShareAccess @RSA | Out-Null

            <#Wy³¹czenie dziedziczenia NTFS#>
            $DNI = @{
                Path                        = "$directoryPath"
                RemoveInheritedAccessRules  = $true
            }
            Write-Log -Type 'Info' -Value "[$user] Disable NTFS inheritance."
            Disable-NTFSAccessInheritance @DNI | Out-Null

            <#Nadawanie uprawnieñ NTFS dla u¿ytkownika#>
            $ANA1 = @{
                Path            = "$directoryPath"
                Account         = "$account"
                AccessRights    = 'FullControl'
            }
            Write-Log -Type "Info" -Value "[$user] Add permision Full Control for $user."
            Add-NTFSAccess @ANA1 | Out-Null

            <#Nadawanie uprawnieñ NTFS dla systemu#>
            $ANA2 = @{
                Path            = "$directoryPath"
                Account         = "SYSTEM"
                AccessRights    = 'Full'
            }
            Write-Log -Type "Info" -Value "[$user] Add permision Full for SYSTEM."
            Add-NTFSAccess @ANA2 | Out-Null

            <#Nadawanie uprawnień NTFS do odczytu dla administratora#>
            if($Admin) {
                $ANA3 = @{
                    Path            = "$directoryPath" 
                    Account         = "$Domain\$Admin"
                    AccessRights    = "Read"
                }
                Write-Log -Type "Info" -Value "[$user] Add permision Read for Administrator."
                Add-NTFSAccess @ANA3 | Out-Null
            }
        }
        else {
            Write-Log -Type 'Info' -Value "[$user] Share alredy exists."
        }
    } 
}
