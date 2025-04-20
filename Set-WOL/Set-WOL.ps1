<#
.SYNOPSIS
    Skrypt włącza funkcje WakeOnLan.

.DESCRIPTION
    Skrypt łączy się z komputerem zdalnym włącza WakeOnLan w ustawieniach BIOS w przypadku komputerów DELL dodatkowo 
    wyłącza DeepSleepControl i C-StatesControl. W opcjach karty sieciowej wyłącza 'Energy Efficient Ethernet' i włącza
    'Wake on Magic Packet'. W ustawieniach komputera 'Opcje zasilania' > 'Definiuj przyciski zasilania... ' wyłącza 
    'Szybkie uruchamianie'.

    Skrypt obsługuje marki DELL i Lenovo

    Skrytp przetestowany na komputerach:
    Dell: OptiPlex 5090, Optiplex 5080, Optiplex 3070
    Lenovo: ThinkCentre M90a Gen2, ThinkCentre M90a Gen3
.PARAMETER ComputerName
     Nazwa komputera lub kilka nazw oddzielonych przecinkami. Parametr wymagany.

.PARAMETER Password
    Hasło do systemu BIOS. Parametr opcjonalny.

.INPUTS
    String

.OUTPUTS
    String 

.EXAMPLE
  Set-WOL.ps1 -ComputerName "Comp-01"

.EXAMPLE
  Get-ADComputer -SearchBase 'OU=komputery,OU=5096,OU=Rejon,OU=Resort,DC=ad,DC=ms,DC=gov,DC=pl'  -Filter * | Select-Object -ExpandProperty Name | Set-Content -Path C:\Temp\komptWOL.txt
  Set-WOL.ps1 -ComputerName (get-content C:\Temp\komptWOL.txt) -Verbose

 .NOTES
   Version:        1.2
   Author:         Sebastian Cichoński
   Creation Date:  08.2024
   Projecturi:     
 #>

#$Error.Clear()                      #
#Set-StrictMode -Version Latest      #
#Requires -RunAsAdministrator


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true,Position=0, ValueFromPipeline)]
    [string[]]$ComputerName ,

    [Parameter(Mandatory=$false)]
    [string]$Password = $null
)

 # Ustaw WOL na stacjach Lenovo
 Function Set-LenovoWOL ($BiosPassword) {
    $Options
    $WOL = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi | Where-Object  CurrentSetting -Like "*wakeonlan,*"
    if($WOL.CurrentSetting -like "*Enabled*") {$Options = "Enabled"}
    elseif ($WOL.CurrentSetting -like "*Enable*") {$Options = "Enable"}
    elseif($WOL.CurrentSetting -like "*Boot Order*") {$Options = "Boot Order"}

    $BiosLenovo = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi -ErrorAction Stop
    if($BiosPassword) { $Set = $BiosLenovo.setBiosSetting("WakeOnLAN,$Options,$BiosPassword,ascii,us") }
    else{ $Set = $BiosLenovo.setBiosSetting("WakeOnLAN,$Options") } 
    if($Set.return -ne "Success") { throw "Nie udało się ustawić wartości [$Options] w BIOS... " } 

    $NewSettings = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi -ErrorAction Stop
    if($BiosPassword) { $Save = $NewSettings.SaveBiosSettings("$BiosPassword,ascii,us") }
    else{$Save = $NewSettings.SaveBiosSettings() }
    if($Save.return -ne "Success") { throw "Nie udało się zapisać wartości [$Options] w BIOS... "}
}# End Set-LenovoWOL


# Ustaw WOL na stacjach DELL
Function Set-DellWOL ($BiosPassword) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    if (Get-Module -ListAvailable -Name DellBIOSProvider) {} 
    else {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
        Install-Module -Name DellBIOSProvider -Force
    } 
    Import-Module DellBIOSProvider -Force 
    Set-ExecutionPolicy -ExecutionPolicy Default
    if($BiosPassword) { 
        Set-Item -Path DellSmbios:\PowerManagement\WakeOnLan LanWlan -ErrorAction Stop -Password "$BiosPassword"
        Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl Disabled -ErrorAction Stop -Password "$BiosPassword"
        Set-Item -Path DellSmbios:\Performance\CStatesCtrl Disabled -ErrorAction Stop -Password "$BiosPassword"
     }
    else{
        Set-Item -Path DellSmbios:\PowerManagement\WakeOnLan LanWlan -ErrorAction Stop 
        Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl Disabled -ErrorAction Stop
        Set-Item -Path DellSmbios:\Performance\CStatesCtrl Disabled -ErrorAction Stop 
     }
    
    Remove-Module -Name DellBIOSProvider -Force
}# End Set-DellWOL


# Wyłącz Szybkie uruchamianie
Function Disable-Hiperboot {
    Set-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Force
}# End Disable-Hiperboot


# Wyłącz Energy Efficient Ethernet na karcie sieciowej
Function Disable-EEE {
    $Adapter = Get-NetAdapter | Where-Object { ($_.Status -eq "Up") -and ($_.PhysicalMediaType -eq "802.3") }
    if(Get-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword  "EEE" -ErrorAction SilentlyContinue) {
        Set-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword "EEE" -RegistryValue "0" 
    }
    elseif (Get-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword  "EEELinkAdvertisement" -ErrorAction SilentlyContinue){
        Set-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword "EEELinkAdvertisement" -RegistryValue "0" 
    }
    elseif(Get-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword  "\*EEE" -ErrorAction SilentlyContinue) {
        Set-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword "\*EEE" -RegistryValue "0" 
    }
 }# End Disable-EEE


# Włącz Wake on Magic Packet na karcie sieciowej
Function Enable-WoMP {
    $Adapter = Get-NetAdapter | Where-Object { ($_.Status -eq "Up") -and ($_.PhysicalMediaType -eq "802.3") }
    Set-NetAdapterAdvancedProperty -Name $Adapter.Name  -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 
}# End Enable-WoMP


# Funkcja ustawia właściwości BIOS i karty sieciowej związane z funkcjonalnością WakeOnLan
Function Set-WOL {
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Lenovo", "Dell")]
    [string]$WOLFunction 
)
    try{
        Write-Verbose "[INFO] > Wyłączam Energy Efficient Ethernet..."
        Invoke-Command -ComputerName $Computer -ScriptBlock ${Function:Disable-EEE} -ErrorAction Stop
        Write-Verbose "[INFO] > Włączam Wake on Magic Packet..."
        Invoke-Command -ComputerName $Computer -ScriptBlock ${Function:Enable-WoMP} -ErrorAction Stop
        Write-Verbose "[INFO] > Wyłączam Szybkie uruchamianie..."
        Invoke-Command -ComputerName $Computer -ScriptBlock ${Function:Disable-Hiperboot} -ErrorAction Stop
        Write-Verbose "[INFO] > Ustawiam parametry BIOS..." 
        if($WOLFunction -eq "Dell") { Invoke-Command -ComputerName $Computer -ScriptBlock ${Function:Set-DellWOL} -ArgumentList $Password -ErrorAction Stop}
        elseif($WOLFunction -eq "Lenovo") {Invoke-Command -ComputerName $Computer -ScriptBlock ${Function:Set-LenovoWOL} -ArgumentList $Password -ErrorAction Stop}
        Write-Host "[STOP SCRIPT] > Zmiany zapisane..." -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] > $_.Exception.Message" -ForegroundColor Red 
    }
}# End Set-WOL


# Punkt wejścia skryptu
foreach($Computer in $ComputerName) {
    Write-Host "[INFO] > Sprawdzam czy komputer [$Computer] jest osiągalny:" -NoNewline -ForegroundColor Cyan
    if(Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Write-Host "    ONLINE" -ForegroundColor Green
        # Pobranie marki Biosu
        $Branch = Get-CimInstance -ComputerName $Computer  -ClassName Win32_BIOS -Verbose:$false | Select-Object -ExpandProperty manufacturer 

        Write-Host "[START SCRIPT] > " -ForegroundColor Cyan -NoNewline
        Write-Host " [$Computer]  -  [$Branch] " -BackgroundColor Yellow -ForegroundColor Black -NoNewline
        Write-Host " > Wprowadzam zmiany..." -ForegroundColor Cyan
        if ($Branch -like "*Dell*") { Set-WOL -WOLFunction "Dell" }
        elseif ($Branch -like "*Lenovo*") { Set-WOl -WOLFunction "Lenovo"}
        else { Write-Host "[ERROR] > Nieobsługiwana marka komputera..." -ForegroundColor Red }

    }else{
        Write-Host "    OFFLINE" -ForegroundColor Red
    }
}
