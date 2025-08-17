# Pester v5 tests for Move-Share.ps1

Describe 'Move-Share.ps1' {

    $scriptPath = 'd:\Git-Projects\Powershell-Scripts\ShareMigrate\Move-Share.ps1'

    Context 'When exported shares file is missing' {
        It 'writes an error about missing exported shares file' {
            Mock -CommandName Test-Path -MockWith {
                param($Path)
                if ($Path -eq 'C:\missing_shares.xml') { return $false } else { return $true }
            }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName New-Item
            Mock -CommandName Write-Error

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\missing_shares.xml' -ExportedSharesAccess 'C:\access.xml' -LogFolder 'C:\logs' 2>$null

            Assert-MockCalled -CommandName Write-Error -Times 1 -Exactly -Scope It
        }
    }

    Context 'When shares and access present' {
        It 'calls Robocopy and creates SMB share' {
            Mock -CommandName Test-Path -MockWith { return $true }

            $sampleShare = [PSCustomObject]@{ Name = 'Share1'; FolderEnumerationMode = 'AccessBased'; CachingMode = 'Manual'; EncryptData = $false }
            Mock -CommandName Import-Clixml -MockWith { param($Path) if ($Path -like '*shares.xml') { return @($sampleShare) } else { return @([PSCustomObject]@{AccessRight='Full'; Name='Share1'; AccountName='DOMAIN\User'}) } }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName New-Item
            Mock -CommandName Robocopy.exe
            Mock -CommandName Get-SmbShare -MockWith { return $null }
            Mock -CommandName New-SmbShare

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\shares.xml' -ExportedSharesAccess 'C:\sharesAccess.xml' -LogFolder 'C:\logs'

            Assert-MockCalled -CommandName Robocopy.exe -Times 1 -Scope It
            Assert-MockCalled -CommandName New-SmbShare -Times 1 -Scope It
        }
    }

    Context 'When exported access file is missing' {
        It 'writes an error about missing access file and returns' {
            Mock -CommandName Test-Path -MockWith {
                param($Path)
                if ($Path -eq 'C:\sharesAccess_missing.xml') { return $false } else { return $true }
            }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName Write-Error

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\shares.xml' -ExportedSharesAccess 'C:\sharesAccess_missing.xml' -LogFolder 'C:\logs' 2>$null

            Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It
        }
    }

    Context 'When Robocopy returns an error code (>=8)' {
        It 'emits a warning about robocopy failure' {
            Mock -CommandName Test-Path -MockWith { return $true }

            $sampleShare = [PSCustomObject]@{ Name = 'Share1'; FolderEnumerationMode = $null; CachingMode = $null; EncryptData = $null }
            Mock -CommandName Import-Clixml -MockWith { param($Path) if ($Path -like '*shares.xml') { return @($sampleShare) } else { return @([PSCustomObject]@{AccessRight='Full'; Name='Share1'; AccountName='DOMAIN\User'}) } }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName New-Item

            Mock -CommandName Robocopy.exe -MockWith {
                $global:LASTEXITCODE = 8
                return 0
            }

            Mock -CommandName Get-SmbShare -MockWith { return $null }
            Mock -CommandName New-SmbShare
            Mock -CommandName Write-Warning

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\shares.xml' -ExportedSharesAccess 'C:\sharesAccess.xml' -LogFolder 'C:\logs' 2>$null

            Assert-MockCalled -CommandName Robocopy.exe -Times 1 -Scope It
            Assert-MockCalled -CommandName Write-Warning -Times 1 -Scope It
        }
    }

    Context 'When SMB share already exists' {
        It 'skips New-SmbShare' {
            Mock -CommandName Test-Path -MockWith { return $true }

            $sampleShare = [PSCustomObject]@{ Name = 'Share1'; FolderEnumerationMode = $null; CachingMode = $null; EncryptData = $null }
            Mock -CommandName Import-Clixml -MockWith { param($Path) if ($Path -like '*shares.xml') { return @($sampleShare) } else { return @([PSCustomObject]@{AccessRight='Full'; Name='Share1'; AccountName='DOMAIN\User'}) } }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName New-Item
            Mock -CommandName Robocopy.exe -MockWith { $global:LASTEXITCODE = 1; return 0 }

            Mock -CommandName Get-SmbShare -MockWith { return [PSCustomObject]@{ Name = 'Share1_migrate' } }
            Mock -CommandName New-SmbShare

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\shares.xml' -ExportedSharesAccess 'C:\sharesAccess.xml' -LogFolder 'C:\logs' 2>$null

            Assert-MockCalled -CommandName Get-SmbShare -Times 1 -Scope It
            Assert-MockNotCalled -CommandName New-SmbShare -Scope It
        }
    }

    Context 'When destination folder is missing' {
        It 'creates destination folder' {
            Mock -CommandName Test-Path -MockWith {
                param($Path)
                if ($Path -eq 'D:\dest') { return $false }
                return $true
            }

            $sampleShare = [PSCustomObject]@{ Name = 'Share1'; FolderEnumerationMode = $null; CachingMode = $null; EncryptData = $null }
            Mock -CommandName Import-Clixml -MockWith { param($Path) if ($Path -like '*shares.xml') { return @($sampleShare) } else { return @([PSCustomObject]@{AccessRight='Full'; Name='Share1'; AccountName='DOMAIN\User'}) } }

            Mock -CommandName Start-Transcript
            Mock -CommandName Stop-Transcript
            Mock -CommandName New-Item
            Mock -CommandName Robocopy.exe -MockWith { $global:LASTEXITCODE = 1; return 0 }
            Mock -CommandName Get-SmbShare -MockWith { return $null }
            Mock -CommandName New-SmbShare

            & $scriptPath -ComputerName 'SRC' -Destination 'D:\dest' -ExportedSharesFile 'C:\shares.xml' -ExportedSharesAccess 'C:\sharesAccess.xml' -LogFolder 'C:\logs' 2>$null

            Assert-MockCalled -CommandName New-Item -TimesAtLeast 1 -Scope It
        }
    }

}