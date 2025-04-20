

# Get-EncryptPass.ps1

## SYNOPSIS
Skrypt do zaszyfrowywania haseł używanych w skryptach.

## SYNTAX

```
Get-SREncryptPass.ps1 [-Phrase] <String> [-WithKey] [<CommonParameters>]
```

## DESCRIPTION
Skrypt pobiera hasło w formie jawnej i zwraca zaszyfrowany cią znaków.
Do szyfrowania używane jest Windows Data Protection API. 
Oznacza to, że poświadczenia zaszyfrowane w ten sposób są możliwe do odczytania tylko przez dany komputer oraz użytkownika, który wykonał to polecenie. 
Niestety skryptu z tak zaszyfrowanym hasłem nie użyjemy na innych komputerach.
Aby to umożliwić musimy dodatkowo wygenerować klucz używając parametru -WithKey
w takim przypadku skrypt wygeneruje plik z hasłem (C:\Temp\Secure\Password.txt) i plik z kluczem (C:\Temp\Secure\Secure.key), które można wykożystać w cmdlecie ConvertFrom-SecureString.

## EXAMPLES

### EXAMPLE 1
```
Get-EncryptPass.ps1 -Phrase tajnehasl0
```

Encrypted Password: 
01000000d08c9ddf0115d1118c7a00c04fc297eb01000000625d34456177704697ebf56209759b940000000002000000000003660000c0000000100000003e27cbf9439f69e23e
4ab5606168d2040000000004800000a000000010000000c2935be984afdbf8bfd2a1ea0e28696b180000006991ad8ce5c13d977bd5dcb775196ac973405afe5bee21de14000000
d70a48082e92cd0d4ce4bfa4fc708750c4e51358

### EXAMPLE 2
```
Get-EncryptPass.ps1 -Phrase tajnehasl0 -WithKey
```

## PARAMETERS

### -Phrase
Hasło do zaszyfrowania. Parametr wymagany.

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

### -WithKey
Przełącznik, który spowoduje wygenerowanie plików z hasłem i kluczem.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

 None
## OUTPUTS

 Plik C:\Temp\Secure\Password.txt.
 Plik C:\Temp\Secure\Secure.key.
## NOTES
Version:        1.1

Author:         Sebastian Cichonski

Creation Date:  1.2024

Projecturi:     https://

## RELATED LINKS
