# Get-SRServerInfo.ps1

## SYNOPSIS
Skrypt do pobierania informacji z serwerów.

## SYNTAX

```
Get-SRServerInfo.ps1 [-SearchBase] <String> [<CommonParameters>]
```

## DESCRIPTION
Skrypt pobiera ze wskazanych serwerów/komputerów informacje: nazwa, Adres IP, adresy serwerów DNS, system operacyjny, wolna przestrzeń na dyskach, ilość pamięci RAM, typ wirtualny/fizyczny, numer seryjny i error.
We właściwości Error przechowywany jest komunikat błędu jeśli taki wystąpił podczas odpytywania serwera przez skrypt.
Jeśli w katalogu głównym skryptu umieścimy plik services.txt z nazwami usług wpisanymi w oddzielnych wierszach skrypt dodatkowo sprawdzi czy na serwerach są wskazane usługi.
Ponieważ skrypt zwraca obiekty można z nimi dalej pracować wybierając interesujące nas właściwości np: ilość wolnego miejsca na dysku, lub obiekty spełniające określone właściwości np: tylko maszyny wirtualne.

## EXAMPLES

### EXAMPLE 1
```
'OU=Serwery,OU=Komputery,DC=domena,DC=pl' | Get-SRServerInfo.ps1
```

### EXAMPLE 2
```
Get-SRServerInfo.ps1 -SearchBase 'OU=Serwery,OU=Komputery,DC=domena,DC=pl'
```

## PARAMETERS

### -SearchBase
Ścieżka do OU w którym znajdują się serwery w formacje: 'OU=Serwery,OU=Komputery,DC=domena,DC=pl'.
Parametr wymagany.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

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
## NOTES
Version:        1.1 \
Author:         Sebastian Cichoński \
Creation Date:  06.2024 \
Projecturi:     


## Jak używać skryptu
Skrypt może wykonywać się dość długo dlatego jego wynik najlepiej przypisać do zmiennej i dopiero na niej pracować:
```
$servInf = 'OU=serwery,OU=IT,DC=firma,DC=local' | .\Get-SRServerInfo.ps1
```
### Tabela z wywnikami:
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | ft -AutoSize

ServerName      IPAddress    DNS                            OS                              FreeSpace_(GB)    Memory_(GB)  Services                       ServerType          S/N      Error
----------      ---------    ---                            --                              --------------    -----------  --------                       ----------          ---      -----
50-SGO12345A    10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2019 Standard            {87, 102}                   4                                 Virtual Machine     -
42-SGO123D      10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2019 Standard            {101}                       4  {Neur, Snow Inventory Agent}   Virtual Machine     -
42-SGO12345678F 10.6.---.--- {10.6.---.---, 10.6.---.--}    Storage Server 2012 R2 Standard {101, 137, 3302}            32 Snow Inventory Agent           Dell Storage NX3230 3BDFGR
50-SGO12345G    10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2019 Standard            {82, 4354}                  4  Snow Inventory Agent           Virtual Machine     -
50-SGO1234H                                                                                                                                                                            Testing conn... 
50-SGO123I      10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2012 R2 Standard         {281, 199, 342}             64 Snow Inventory Agent           PowerEdge R730xd    HVFDCVF
50-SGO12345J                                                                                                                                                                           Cannot bind ... 
50-SGO12345K    10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2019 Standard            {56}                        8  {RCS, Snow Inventory Agent}    Virtual Machine     -
50-SGO123N      10.6.---.--- {10.6.---.---, 10.6.---.--}    Server 2012 Standard            {95, 361, 1247}             32 Snow Inventory Agent           PowerEdge R720      DMD564Y

```
### Wybieranie konkretnych kolumn
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | select ServerName, ServerType, S/N

ServerName      ServerType          S/N     
----------      ----------          ---     
50-SGO12345A    Virtual Machine     -
42-SGO123D      Virtual Machine     -
42-SGO12345678F Dell Storage NX3230 3BDFGR
50-SGO12345G    Virtual Machine     -
50-SGO1234H                     
50-SGO123I      PowerEdge R730xd    HVFDCVF
50-SGO12345J     
50-SGO12345K    Virtual Machine     -
50-SGO123N      PowerEdge R720      DMD564Y

```

### Wybranie serwerów spełniających konkretny warunek (tylko wirtualne maszyny)
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | where ServerType -EQ 'Virtual Machine' | ft -AutoSize 

ServerName      IPAddress    DNS                          OS                              FreeSpace_(GB)    Memory_(GB)  Services                       ServerType          S/N      Error
----------      ---------    ---                          --                              --------------    -----------  --------                       ----------          ---      -----
50-SGO12345A    10.6.---.-- {10.6.---.--, 10.6.---.--}    Server 2019 Standard            {87, 102}                   4                                 Virtual Machine     -
42-SGO123D      10.6.---.-- {10.6.---.--, 10.6.---.--}    Server 2019 Standard            {101}                       4  {Neur, Snow Inventory Agent}   Virtual Machine     -
50-SGO12345G    10.6.---.-- {10.6.---.--, 10.6.---.--}    Server 2019 Standard            {82, 4354}                  4  Snow Inventory Agent           Virtual Machine     -
50-SGO12345K    10.6.---.-- {10.6.---.--, 10.6.---.--}    Server 2019 Standard            {56}                        8  {RCS, Snow Inventory Agent}    Virtual Machine     -

```

### Połączenie komend 'select' i 'where' (serwery które posiadają Serial Number)
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | where {$_.'S/N' -and $_.'S/N' -ne '-'  } | select ServerName, ServerType, S/N

ServerName      ServerType          S/N     
----------      ----------          ---     
42-SGO12345678F Dell Storage NX3230 3BDFGR
50-SGO123I      PowerEdge R730xd    HVFDCVF
50-SGO123N      PowerEdge R720      DMD564Y

```

### Serwery z dyski poiżej 90 GB wolnej przestrzeni 
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | where {$_.'FreeSpace_(GB)' -lt 90 -and $_.'FreeSpace_(GB)'} | select ServerName, 'FreeSpace_(GB)'

ServerName      FreeSpace_(GB)    
----------      --------------    
50-SGO12345K    {56}                       
50-SGO12345A    {87, 102}              

```

### Serwery na których wystąpiły błędy podczas pobierania informacji
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | where {$_.Error} | select ServerName, Error   

ServerName     Error
----------     -----
50-SGO1234H    Testing connection to computer '50-SGO1234H' failed: Nieznany host      
50-SGO12345J   Cannot bind argument to parameter 'CimSession' because it is null.    
```

### Zapisanie wyników do pliku
```
PS C:\ps_scripts\Scripts\Get-ServerInfo> $servInf | Ft -AutoSize | Out-File  c:\ServerInfo.txt -Width 1000
```
