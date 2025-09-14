<#
.SYNOPSIS
Testy jednostkowe dla skryptu Move-Share.ps1 przy użyciu frameworka Pester.

.DESCRIPTION
Ten zestaw testów weryfikuje poprawność działania skryptu Move-Share.ps1, który odpowiada za migrację udziałów sieciowych SMB. Testy koncentrują się na kluczowych aspektach działania skryptu, takich jak:
- Tworzenie folderu logowania
- Importowanie danych udziałów z pliku XML
- Wywoływanie narzędzia Robocopy
- Tworzenie udziałów SMB, jeśli nie istnieją

W sekcji BeforeEach mockowane są wszystkie zależności systemowe, aby testy mogły być uruchamiane w izolacji bez wpływu na rzeczywisty system plików czy konfigurację SMB.

.PARAMETER $scriptPath
Ścieżka do testowanego skryptu Move-Share.ps1, ustalana dynamicznie na podstawie lokalizacji testu.

.NOTES
Autor: Sebastian Cichoński  
Data utworzenia: Wrzesień 2025  
Framework: Pester v5  
#>


# ========================
# Sekcja przygotowawcza
# ========================

# Import funkcji do testowania
#. (Resolve-Path "$PSScriptRoot\..\Move-Share.ps1").Path
$scriptPath = (Get-Item "$PSScriptRoot\..\Move-Share.ps1").FullName
# ========================
# Blok testowy
# ========================

Describe 'Tests for Move-Share.ps1' {

    # Mockowanie zależności systemowych
    BeforeEach {
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName New-Item -MockWith { @{ FullName = 'C:\MockFolder' } }
        Mock -CommandName Start-Transcript
        Mock -CommandName Stop-Transcript
        Mock -CommandName Import-Clixml -MockWith { @(@{ Name = 'Share1' }) }
        Mock -CommandName Robocopy.exe -MockWith { $global:LASTEXITCODE = 0 }
        Mock -CommandName Get-SmbShare -MockWith { $null }
        Mock -CommandName New-SmbShare
        Mock -CommandName Write-Verbose
        Mock -CommandName Write-Warning
        Mock -CommandName Write-Error
    }

    It 'Powinien utworzyć folder logowania jeśli nie istnieje' {
        & $scriptPath -ComputerName 'Server01' -Destination 'C:\Dest'
        Assert-MockCalled -CommandName New-Item -Times 1
    }

    It 'Powinien zaimportować plik z udziałami' {
        & $scriptPath -ComputerName 'Server01' -Destination 'C:\Dest'
        Assert-MockCalled -CommandName Import-Clixml -Times 2
    }

    It 'Powinien wywołać Robocopy dla każdego udziału' {
        & $scriptPath -ComputerName 'Server01' -Destination 'C:\Dest'
        Assert-MockCalled -CommandName Robocopy.exe -Times 1
    }

    It 'Powinien utworzyć udział SMB jeśli nie istnieje' {
        & $scriptPath -ComputerName 'Server01' -Destination 'C:\Dest'
        Assert-MockCalled -CommandName New-SmbShare -Times 1
    }
}

# ========================
# Wywołanie testów
# ========================

Invoke-Pester