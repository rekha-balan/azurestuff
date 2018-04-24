$vmName = "db01-test"
$rgName = "jminck-vault-rg"
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $rgName -Location "West US" -VMName $vmName -Name "ContosoTest" -TypeHandlerVersion "1.1" -StorageAccountName "jminckasr" -FileName "ipconfig.ps1" -ContainerName "files"
