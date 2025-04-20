
# Set-WOL.ps1

## SYNOPSIS
 Skrypt włącza funkcje WakeOnLan.

## SYNTAX

```
Set-WOL.ps1 [-ComputerName] <String[]> [-Password <String>] [<CommonParameters>]
```

## DESCRIPTION
 Skrypt łączy się z komputerem zdalnym włącza WakeOnLan w ustawieniach BIOS, w przypadku komputerów DELL dodatkowo 
    wyłącza DeepSleepControl i C-StatesControl. W opcjach karty sieciowej wyłącza 'Energy Efficient Ethernet' i włącza
    'Wake on Magic Packet'. W ustawieniach komputera 'Opcje zasilania' > 'Definiuj przyciski zasilania... ' wyłącza 
    'Szybkie uruchamianie'.

 Skrypt obsługuje marki DELL i Lenovo

 Skrytp przetestowany na komputerach:
- **Dell**: OptiPlex 5090, Optiplex 5080, Optiplex 3070
- **Lenovo**: ThinkCentre M90a Gen2, ThinkCentre M90a Gen3

## EXAMPLES

### EXAMPLE 1
Właczenie WOL na komputerze Comp-01
```powershell
> Set-WOL.ps1 -ComputerName "Comp-01"

[INFO] > Sprawdzam czy komputer [Comp-01] jest osiągalny:    ONLINE
[START SCRIPT] >  [Comp-01]  -  [LENOVO] > Wprowadzam zmiany... 
[STOP SCRIPT] > Zmiany zapisane...
```

### EXAMPLE 2
Właczenie WOL dla komputerów których nazwy zostały pobrane z OU.
```powershell
> Get-ADComputer -SearchBase 'OU=komputery,DC=domena,DC=com'  -Filter * | Select-Object -ExpandProperty Name | Set-Content -Path C:\Temp\komptWOL.txt

> Set-WOL.ps1 -ComputerName (get-content C:\Temp\komptWOL.txt) -Verbose

[INFO] > Sprawdzam czy komputer [Comp-01] jest osiągalny:    ONLINE
[START SCRIPT] >  [Comp-01]  -  [LENOVO]  > Wprowadzam zmiany...
VERBOSE: [INFO] > Wyłączam Energy Efficient Ethernet...
VERBOSE: [INFO] > Włączam Wake on Magic Packet...
VERBOSE: [INFO] > Wyłączam Szybkie uruchamianie...
VERBOSE: [INFO] > Ustawiam parametry BIOS...
[STOP SCRIPT] > Zmiany zapisane...
[INFO] > Sprawdzam czy komputer [Comp-02] jest osiągalny:    OFFLINE
[INFO] > Sprawdzam czy komputer [Comp-03] jest osiągalny:    ONLINE
[START SCRIPT] >  [Comp-03]  -  [LENOVO]  > Wprowadzam zmiany...
VERBOSE: [INFO] > Wyłączam Energy Efficient Ethernet...
VERBOSE: [INFO] > Włączam Wake on Magic Packet...
VERBOSE: [INFO] > Wyłączam Szybkie uruchamianie...
VERBOSE: [INFO] > Ustawiam parametry BIOS...
[STOP SCRIPT] > Zmiany zapisane...
```
### EXAMPLE 3
Właczenie WOL na komputerze z ustawionym hasłem BIOS, dodatkowo włączony tryb wyświetlający więcej informacji
```powershell
> Set-WOL.ps1 -ComputerName "Comp-01" -Password "Pa$$w.rd" -Verbose

[INFO] > Sprawdzam czy komputer [Comp-01] jest osiągalny:    ONLINE
[START SCRIPT] >  [Comp-01]  -  [LENOVO] > Wprowadzam zmiany...
VERBOSE: [INFO] > Wyłączam Energy Efficient Ethernet...
VERBOSE: [INFO] > Włączam Wake on Magic Packet...
VERBOSE: [INFO] > Wyłączam Szybkie uruchamianie...
VERBOSE: [INFO] > Ustawiam parametry BIOS...
[STOP SCRIPT] > Zmiany zapisane...
```
## PARAMETERS

### -ComputerName
Nazwa komputera. Parametr wymagany.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```
### -Password
Hasło do systemu BIOS. Parametr opcjonalny.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```
### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### String
## NOTES
Version:        1.2 \
Author:         Sebastian Cichoński \
Creation Date:  08.2024 \
Projecturi:     

## RELATED LINKS
