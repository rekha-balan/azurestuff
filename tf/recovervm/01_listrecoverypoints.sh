az backup recoverypoint list \
--resource-group acctestrg \
--vault-name vault581 \
--container-name acctvm \
--item-name acctvm \
--query [0].name \
--output tsv
