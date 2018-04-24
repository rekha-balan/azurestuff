export AZURE_STORAGE_CONNECTION_STRING=$( az storage account show-connection-string \
--resource-group acctestrg \
--output tsv \
--name myrestoreaccount )
echo $AZURE_STORAGE_CONNECTION_STRING
