

# New-SRUsersShare.ps1 

## SYNOPSIS
Skrypt do tworzenia udziałów dla użytkowników na podstawie nazwy konta.

## SYNTAX

```
New-SRUsersShare.ps1 [-OUPath] <String> [-Domain] <String> [-path] <String> [[-LogPath] <String>]
 [[-Admin] <String>] [<CommonParameters>]
```

## DESCRIPTION
Problem: Utworzyć dla wszystkich użytkowników z AD udział‚ którego nazwa będzie tożsama z nazwą konta użytkownika.

Skrypt pobiera nazwę konta użytkownika tworzy katalog odpowiadający tej nazwie, udostępnia i nadaje uprawnienia.\
Dla konta 'jan.kowalski' utworzony zostanie katalog 'jan.kowalski' z uprawnieniami: \
NTFS - jan.kowalski/FullControl, SYSTEM/FullControl (ewentualnie Administrator/Read)\
Share - jan.kowalski/FullControl

Każdemu użytkownikowi można podpiąć jego uział‚ za pomocą GPO: User Configuration -\> Preferences -\> Drive Maps -\> New Mapped Drive, w pole Location
podajemy \\\\serwer\ścieżka do kotalogu z udziałem\%LogonUser%

## EXAMPLES

### EXAMPLE 1
```
New-SRUsersShare.ps1 -OUPath "OU=Users,OU=HR,DC=lab,DC=com" -Domain "lab" -DestPath "\\serwer\users" -LogPath "C:\ps_script\logs"
```



## PARAMETERS

### -OUPath
ścieżka do jednostki organizacyjnej AD w której znajdują się konta użytkowników (OU mogą być zagnieżdzone).
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

### -Domain
Nazwa domeny (Pierwszy człon nazwy).
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

### -DestPath
Ścieżka do katalogu w którym utworzone zostaną udziały. Parametr wymagany.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Path

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogPath
Ścieżka do katalogu w którym zapisany będzie log z wykonania skryptu. Parametr opcjonalny.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Log

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Admin
Parametr określający nazwę konta administratora, skrypt wywołany z tym parametrem dodatkowo nada uprawnienia NTFS-ReadOnly
dla podanego konta administratora.
Parametr opcjonalny.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

 None.
## OUTPUTS

 Plik logu (New-SRUsersShare_2024-02-10_23.22.10.log) w formacie:\
 2024-02-10_23.22.10 [INFO] > Log started\
 2024-02-10_23.22.31 [SUCCESS] > [jan.kowalski] Creating directory.\
 2024-02-10_23.22.31 [INFO] > [jan.kowalski] Share alredy exists.\
 2024-02-10_23.22.31 [SUCCESS] > [anna.nowak] Creating directory.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Creating share and add permission.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Remove share permissions for a group: Everyone.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Disable NTFS inheritance.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Full Control for anna.nowak.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Full for SYSTEM.\
 2024-02-10_23.22.31 [INFO] > [anna.nowak] Add permision Read for Administrator.\
 ...
## NOTES
Version:        1.1\
Author:         Sebastian Cichoński\
Creation Date:  12.2023\
Projecturi:     

## RELATED LINKS
