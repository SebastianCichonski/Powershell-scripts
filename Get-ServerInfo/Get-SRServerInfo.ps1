<#
.SYNOPSIS
    Skrypt do pobierania informacji z serwerów.

.DESCRIPTION
    Skrypt pobiera ze wskazanych serwerów/komputerów informacje: nazwa, Adres IP, adresy serwerów DNS, system operacyjny, wolna przestrzeń na dyskach, ilość pamięci RAM, typ wirtualny/fizyczny, numer seryjny i error.
    We właściwości Error przechowywany jest komunikat błędu jeśli taki wystąpił podczas odpytywania serwera przez skrypt.
    Jeśli w katalogu głównym skryptu umieścimy plik services.txt z nazwami usług wpisanymi w oddzielnych wierszach skrypt dodatkowo sprawdzi czy na serwerach są wskazane usługi.
    Ponieważ skrypt zwraca objekty można z nimi dalej pracować wybierając interesujące nas właściwości np: ilość wolnego miejsca na dysku, lub objekty spełniające określone właściwości np: tylko maszyny wirtualne.

.PARAMETER SearchBase
    Ścieżka w formacje: 'OU=Serwery,OU=Komputery,DC=domena,DC=pl' do OU w którym znajdują się serwery. Parametr wymagany.

.INPUTS
    String

.OUTPUTS
    Skrypt zwraca obiekt reprezentujący serwer z właściwościami i typem jak poniżej:

        TypeName: System.Management.Automation.PSCustomObject

        Name           MemberType   Definition
        ----           ----------   ----------
        Equals         Method       bool Equals(System.Object obj)
        GetHashCode    Method       int GetHashCode()
        GetType        Method       type GetType()
        ToString       Method       string ToString()
        DNS            NoteProperty string[] DNS=System.String[]
        Error          NoteProperty object Error=null
        FreeSpace_(GB) NoteProperty ArrayList FreeSpace_(GB)=System.Collections.ArrayList
        IPAddress      NoteProperty string IPAddress=10.10.10.10
        Memory_(GB)    NoteProperty double Memory_(GB)=8
        OS             NoteProperty string OS=Microsoft Windows Server 2019 Standard     
        S/N            NoteProperty string S/N=-
        ServerName     NoteProperty System.String ServerName=Server1
        ServerType     NoteProperty string ServerType=Virtual Machine
        Services       NoteProperty Object[] Services=System.Object[]

.EXAMPLE
 'OU=Serwery,OU=Komputery,DC=domena,DC=pl' | Get-SRServerInfo.ps1

.EXAMPLE
  Get-SRServerInfo.ps1 -SearchBase 'OU=Serwery,OU=Komputery,DC=domena,DC=pl'

 .NOTES
   Version:        1.1
   Author:         Sebastian Cichoński
   Creation Date:  06.2024
   Projecturi:     
 #>

 #Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter(Mandatory, Position=0, ValueFromPipeline)]
    [string] $SearchBase
)

# Pobranie komputerów z AD
try {
    $Servers = Get-ADComputer -SearchBase $SearchBase -Filter * | Select-Object -ExpandProperty Name -ErrorAction Stop
}
catch {
    Write-Host "Nie można znaleźć obiektu: $SearchBase" -ForegroundColor Red
}

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent

# Pobranie nazw usług z pliku '.\services.txt'
try {
    $Services = Get-Content "$ScriptPath\services.txt" -ErrorAction Stop
}
catch {
    Write-Host "Nie można znaleźć pliku: [$ScriptPath\services.txt]." -ForegroundColor Red
}


foreach($Server in $Servers) {
    
    try {
        $Output = [PSCustomObject]@{
            'ServerName' = $null
            'IPAddress' = $null
            'DNS' = $null
            'OS' = $null
            'FreeSpace_(GB)' = $null
            'Memory_(GB)' = $null
            'Services' = $null
            'ServerType' = $null
            "S/N" = $null
            'Error' = $null
        }
    
        $Output.ServerName = $Server

        # Przycięcie nazwy serwera do pierwszych 15 znaków. 
        # Jeśli nazwa serwera jest dłuższa niż 15 znaków różni się od nazwy NetBios
        # wtedy polecenia związane z sesją CIM zwracają błąd
        If($Server.Length -gt 15) {
            $Server = $Server.Substring(0,15)
        }
        # Sprawdzenie czy komputer jest online, jeśli tak tworzona jest sesja CIM
        # która jest wykożystana do pobrania informacji z serwera
        if($null = Test-Connection -ComputerName $Server -Count 1 -ErrorAction Stop) {
            $cimInstanceParams = @{
                CimSession = New-CimSession -ComputerName $Server -ErrorAction SilentlyContinue
            }
            
            # Pobranie inforamcji o wolnej przestrzeni na dyskach, wynik wyrażony w bajtach
            # jest konwertowany na GB i zaokrąglany żeby nie wyświetlać miejsc po przecinku
            $discSpace = (Get-CimInstance @cimInstanceParams -ClassName Win32_LogicalDisk).FreeSpace
            $discSpace | ForEach-Object -Begin{ $FreeSpaceList = [System.Collections.ArrayList]@() }  -Process{ if($_){$null = $FreeSpaceList.add([Math]::Round(($_ / 1GB),0))} } 
            $Output.'FreeSpace_(GB)' = $FreeSpaceList
        
            # Pobranie informacji o systemie
            $Output.OS = (Get-CimInstance @cimInstanceParams -ClassName Win32_OperatingSystem).Caption 
        
            # Pobranie informacji o ilości pamięci, informacje są podawane oddzielnie dla każdego banku pamięci
            # są sumowane i zamieniana na GB
            $Output.'Memory_(GB)' = (Get-CimInstance @cimInstanceParams -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB

            # Pobranie adresu kart które ten adres mają przypisany i wybranie adresu IPv4
            $Output.IPAddress = (Get-CimInstance @cimInstanceParams -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" | Select-Object -Property *).IPAddress[0]
        
            # Pobranie adresów serwerów DNS
            $Output.DNS = (Get-CimInstance @cimInstanceParams -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" | Select-Object -Property *).DnsServerSearchOrder
        
            # Pobranie modelu serwera, jeśli jest to maszyna wirtualna w wyniku będzie 'Virtual Machine'
            # jeśli jest to serwer fizyczny otrzymamy nazwe modelu np: 'PowerEdge R730xd'
            $Output.'ServerType' = (Get-CimInstance @cimInstanceParams -ClassName Win32_ComputerSystem -ErrorAction Stop ).Model

            # Pobranie usług wyszczególnionych w pliku: .\services.txt
            if($Services -ne $null) {
                $Output.Services = (Get-Service -ComputerName $Server -Name $Services -ErrorAction SilentlyContinue).DisplayName
            }

            # Pobranie nueru seryjnego serwera w przypadku gdy jest to serwer fizyczny
            if($Output.'ServerType' -like "Virtual Machine") { 
                $Output.'S/N'= '-' 
            }
            else {
                $Output.'S/N' = (Get-CimInstance @cimInstanceParams -ClassName Win32_bios).SerialNumber
            } 
        }
    }
    catch {
        $Output.Error = $_.Exception.Message
    }
    finally {
        [PSCustomObject]$Output
    }
}
