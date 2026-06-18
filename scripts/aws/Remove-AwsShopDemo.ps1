<#
.SYNOPSIS
    Elimina los recursos del laboratorio ShopDemo en AWS.

.DESCRIPTION
    Usa el archivo .deploy-state.json generado por Deploy-AwsShopDemo.ps1.
    Ref: docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md §19

.PARAMETER EnvFile
    Ruta a .env.aws (fallback si no hay state file).

.PARAMETER Force
    Omite confirmación interactiva.

.EXAMPLE
    .\Remove-AwsShopDemo.ps1
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env.aws'),
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StatePath = Join-Path $PSScriptRoot '.deploy-state.json'
$script:AwsGlobalArgs = @()

function Write-Info { param([string]$Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Warn { param([string]$Message) Write-Host "    [AVISO] $Message" -ForegroundColor Yellow }

function Import-EnvFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @{} }
    $config = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $config[$line.Substring(0, $idx).Trim()] = $line.Substring($idx + 1).Trim()
    }
    return $config
}

function Invoke-Aws {
    param([string[]]$AwsArguments, [switch]$AllowFailure)
    $out = & aws @script:AwsGlobalArgs @AwsArguments 2>&1
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) {
        Write-Warn "Falló: aws $($AwsArguments -join ' ') — $out"
    }
    return $out
}

$cfg = Import-EnvFile -Path $EnvFile
$state = $null
if (Test-Path $StatePath) {
    $state = Get-Content $StatePath -Raw | ConvertFrom-Json
}

$region = if ($state.region) { $state.region } else { $cfg.AWS_REGION }
$prefix = if ($state.labPrefix) { $state.labPrefix } else { $cfg.LAB_PREFIX }
$cluster = if ($state.ecsCluster) { $state.ecsCluster } else { $cfg.ECS_CLUSTER_NAME }
$eksCluster = if ($state.eksCluster) { $state.eksCluster } else { $cfg.EKS_CLUSTER_NAME }

if ($cfg.AWS_PROFILE) { $script:AwsGlobalArgs += @('--profile', $cfg.AWS_PROFILE) }
$script:AwsGlobalArgs += @('--region', $region)

Write-Host ""
Write-Host "Eliminar laboratorio ShopDemo en AWS (prefijo: $prefix, región: $region)" -ForegroundColor Yellow
Write-Host "Ref: docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md §19" -ForegroundColor DarkGray
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Escribe 'delete-$prefix' para confirmar"
    if ($confirm -ne "delete-$prefix") {
        Write-Host "Cancelado." -ForegroundColor DarkGray
        exit 0
    }
}

# --- EKS ---
if ($eksCluster) {
    if (Get-Command eksctl -ErrorAction SilentlyContinue) {
        Write-Info "Eliminar cluster EKS $eksCluster (eksctl)..."
        & eksctl delete cluster --name $eksCluster --region $region 2>$null
    }
    else {
        Write-Warn "eksctl no disponible — elimina EKS manualmente: $eksCluster"
    }
}

# --- ECS services ---
if ($cluster) {
    $services = @(
        "$prefix-mcp", "$prefix-analytics", "$prefix-orders", "$prefix-inventory",
        "$prefix-catalog", "$prefix-azurite", "$prefix-postgres"
    )
    foreach ($svc in $services) {
        Write-Info "Detener servicio ECS $svc"
        Invoke-Aws @(
            'ecs', 'update-service', '--cluster', $cluster, '--service', $svc, '--desired-count', '0'
        ) -AllowFailure | Out-Null
        Invoke-Aws @(
            'ecs', 'delete-service', '--cluster', $cluster, '--service', $svc, '--force'
        ) -AllowFailure | Out-Null
    }
    Invoke-Aws @('ecs', 'delete-cluster', '--cluster', $cluster) -AllowFailure | Out-Null
}

# --- ALBs y target groups ---
$albNames = @("$prefix-catalog-alb", "$prefix-orders-alb", "$prefix-analytics-alb", "$prefix-mcp-alb")
foreach ($albName in $albNames) {
    $albArn = (Invoke-Aws @(
        'elbv2', 'describe-load-balancers', '--names', $albName,
        '--query', 'LoadBalancers[0].LoadBalancerArn', '--output', 'text'
    ) -AllowFailure).Trim()
    if ($albArn -and $albArn -ne 'None') {
        Write-Info "Eliminar ALB $albName"
        Invoke-Aws @('elbv2', 'delete-load-balancer', '--load-balancer-arn', $albArn) -AllowFailure | Out-Null
    }
}
$tgNames = @("$prefix-catalog-tg", "$prefix-orders-tg", "$prefix-analytics-tg", "$prefix-mcp-tg")
foreach ($tgName in $tgNames) {
    $tgArn = (Invoke-Aws @(
        'elbv2', 'describe-target-groups', '--names', $tgName,
        '--query', 'TargetGroups[0].TargetGroupArn', '--output', 'text'
    ) -AllowFailure).Trim()
    if ($tgArn -and $tgArn -ne 'None') {
        Invoke-Aws @('elbv2', 'delete-target-group', '--target-group-arn', $tgArn) -AllowFailure | Out-Null
    }
}

# --- Cloud Map ---
$ns = Invoke-Aws @(
    'servicediscovery', 'list-namespaces',
    '--filters', "Name=NAME,Values=$($cfg.CLOUDMAP_NAMESPACE)",
    '--output', 'json'
) -AllowFailure
if ($LASTEXITCODE -eq 0) {
    $nsObj = $ns | ConvertFrom-Json
    foreach ($n in $nsObj.Namespaces) {
        $svcs = Invoke-Aws @(
            'servicediscovery', 'list-services',
            '--filters', "Name=NAMESPACE_ID,Values=$($n.Id)", '--output', 'json'
        ) -AllowFailure
        if ($LASTEXITCODE -eq 0) {
            ($svcs | ConvertFrom-Json).Services | ForEach-Object {
                Invoke-Aws @('servicediscovery', 'delete-service', '--id', $_.Id) -AllowFailure | Out-Null
            }
        }
        Invoke-Aws @('servicediscovery', 'delete-namespace', '--id', $n.Id) -AllowFailure | Out-Null
    }
}

# --- SSM parameters ---
$ssmParams = @('eh-connection', 'pg-catalog', 'pg-orders', 'pg-inventory', 'azurite-checkpoint')
foreach ($p in $ssmParams) {
    Invoke-Aws @('ssm', 'delete-parameter', '--name', "/$prefix/$p") -AllowFailure | Out-Null
}

# --- Log groups ---
$logs = @(
    "/ecs/$prefix-postgres", "/ecs/$prefix-azurite", "/ecs/$prefix-catalog",
    "/ecs/$prefix-inventory", "/ecs/$prefix-orders", "/ecs/$prefix-analytics", "/ecs/$prefix-mcp"
)
foreach ($lg in $logs) {
    Invoke-Aws @('logs', 'delete-log-group', '--log-group-name', $lg) -AllowFailure | Out-Null
}

# --- VPC (si está en state) ---
$vpcId = $state.vpcId
if ($vpcId) {
    Write-Info "Eliminar VPC $vpcId y dependencias..."
    $subnets = Invoke-Aws @(
        'ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$vpcId",
        '--query', 'Subnets[].SubnetId', '--output', 'text'
    ) -AllowFailure
    foreach ($sn in ($subnets -split "`t")) {
        if ($sn) { Invoke-Aws @('ec2', 'delete-subnet', '--subnet-id', $sn) -AllowFailure | Out-Null }
    }
    $sgs = @("$prefix-alb", "$prefix-apps", "$prefix-data")
    foreach ($sgName in $sgs) {
        $sgId = (Invoke-Aws @(
            'ec2', 'describe-security-groups',
            '--filters', "Name=group-name,Values=$sgName", "Name=vpc-id,Values=$vpcId",
            '--query', 'SecurityGroups[0].GroupId', '--output', 'text'
        ) -AllowFailure).Trim()
        if ($sgId -and $sgId -ne 'None') {
            Invoke-Aws @('ec2', 'delete-security-group', '--group-id', $sgId) -AllowFailure | Out-Null
        }
    }
    $igw = (Invoke-Aws @(
        'ec2', 'describe-internet-gateways',
        '--filters', "Name=attachment.vpc-id,Values=$vpcId",
        '--query', 'InternetGateways[0].InternetGatewayId', '--output', 'text'
    ) -AllowFailure).Trim()
    if ($igw -and $igw -ne 'None') {
        Invoke-Aws @('ec2', 'detach-internet-gateway', '--internet-gateway-id', $igw, '--vpc-id', $vpcId) -AllowFailure | Out-Null
        Invoke-Aws @('ec2', 'delete-internet-gateway', '--internet-gateway-id', $igw) -AllowFailure | Out-Null
    }
    Invoke-Aws @('ec2', 'delete-vpc', '--vpc-id', $vpcId) -AllowFailure | Out-Null
}

# --- IAM role (lab) ---
$roleName = "$prefix-ecs-execution"
Invoke-Aws @('iam', 'delete-role-policy', '--role-name', $roleName, '--policy-name', 'ShopDemoSsmRead') -AllowFailure | Out-Null
Invoke-Aws @(
    'iam', 'detach-role-policy', '--role-name', $roleName,
    '--policy-arn', 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'
) -AllowFailure | Out-Null
Invoke-Aws @('iam', 'delete-role', '--role-name', $roleName) -AllowFailure | Out-Null

if (Test-Path $StatePath) { Remove-Item $StatePath -Force }

Write-Host ""
Write-Host "[OK] Limpieza iniciada. Verifica en Consola ECS/EC2/VPC." -ForegroundColor Green
Write-Host "ECR: los repositorios no se borran (conserva imágenes) — elimínalos manualmente si quieres." -ForegroundColor DarkGray
Write-Host "No commitees k8s/secrets.yaml si fue generado." -ForegroundColor DarkGray
Write-Host ""
