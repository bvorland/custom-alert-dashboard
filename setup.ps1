# Setup script for Custom Alerts Dashboard
# This script helps you configure the project for first-time deployment

Write-Host "=== Custom Alerts Dashboard Setup ===" -ForegroundColor Green

# Check if config.json already exists
if (Test-Path "config.json") {
    Write-Host "✅ config.json already exists" -ForegroundColor Yellow
    $config = Get-Content "config.json" | ConvertFrom-Json
    Write-Host "Current configuration:"
    Write-Host "  Resource Group: $($config.ResourceGroupName)"
    Write-Host "  Location: $($config.Location)"
    Write-Host "  Subscription ID: $($config.SubscriptionId)"
    Write-Host "  Environment: $($config.EnvironmentName)"
    
    $overwrite = Read-Host "`nDo you want to reconfigure? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Setup complete! You can now run .\deploy.ps1" -ForegroundColor Green
        exit 0
    }
}

# Copy template if config doesn't exist
if (-not (Test-Path "config.json")) {
    Write-Host "📋 Copying config template..." -ForegroundColor Cyan
    Copy-Item "config.template.json" "config.json"
}

# Get user input for configuration
Write-Host "`n📝 Please provide your Azure configuration:" -ForegroundColor Cyan

$resourceGroup = Read-Host "Resource Group Name [MyMonitorRG]"
if ([string]::IsNullOrWhiteSpace($resourceGroup)) { $resourceGroup = "MyMonitorRG" }

$location = Read-Host "Azure Region [westeurope]"
if ([string]::IsNullOrWhiteSpace($location)) { $location = "westeurope" }

$subscriptionId = Read-Host "Azure Subscription ID (required)"
while ([string]::IsNullOrWhiteSpace($subscriptionId)) {
    Write-Host "⚠️  Subscription ID is required!" -ForegroundColor Red
    $subscriptionId = Read-Host "Azure Subscription ID"
}

$environment = Read-Host "Environment Name [prod]"
if ([string]::IsNullOrWhiteSpace($environment)) { $environment = "prod" }

# Create configuration object
$config = @{
    ResourceGroupName = $resourceGroup
    Location = $location
    SubscriptionId = $subscriptionId
    EnvironmentName = $environment
}

# Save configuration
Write-Host "`n💾 Saving configuration..." -ForegroundColor Cyan
$config | ConvertTo-Json -Depth 2 | Set-Content "config.json"

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
Write-Host "Configuration saved to config.json (this file is gitignored for security)"
Write-Host "`nNext steps:"
Write-Host "1. Review your configuration in config.json"
Write-Host "2. Run .\deploy.ps1 to deploy your Custom Alerts Dashboard"
Write-Host "3. Access your resources through the Azure Portal"
