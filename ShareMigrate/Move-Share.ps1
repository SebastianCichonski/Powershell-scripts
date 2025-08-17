[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
    [string] $ComputerName,

    [Parameter(Mandatory, Position = 1)]
    [string] $Destination,

    [Parameter(Mandatory = $false)]
    [string] $ExportedSharesFile = "C:\shares.xml",

    [Parameter(Mandatory = $false)]
    [string] $ExportedSharesAccess = "C:\sharesAccess.xml",

    [Parameter(Mandatory = $false)]
    [string] $LogFolder = "C:\MigrationLogs"
)

# === Parametry ===
$sourceServerPath = "\\$ComputerName"
$logFile = Join-Path $LogFolder "robocopy_log.txt"

Write-Verbose "======> Skrypt kopiuje udziały z $sourceServerPath na komputer lokalny <======`n"
Write-Verbose "=====> Przygotowania..."

# =====Przygotowanie======
if (!(Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    Write-Verbose "Utworzono folder logowania: $LogFolder"
}

try {
    Start-Transcript -Path (Join-Path $LogFolder 'migration_transcript.log') -Append | Out-Null
    Write-Verbose "Start logowania wykonania skryptu do pliku: $LogFolder\migration_transcript.log"

    # =====Sprawdzenie pliku XML z udziałami=====
    if (!(Test-Path -Path $ExportedSharesFile)) {
        Write-Error "Plik z udziałami nie istnieje: $ExportedSharesFile"
        return
    }

    $shares = Import-Clixml -Path $ExportedSharesFile
    Write-Verbose "Zaczytanie udziałów z pliku: $ExportedSharesFile"

    if (!$shares -or $shares.Count -eq 0) {
        Write-Error "Brak danych w pliku z udziałami: $ExportedSharesFile"
        return
    }

    # =====Sprawdzenie pliku XML z uprawnieniami=====
    if (!(Test-Path -Path $ExportedSharesAccess)) {
        Write-Error "Plik z uprawnieniami nie istnieje: $ExportedSharesAccess"
        return
    }

    $sharesAccess = Import-Clixml -Path $ExportedSharesAccess
    Write-Verbose "Zaczytanie uprawnień z pliku: $ExportedSharesAccess"

    if (!$sharesAccess -or $sharesAccess.Count -eq 0) {
        Write-Error "Brak danych w pliku z uprawnieniami: $ExportedSharesAccess"
        return
    }

    # =====Tworzenie folderu docelowego=====
    if (!(Test-Path -Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Verbose "Utworzenie folderu docelowego: $Destination"
    }

    # =====Kopiowanie danych z uprawnieniami NTFS=====
    Write-Verbose "=====> `nZaczynam kopiowanie udziałów... "
    foreach ($share in $shares) {
        $dest = Join-Path $Destination $share.Name
        if (!(Test-Path -Path $dest)) {
            New-Item -Path $dest -ItemType Directory -Force | Out-Null
            Write-Verbose "Utworzenie folderu: $dest"
        }

        $source = Join-Path $sourceServerPath $share.Name

        # Uruchom robocopy i sprawdź $LASTEXITCODE
        & Robocopy.exe $source $dest /MIR /COPYALL /SEC /R:3 /W:5 "/LOG+:$logFile"
        $rc = $LASTEXITCODE
        if ($rc -ge 8) {
            Write-Warning "Robocopy zakończył się błędem (kod $rc) dla $source"
        } else {
            Write-Verbose "Skopiowano dane z $source do $dest (Robocopy kod: $rc)"
        }

        # =====Tworzenie udziałów=====
        $shareParameters = @{
            Path        = $dest
            Name        = $share.Name + "_migrate"
            Description = "Udział: " + $share.Name
        }

        if ($null -ne $share.FolderEnumerationMode) { $shareParameters.FolderEnumerationMode = $share.FolderEnumerationMode }
        if ($null -ne $share.CachingMode)           { $shareParameters.CachingMode = $share.CachingMode }
        if ($null -ne $share.EncryptData)           { $shareParameters.EncryptData = $share.EncryptData }

        $Full = $sharesAccess | Where-Object { ($_.AccessRight -eq 'Full')   -and ($_.Name -eq $share.Name) } | Select-Object -ExpandProperty AccountName -ErrorAction SilentlyContinue
        $Change = $sharesAccess | Where-Object { ($_.AccessRight -eq 'Change') -and ($_.Name -eq $share.Name) } | Select-Object -ExpandProperty AccountName -ErrorAction SilentlyContinue
        $Read = $sharesAccess | Where-Object { ($_.AccessRight -eq 'Read')   -and ($_.Name -eq $share.Name) } | Select-Object -ExpandProperty AccountName -ErrorAction SilentlyContinue

        if ($Full)   { $shareParameters.FullAccess   = $Full }
        if ($Change) { $shareParameters.ChangeAccess = $Change }
        if ($Read)   { $shareParameters.ReadAccess   = $Read }

        $smbName = $shareParameters.Name
        # sprawdź czy udział już istnieje
        $existing = Get-SmbShare -Name $smbName -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Warning "Udział o nazwie '$smbName' już istnieje. Pomijam tworzenie."
            continue
        }

        try {
            New-SmbShare @shareParameters -ErrorAction Stop | Out-Null
            Write-Verbose "Utworzono udział: $smbName"
        }
        catch {
            Write-Warning "Nie można utworzyć udziału: $smbName - $_"
        }
    }

} finally {
    Stop-Transcript | Out-Null
    Write-Verbose "=====> Kopiowanie udziałów zakończone... `n"
    Write-Verbose "Koniec skryptu, logi zapisane w: $LogFolder"
}