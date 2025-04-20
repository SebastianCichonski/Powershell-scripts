<#
.SYNOPSIS
    Skrypt do tworzenia backupu uprawnieñ u¿ytkowników.

.DESCRIPTION
    Problem: Stworzyæ kopiê zapasow¹ uprawnieñ u¿ytkowników (Wymaganie: uprawnienia s¹ nadawane dla grup a nie dla u¿ytkowników.)

    Do skryptu przekazujemy login u¿ytkownika, ponadto skrypt posiada parametr Action który mo¿e mieæ jedn¹ z dwóch wartoœci: Get lub Set. 
    Wywo³any z wartoœci¹ Get skrypt pobiera wszystkie grupu do których nale¿y dany u¿ytkownik i zapisuje ich nazwy w pliku o nazwie identycznej 
    jak nazwa konta u¿ytkownika. Wywo³any z wartoœci¹ Set, skrpt sprawdzi czy istnieje plik z kopi¹ grup jeœli tak doda u¿ytkownika do ka¿dej grup z pliku.

.PARAMETER ADLogin
    Login u¿ytkownika. Parametr wymagany.

.PARAMETER Action
    Rodzaj akcji któr¹ ma wykonaæ skrypt, mo¿e przyj¹æ dwie wartoœci Get (backup uprawnieñ) lub Set (przywrócenie uprawnieñ). Parametr wymagany.

.INPUTS
    None.

.OUTPUTS
    None.

.NOTES
    Version:        1.1
    Author:         Sebastian Cichoñski
    Creation Date:  11.2023
    Projecturi:     https://
  
.EXAMPLE
  Backup-ADUserGroup.ps1 -ADLogin jan.kowalski -Action Get

  Utworzenie backupu uprawnieñ w pliku: C:\Temp\userlogin.txt

.EXAMPLE
  Backup-ADUserGroup.ps1 -ADLogin jan.kowalski -Action Set

  Przywrócenie uprawnieñ z pliku : C:\Temp\userlogin.txt
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $ADLogin,
        
        [Parameter(Mandatory)]
        [ValidateSet("Get", "Set")]
        [String] $Action
    )

    
    $userTest = $null
    $userGroups = $null
    $path = "C:\Temp"
    $file = Join-Path -Path $path -ChildPath "$ADLogin.txt"

    if($Action -like "Get"){
        try {
            $userTest = Get-ADUser -Identity $ADLogin -ErrorAction Stop
        }
        catch {
            Write-Verbose "Cannot find user: $ADLogin in AD."
        }  
        if($userTest -ne $null){
            if(-not (Test-Path -Path $path)) {
                New-Item -Path $path -ItemType Directory | Out-Null
            }
            Get-ADPrincipalGroupMembership -Identity $ADLogin| Select-Object -ExpandProperty  Name | Add-Content -Path $file -Force
            if(Test-Path -Path $file) {
                Write-Host "File $ADLogin.txt was created in location: $path."
            }
        }
    }

    elseif ($Action -like "Set") {
        try {
            $userGroups =  Get-Content -Path $file -ErrorAction Stop
        }
        catch {
            Write-Verbose "Cannot find file: $file, use first 'Backup-ADUserGroup.ps1 -ADLogin userLogin -Action Get'"
        }
        if($userGroups -ne $null) {
            foreach($group in $userGroups) {
                $testGroup = $null
                try {
                    $testGroup = Get-ADGroup -Identity $group
                }
                catch {
                    Write-Verbose "Cannot find group: $group"
                }
                if($testGroup -ne $null){
                    Write-Verbose "Add $ADLogin to group: $group"
                    Add-ADGroupMember -Identity $group -Members $ADLogin 
                } 
            }
        }
    }
   
