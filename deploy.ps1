# Fast idempotent deployment script for Custom Alerts Dashboard solution
param(
    [string]$ConfigFile = "config.json"
)

# Load configuration from JSON file
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Configuration file '$ConfigFile' not found. Please copy 'config.template.json' to '$ConfigFile' and update with your values."
    exit 1
}

Write-Host "Loading configuration from $ConfigFile..."
$config = Get-Content $ConfigFile | ConvertFrom-Json

$ResourceGroupName = $config.ResourceGroupName
$Location = $config.Location
$SubscriptionId = $config.SubscriptionId
$EnvironmentName = $config.EnvironmentName

# Set the subscription context
Write-Host "Setting subscription context..."
az account set --subscription $SubscriptionId

# Use consistent, deterministic names (no random numbers)
$dcrName = "MyDataCollectionRule-$EnvironmentName"
$workspaceName = "MyLogAnalyticsWorkspace-$EnvironmentName"
$dceName = "MyDCE-$EnvironmentName"
$customTableName = "MyCustomTable"
$logicAppName = "CustomAlertLogicApp-$EnvironmentName"

Write-Host "Deploying Custom Alerts Dashboard solution with parameters:"
Write-Host "  Environment: $EnvironmentName"
Write-Host "  Location: $Location"
Write-Host "  Resource Group: $ResourceGroupName"

# Check if resource group exists, create if it doesn't
Write-Host "Checking if resource group exists..."
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group $ResourceGroupName..."
    az group create --name $ResourceGroupName --location $Location
}

# Step 1: Deploy Infrastructure (fast, no validation)
Write-Host "`n=== STEP 1: Deploying Infrastructure ==="
$dcrDeploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "infrastructure.bicep" `
    --parameters `
        DCR_NAME=$dcrName `
        location=$Location `
        workspaceName=$workspaceName `
        dataCollectionEndpointName=$dceName `
        customTableName=$customTableName `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Infrastructure deployment failed!"
    exit 1
}

Write-Host "Infrastructure deployed successfully!"

# Extract outputs from infrastructure deployment
$dcrDeployment = $dcrDeploymentResult | ConvertFrom-Json
$workspaceId = $dcrDeployment.properties.outputs.workspaceId.value
$dceUrl = $dcrDeployment.properties.outputs.dataCollectionEndpointUrl.value
$dcrId = $dcrDeployment.properties.outputs.dataCollectionRuleId.value
$dcrImmutableId = $dcrDeployment.properties.outputs.dataCollectionRuleImmutableId.value
$actualCustomTableName = $dcrDeployment.properties.outputs.customTableName.value

# Step 2: Deploy Logic App (fast, no validation)
Write-Host "`n=== STEP 2: Deploying Logic App ==="
$logicAppDeploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "logic-app.template.json" `
    --parameters `
        logicAppName=$logicAppName `
        location=$Location `
        dataCollectionEndpointUrl=$dceUrl `
        dataCollectionRuleId=$dcrId `
        dataCollectionRuleImmutableId=$dcrImmutableId `
        customTableName=$actualCustomTableName `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Logic App deployment failed!"
    exit 1
}

Write-Host "Logic App deployed successfully!"

# Extract outputs from Logic App deployment
$logicAppDeployment = $logicAppDeploymentResult | ConvertFrom-Json
$logicAppId = $logicAppDeployment.properties.outputs.logicAppId.value
$systemIdentityId = $logicAppDeployment.properties.outputs.systemAssignedIdentity.value

# Step 3: Configure permissions (idempotent)
Write-Host "`n=== STEP 3: Configuring Permissions ==="

# Grant permissions (idempotent operations)
az role assignment create `
    --assignee $systemIdentityId `
    --role "Monitoring Metrics Publisher" `
    --scope $dcrId `
    --output none 2>$null

az role assignment create `
    --assignee $systemIdentityId `
    --role "Log Analytics Contributor" `
    --scope $workspaceId `
    --output none 2>$null

Write-Host "Permissions configured!"

# Step 4: Deploy Dashboard (fast, no validation)
Write-Host "`n=== STEP 4: Deploying Custom Alerts Dashboard ==="

# Generate deterministic GUID for the workbook
$guidSeed = "$EnvironmentName-workbook-$ResourceGroupName"
$hash = [System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($guidSeed))
$workbookGuid = [System.Guid]::new($hash).ToString()

$workbookDeploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "dashboard.template.json" `
    --parameters `
        workbookName=$workbookGuid `
        workspaceResourceId=$workspaceId `
        customTableName=$actualCustomTableName `
        location=$Location `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Dashboard deployment failed, but other resources are deployed successfully."
} else {
    Write-Host "Custom Alerts Dashboard deployed successfully!"
}

Write-Host "`n=== DEPLOYMENT COMPLETE ==="
Write-Host "✅ Custom Alerts Dashboard solution deployed!"
Write-Host "`nSUMMARY:"
Write-Host "  Resource Group: $ResourceGroupName"
Write-Host "  Environment: $EnvironmentName"
Write-Host "  Log Analytics Workspace: $workspaceName"
Write-Host "  Custom Table: $actualCustomTableName"
Write-Host "  Logic App: $logicAppName"
Write-Host "`nACCESS LINKS:"
Write-Host "  📋 View Logs: https://portal.azure.com/#view/Microsoft_OperationalInsights/LogAnalyticsBlade"
Write-Host "  📊 View Dashboard: https://portal.azure.com/#view/Microsoft_Azure_Monitoring/WorkbooksBrowseBlade"
Write-Host "`nTo redeploy, simply run this script again - it will update existing resources."
