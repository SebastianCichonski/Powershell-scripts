# 🛠️ Skrypt PowerShell: Migracja udziałów sieciowych

## 0. Opis

Ten skrypt PowerShell automatyzuje proces migracji udziałów sieciowych z komputera zdalnego na lokalny serwer. Wykorzystuje pliki XML zawierające informacje o udziałach oraz ich uprawnieniach, aby odtworzyć strukturę folderów i przypisać odpowiednie prawa dostępu NTFS oraz SMB.

## 1. Funkcjonalności

- Import udziałów z pliku XML (`shares.xml`)
- Import uprawnień z pliku XML (`sharesAccess.xml`)
- Tworzenie struktury folderów lokalnych
- Kopiowanie danych z zachowaniem uprawnień NTFS (Robocopy)
- Tworzenie udziałów SMB z odpowiednimi uprawnieniami (Full, Change, Read)
- Logowanie przebiegu operacji do plików tekstowych

## 2. Parametry

| Parametr               | Typ     | Wymagany | Opis |
|------------------------|---------|----------|------|
| `ComputerName`         | string  | ✅       | Nazwa komputera źródłowego |
| `Destination`          | string  | ✅       | Ścieżka lokalna docelowa |
| `ExportedSharesFile`   | string  | ❌       | Ścieżka do pliku XML z udziałami (domyślnie `C:\shares.xml`) |
| `ExportedSharesAccess` | string  | ❌       | Ścieżka do pliku XML z uprawnieniami (domyślnie `C:\sharesAccess.xml`) |
| `LogFolder`            | string  | ❌       | Folder logów (domyślnie `C:\MigrationLogs`) |

## 3. Przykład użycia
```powershell
.\Migrate-Shares.ps1 -ComputerName "Server01" -Destination "D:\MigratedShares"
```

## 4. Wymagania

- PowerShell 5.1 lub nowszy
- Uprawnienia administratora
- Dostęp do zdalnego komputera przez sieć
- Pliki XML z udziałami (`shares.xml`) i uprawnieniami (`sharesAccess.xml`)
- Moduł `SmbShare` dostępny w systemie (dla `New-SmbShare`)
- Narzędzie Robocopy dostępne w systemie Windows

## 5. Logi

- `robocopy_log.txt` – log z kopiowania danych
- `migration_transcript.log` – pełna transkrypcja działania skryptu

## 6. Uwagi

- Skrypt pomija tworzenie udziału, jeśli już istnieje o tej samej nazwie.
- W przypadku błędów Robocopy (kod >= 8), zostanie wyświetlone ostrzeżenie.
- Uprawnienia są przypisywane tylko jeśli zostały zdefiniowane w pliku XML.

## 7. Testowanie i wdrażanie

### 7.1 Testowanie

1. Uruchom skrypt w środowisku testowym.
2. Zweryfikuj poprawność plików XML.
3. Sprawdź logi po wykonaniu skryptu.
4. Przetestuj dostęp do utworzonych udziałów.

### 7.2 Wdrażanie

1. Uruchom skrypt jako administrator.
2. Zabezpiecz pliki XML przed modyfikacją.
3. Monitoruj logi po migracji.
4. Wykonaj kopię zapasową przed wdrożeniem.

## 8. Tworzenie plików XML z udziałami i uprawnieniami


Poniżej przykład tworzenia plików z udziałami i uprawnieniami pomijający udziały adinistracyjne:

- działy

```powershell
$shares = Get-SmbShare | Where-Object { $_.Name -ne "IPC$" -and $_.Name -ne "ADMIN$" }
$shares | Export-Clixml -Path "C:\shares.xml"
```
- uprawnienia
```powershell
$share | Get-SmbShareAccess | Export-Clixml -Path "C:\sharesAccess.xml"
```