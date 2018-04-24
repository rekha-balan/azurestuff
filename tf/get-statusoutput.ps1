$vmResourceGroupName="jminck-vault-rg"
$VMName="control2-test"
$ScriptName="customScript"
$output = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $vmResourceGroupName `
                                            -VMName $vmName `
                                            -Name $ScriptName `
                                            -Status
$output.Statuses
