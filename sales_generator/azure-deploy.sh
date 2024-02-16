export RESOURCE_GROUP_NAME=
export REGISTRY_NAME=
export bootstrap_servers=
export sasl_username='$ConnnectionString'
export sasl_password=
export topic_products=products
export topic_purchases=purchases
export topic_inventories=inventories

RESOURCE_ID=$(az group show \
  --resource-group $RESOURCE_GROUP_NAME \
  --query id \
  --output tsv)
echo $RESOURCE_ID

APP_SERVICE_PLAN_NAME='sales-streaming-web-app-plan'

az appservice plan create --name $APP_SERVICE_PLAN_NAME --resource-group $RESOURCE_GROUP_NAME --sku B1 --is-linux


APP_SERVICE_NAME='sales-data-stream'

CONTAINER_NAME=$REGISTRY_NAME'.azurecr.io/salesstreamingdata:latest'

az webapp create \
  --resource-group $RESOURCE_GROUP_NAME \
  --plan $APP_SERVICE_PLAN_NAME \
  --name $APP_SERVICE_NAME \
  --assign-identity '[system]' \
  --scope $RESOURCE_ID \
  --role acrpull \
  --deployment-container-image-name $CONTAINER_NAME 

az webapp config set --resource-group $RESOURCE_GROUP_NAME --name $APP_SERVICE_NAME --generic-configurations '{"acrUseManagedIdentityCreds": true}'  

CREDENTIAL=$(az webapp deployment list-publishing-credentials --resource-group $RESOURCE_GROUP_NAME --name $APP_SERVICE_NAME --query publishingPassword --output tsv)
echo $CREDENTIAL

SERVICE_URI='https://$'$APP_SERVICE_NAME':'$CREDENTIAL'@'$APP_SERVICE_NAME'.scm.azurewebsites.net/api/registry/webhook'

az acr webhook create \
  --name webhookforsalesdata \
  --registry $REGISTRY_NAME \
  --scope salesstreamingdata:* \
  --uri $SERVICE_URI \
  --actions push 

az webapp config appsettings set --resource-group $RESOURCE_GROUP_NAME --name $APP_SERVICE_NAME --settings kafka_env=eventhub bootstrap_servers=$bootstrap_servers sasl_username=$sasl_username sasl_password=$sasl_password  topic_products=$topic_products topic_purchases=$topic_purchases topic_inventories=$topic_inventories