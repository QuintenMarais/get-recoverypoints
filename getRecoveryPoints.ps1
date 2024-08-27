# Connect to Azure using device code authentication and select the specific tenant
Connect-AzAccount

# Define the date range
$startDate = (Get-Date).AddDays(-9370) # 1 Jan 1999
$endDate = Get-Date

# Array to store backup information
$backupData = @()

# List of Recovery Services Vaults to iterate through
$vaults = @(
    "Vault1",    # ADD ALL YOUR VAULTS HERE
    "Vault2"     # NO , in the Last Line
)

# The Resource Group the Resovery service vaut is located in
$Resourcegroup = "ResourceGroup1" # ADD THE RESOURCE GROUP HERE

# Start progress
$totalVaults = $vaults.Count
$currentVault = 0

# Loop through each vault
foreach ($vaultName in $vaults) {
    $currentVault++
    Write-Host "Processing Vault $currentVault of $totalVaults - $vaultName"

    # Get the vault details
    $vaultDetails = Get-AzRecoveryServicesVault -ResourceGroupName $Resourcegroup -Name $vaultName

    # Get all Azure VM containers in the vault
    $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $vaultDetails.ID

    $totalContainers = $containers.Count
    $currentContainer = 0

    foreach ($container in $containers) {
        $currentContainer++
        Write-Host "    Processing Container $currentContainer of $totalContainers - $($container.FriendlyName)"

        # Get all backup items within the container
        $backupItems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM -VaultId $vaultDetails.ID

        $totalBackupItems = $backupItems.Count
        $currentBackupItem = 0

        foreach ($backupItem in $backupItems) {
            $currentBackupItem++
            Write-Host "        Processing Backup Item $currentBackupItem of $totalBackupItems - $($backupItem.Name)"

            # Get recovery points within the specified date range
            $recoveryPoints = Get-AzRecoveryServicesBackupRecoveryPoint -Item $backupItem -StartDate $startDate.ToUniversalTime() -EndDate $endDate.ToUniversalTime() -VaultId $vaultDetails.ID

            $totalRecoveryPoints = $recoveryPoints.Count
            $currentRecoveryPoint = 0

            foreach ($rp in $recoveryPoints) {
                $currentRecoveryPoint++
                Write-Host "            Processing Recovery Point $currentRecoveryPoint of $totalRecoveryPoints - $($rp.RecoveryPointTime)"

                # Add the relevant information to the array
                $backupData += [PSCustomObject]@{
                    RecoveryPointAdditionalInfo    = $rp.RecoveryPointAdditionalInfo
                    SourceVMStorageType            = $rp.SourceVMStorageType
                    SourceResourceId               = $rp.SourceResourceId
                    EncryptionEnabled              = $rp.EncryptionEnabled
                    IlrSessionActive               = $rp.IlrSessionActive
                    IsManagedVirtualMachine        = $rp.IsManagedVirtualMachine
                    KeyAndSecretDetails            = $rp.KeyAndSecretDetails
                    OriginalSAEnabled              = $rp.OriginalSAEnabled
                    Zones                          = $rp.Zones
                    RecoveryPointType              = $rp.RecoveryPointType
                    RecoveryPointTime              = $rp.RecoveryPointTime
                    RecoveryPointId                = $rp.RecoveryPointId
                    ItemName                       = $rp.ItemName
                    Id                             = $rp.Id
                    WorkloadType                   = $rp.WorkloadType
                    ContainerName                  = $rp.ContainerName
                    ContainerType                  = $rp.ContainerType
                    BackupManagementType           = $rp.BackupManagementType
                    RecoveryPointTier              = $rp.RecoveryPointTier
                    RehydrationExpiryTime          = $rp.RehydrationExpiryTime
                    RecoveryPointMoveReadinessInfo = $rp.RecoveryPointMoveReadinessInfo
                    RecoveryPointExpiryTime        = $rp.RecoveryPointExpiryTime
                    RuleName                       = $rp.RuleName
                }
            }
        }
    }
}

# Output the gathered backup information
$backupData

# Optionally, export the data to a CSV
$backupData | Export-Csv -Path "BackupData.csv" -NoTypeInformation

# Final message
Write-Host "Backup data collection complete."
