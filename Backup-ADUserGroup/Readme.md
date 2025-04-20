
# Backup-ADUserGroup.ps1

## SYNOPSIS
Skrypt do tworzenia backupu uprawnień użytkowników.

## SYNTAX

```
Backup-SRUserGroups.ps1 [-ADLogin] <String> [-Action] <String> [<CommonParameters>]
```

## DESCRIPTION
Problem: Stworzyć kopię zapasową uprawnień użytkowników (Wymaganie: uprawnienia są nadawane dla grup a nie dla użytkowników.)

Do skryptu przekazujemy login użytkownika, ponadto skrypt posiada parametr Action który może mieć jedną z dwóch wartości: Get lub Set. 
Wywołany z wartością Get skrypt pobiera wszystkie grupu do których należy dany użytkownik i zapisuje ich nazwy w pliku o nazwie identycznej 
jak nazwa konta użytkownika.
Wywołany z wartością Set, skrypt sprawdzi czy istnieje plik z kopią grup jeśli tak doda użytkownika do każdej grup z pliku.

## EXAMPLES

### EXAMPLE 1
```
Backup-ADUserGroup.ps1 -ADLogin jan.kowalski -Action Get
```

Utworzenie backupu uprawnień w pliku: C:\Temp\jan.kowalski.txt

### EXAMPLE 2
```
Backup-ADUserGroup.ps1 -ADLogin jan.kowalski -Action Set
```

Przywrócenie uprawnień z pliku : C:\Temp\jan.kowalski.txt

## PARAMETERS

### -ADLogin
Login użytkownika.
Parametr wymagany.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
Rodzaj akcji którą ma wykonać skrypt, może przyjąć dwie wartości Get (backup uprawnień) lub Set (przywrócenie uprawnień).
Parametr wymagany.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

 None.
## OUTPUTS

 None.
## NOTES
Version:        1.1\
Author:         Sebastian Cichoński\
Creation Date:  11.2023\
Projecturi:     https://

## RELATED LINKS
