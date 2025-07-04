# Custom Alerts Dashboard - Azure Monitor Solution

An Azure monitoring solution that includes Log Analytics, Data Collection Rules, Logic Apps, and custom dashboards.

## Prerequisites

- Azure CLI installed and configured
- PowerShell 5.1 or later
- Appropriate Azure permissions for resource deployment

## Setup

1. **Clone this repository**

   ```bash
   git clone <your-repo-url>
   cd "Custom Alerts Dashboard"
   ```

2. **Configure deployment parameters**

   Option A - Use the interactive setup script (recommended):
   ```powershell
   .\setup.ps1
   ```

   Option B - Manual configuration:
   ```powershell
   # Copy the template configuration file
   Copy-Item "config.template.json" "config.json"
   
   # Edit config.json with your Azure subscription details
   # Note: config.json is gitignored to prevent exposing sensitive information
   ```

3. **Update config.json with your values (if using manual setup):**

   ```json
   {
       "ResourceGroupName": "your-resource-group-name",
       "Location": "your-preferred-azure-region",
       "SubscriptionId": "your-azure-subscription-id",
       "EnvironmentName": "dev|staging|prod"
   }
   ```

## Deployment

Run the deployment script:

```powershell
.\deploy.ps1
```

Or specify a custom config file:

```powershell
.\deploy.ps1 -ConfigFile "config-dev.json"
```

## Architecture

The solution deploys:

- **Log Analytics Workspace** - Central logging and monitoring
- **Data Collection Rule (DCR)** - Defines data collection and routing
- **Data Collection Endpoint (DCE)** - Secure data ingestion endpoint
- **Custom Table** (`MyCustomTable_CL`) - Table schema: `TimeGenerated`, `Message`, `Severity`, `Type`
- **Logic App** - Automated alert processing and custom logic (runs every 5 minutes)
- **Custom Alerts Dashboard** - Azure Workbook for visualization

## Dashboard Features

The Custom Alerts Dashboard provides:

- **Total Alerts** count
- **Recent Alerts** (last hour)
- **Last Alert Time**
- **Alert Distribution by Severity** (pie chart)
- **Alert Volume Over Time** (time chart)
- **Recent Alerts Table** (latest 50 records)

## Security

- Sensitive configuration values are stored in `config.json` (gitignored)
- Uses Azure Managed Identity for secure authentication
- Implements least-privilege RBAC permissions
- All resources follow Azure security best practices

## Multiple Environments

Create separate config files for different environments:

- `config-dev.json`
- `config-staging.json`
- `config-prod.json`

Deploy to specific environments:

```powershell
.\deploy.ps1 -ConfigFile "config-dev.json"
```

## Key Features

- **Idempotent** - Safe to run multiple times
- **In-place updates** - Updates existing resources instead of creating duplicates
- **Deterministic GUIDs** - Consistent workbook IDs across deployments

## Files Structure

- `setup.ps1` - Interactive setup script for first-time configuration
- `deploy.ps1` - Main deployment script
- `infrastructure.bicep` - Azure infrastructure as code
- `logic-app.template.json` - Logic App ARM template
- `dashboard.template.json` - Custom dashboard template
- `config.template.json` - Configuration template (safe to commit)
- `config.json` - Your actual configuration (gitignored)

## Access URLs

After deployment, access your resources:

- **Log Analytics**: Azure Portal → Log Analytics Workspaces → MyLogAnalyticsWorkspace-{env}
- **Custom Alerts Dashboard**: Azure Portal → Monitor → Workbooks → Custom Alerts Dashboard
- **Logic App**: Azure Portal → Logic Apps → CustomAlertLogicApp-{env}

## Troubleshooting

1. **Permission Issues**: Ensure your Azure account has Contributor access to the subscription
2. **Quota Limits**: Check Azure resource quotas in your target region
3. **Resource Conflicts**: Use different EnvironmentName values to avoid naming conflicts

## Contributing

1. Never commit `config.json` or other files containing sensitive data
2. Update `config.template.json` when adding new configuration parameters
3. Test deployments in a development environment first