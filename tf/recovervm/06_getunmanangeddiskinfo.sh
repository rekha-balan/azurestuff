AZURE_STORAGE_CONNECTION_STRING=$(./05_exportconnectionstring.sh)
container=$(az storage container list --query [0].name -o tsv --connection-string=\'$AZURE_STORAGE_CONNECTION_STRING\')
blob=$(az storage blob list --container-name $container --query [0].name -o tsv --connection-string=\'$AZURE_STORAGE_CONNECTION_STRING\')
uri=$(az storage blob url --container-name $container --name $blob -o tsv --connection-string=\'$AZURE_STORAGE_CONNECTION_STRING\')
