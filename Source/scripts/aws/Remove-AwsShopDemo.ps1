<#
.SYNOPSIS
    Elimina todos los recursos del laboratorio ShopDemo en AWS.

.DESCRIPTION
    Usa .deploy-state.json y/o deploy-eks-report.json.
    Incluye EKS (eksctl), ECS, ECR, SSM, IAM lab, CloudFormation eksctl y VPC asociada.

.PARAMETER EnvFile
    Ruta a .env.aws

.PARAMETER Force
    Omite confirmación interactiva.

.PARAMETER DeleteEcr
    Elimina repositorios ECR shopdemo-* (por defecto: sí).

.PARAMETER SkipAccountClosureGuide
    No muestra instrucciones para cerrar la cuenta AWS al final.

.EXAMPLE
    .\Remove-AwsShopDemo.ps1 -Force
#>
[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env.aws'),
    [switch]$Force,
    [switch]$DeleteEcr = $true,
    [switch]$SkipAccountClosureGuide
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StatePath = Join-Path $PSScriptRoot '.deploy-state.json'
$EksReportPath = Join-Path $PSScriptRoot 'deploy-eks-report.json'
$script:AwsGlobalArgs = @()

function Write-Info { param([string]$Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Warn { param([string]$Message) Write-Host "    [AVISO] $Message" -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message) Write-Host "    [OK] $Message" -ForegroundColor Green }

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

function Ensure-EksctlInPath {
    $eksctlLocal = Join-Path $env:LOCALAPPDATA 'eksctl\eksctl.exe'
    if ((Test-Path $eksctlLocal) -and -not (Get-Command eksctl -ErrorAction SilentlyContinue)) {
        $env:Path = "$(Split-Path $eksctlLocal -Parent);$env:Path"
    }
}

function Remove-EksctlCloudFormationStacks {
    param([string]$ClusterName, [string]$Region)
    $stacks = Invoke-Aws @(
        'cloudformation', 'list-stacks', '--stack-status-filter',
        'CREATE_COMPLETE', 'UPDATE_COMPLETE', 'ROLLBACK_COMPLETE', 'DELETE_FAILED',
        '--query', "StackSummaries[?contains(StackName, '$ClusterName')].StackName",
        '--output', 'text'
    ) -AllowFailure
    foreach ($stack in (($stacks -split "`t") | Where-Object { $_ })) {
        Write-Info "Desactivar protección y eliminar stack $stack"
        Invoke-Aws @(
            'cloudformation', 'update-termination-protection',
            '--stack-name', $stack, '--no-enable-termination-protection'
        ) -AllowFailure | Out-Null
        Invoke-Aws @('cloudformation', 'delete-stack', '--stack-name', $stack) -AllowFailure | Out-Null
    }
}

function Remove-EcrRepositories {
    param([string]$Prefix, [string]$Region)
    $repos = @(
        "$Prefix-catalog", "$Prefix-orders", "$Prefix-inventory",
        "$Prefix-analytics", "$Prefix-mcp"
    )
    foreach ($repo in $repos) {
        Write-Info "Vaciar y eliminar ECR $repo"
        Invoke-Aws @(
            'ecr', 'batch-delete-image', '--repository-name', $repo,
            '--image-ids', 'imageTag=latest'
        ) -AllowFailure | Out-Null
        Invoke-Aws @('ecr', 'delete-repository', '--repository-name', $repo, '--force') -AllowFailure | Out-Null
    }
}

function Remove-IamLabPolicies {
    param([string]$AccountId)
    $policyNames = @('ShopDemoLabECS', 'ShopDemoLabEKS')
    foreach ($name in $policyNames) {
        $arn = "arn:aws:iam::${AccountId}:policy/$name"
        $entities = Invoke-Aws @(
            'iam', 'list-entities-for-policy', '--policy-arn', $arn, '--output', 'json'
        ) -AllowFailure
        if ($LASTEXITCODE -eq 0) {
            $obj = $entities | ConvertFrom-Json
            foreach ($u in $obj.PolicyUsers) {
                Invoke-Aws @('iam', 'detach-user-policy', '--user-name', $u.UserName, '--policy-arn', $arn) -AllowFailure | Out-Null
            }
            foreach ($g in $obj.PolicyGroups) {
                Invoke-Aws @('iam', 'detach-group-policy', '--group-name', $g.GroupName, '--policy-arn', $arn) -AllowFailure | Out-Null
            }
            foreach ($r in $obj.PolicyRoles) {
                Invoke-Aws @('iam', 'detach-role-policy', '--role-name', $r.RoleName, '--policy-arn', $arn) -AllowFailure | Out-Null
            }
        }
        Invoke-Aws @('iam', 'delete-policy', '--policy-arn', $arn) -AllowFailure | Out-Null
    }
}

function Remove-LoadBalancersByPrefix {
    param([string]$Prefix)
    $lbs = Invoke-Aws @('elbv2', 'describe-load-balancers', '--output', 'json') -AllowFailure
    if ($LASTEXITCODE -ne 0) { return }
    ($lbs | ConvertFrom-Json).LoadBalancers | Where-Object {
        $_.LoadBalancerName -like "$Prefix*" -or $_.LoadBalancerName -like 'k8s-*'
    } | ForEach-Object {
        Write-Info "Eliminar LB $($_.LoadBalancerName)"
        Invoke-Aws @('elbv2', 'delete-load-balancer', '--load-balancer-arn', $_.LoadBalancerArn) -AllowFailure | Out-Null
    }
}

function Show-AccountClosureGuide {
    Write-Host ""
    Write-Host "=== Cerrar cuenta AWS (manual, usuario ROOT) ===" -ForegroundColor Yellow
    Write-Host @"
1. Inicia sesión como usuario ROOT (email de la cuenta), no solo IAM.
2. Consola: icono cuenta (arriba derecha) → Account.
3. Baja hasta 'Close account' / 'Cerrar cuenta'.
4. Confirma; AWS inicia periodo de cierre (~90 días).
5. Antes de cerrar, verifica en Billing que no queden cargos:
   - EC2 (nodos EKS), EKS control plane, ECR, ELB, NAT Gateway.
6. Si 'Close account' está deshabilitado, quedan recursos activos:
   - Revisa CloudFormation, EC2, EKS, ECS, VPC en us-east-2.
7. Documentación: https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-closing.html
"@ -ForegroundColor DarkGray
    Write-Host ""
}

# --- Config ---
$cfg = Import-EnvFile -Path $EnvFile
$state = $null
if (Test-Path $StatePath) {
    $state = Get-Content $StatePath -Raw | ConvertFrom-Json
}
$eksReport = $null
if (Test-Path $EksReportPath) {
    $eksReport = Get-Content $EksReportPath -Raw | ConvertFrom-Json
}

$region = if ($state.region) { $state.region } elseif ($eksReport.region) { $eksReport.region } else { $cfg.AWS_REGION }
$prefix = if ($state.labPrefix) { $state.labPrefix } else { $cfg.LAB_PREFIX }
$cluster = if ($state.ecsCluster) { $state.ecsCluster } else { $cfg.ECS_CLUSTER_NAME }
$eksCluster = if ($state.eksCluster) { $state.eksCluster } else { $cfg.EKS_CLUSTER_NAME }
$accountId = if ($state.accountId) { $state.accountId } elseif ($eksReport.accountId) { $eksReport.accountId } else { $null }

if ($cfg.AWS_PROFILE) { $script:AwsGlobalArgs += @('--profile', $cfg.AWS_PROFILE) }
$script:AwsGlobalArgs += @('--region', $region)

Write-Host ""
Write-Host "=== Baja completa ShopDemo AWS ===" -ForegroundColor Yellow
Write-Host "Región: $region | Prefijo: $prefix | EKS: $eksCluster | ECS: $cluster" -ForegroundColor DarkGray
Write-Host ""

# --- Validar credenciales ---
$identity = Invoke-Aws @('sts', 'get-caller-identity', '--output', 'json')
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Credenciales AWS inválidas o expiradas." -ForegroundColor Red
    Write-Host "Ejecuta: aws configure" -ForegroundColor Yellow
    Write-Host "O crea nuevas access keys en IAM → Users → Security credentials." -ForegroundColor Yellow
    exit 1
}
$identityObj = $identity | ConvertFrom-Json
if (-not $accountId) { $accountId = $identityObj.Account }
Write-Ok "Cuenta AWS: $accountId | ARN: $($identityObj.Arn)"

if (-not $Force) {
    $confirm = Read-Host "Escribe 'delete-$prefix' para confirmar la baja de TODOS los recursos"
    if ($confirm -ne "delete-$prefix") {
        Write-Host "Cancelado." -ForegroundColor DarkGray
        exit 0
    }
}

Ensure-EksctlInPath

# --- K8s workloads (si kubectl apunta al cluster) ---
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Write-Info "Eliminar namespaces shopdemo e ingress-nginx (si existen)..."
    kubectl delete namespace shopdemo --ignore-not-found --timeout=120s 2>$null
    kubectl delete namespace ingress-nginx --ignore-not-found --timeout=120s 2>$null
}

# --- EKS ---
if ($eksCluster) {
    if (Get-Command eksctl -ErrorAction SilentlyContinue) {
        Write-Info "Eliminar cluster EKS $eksCluster (eksctl, puede tardar 10-15 min)..."
        & eksctl delete cluster --name $eksCluster --region $region --wait 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "eksctl delete falló — limpiando stacks CloudFormation..."
            Remove-EksctlCloudFormationStacks -ClusterName $eksCluster -Region $region
        }
    }
    else {
        Write-Warn "eksctl no disponible — eliminando stacks CFN asociados..."
        Remove-EksctlCloudFormationStacks -ClusterName $eksCluster -Region $region
    }
}

# --- LB residuales (Ingress K8s / ALB lab) ---
Remove-LoadBalancersByPrefix -Prefix $prefix

# --- ECS ---
if ($cluster) {
    $services = @(
        "$prefix-mcp", "$prefix-analytics", "$prefix-orders", "$prefix-inventory",
        "$prefix-catalog", "$prefix-azurite", "$prefix-postgres"
    )
    foreach ($svc in $services) {
        Write-Info "Eliminar servicio ECS $svc"
        Invoke-Aws @('ecs', 'update-service', '--cluster', $cluster, '--service', $svc, '--desired-count', '0') -AllowFailure | Out-Null
        Invoke-Aws @('ecs', 'delete-service', '--cluster', $cluster, '--service', $svc, '--force') -AllowFailure | Out-Null
    }
    Invoke-Aws @('ecs', 'delete-cluster', '--cluster', $cluster) -AllowFailure | Out-Null
}

# --- ALBs nombrados ---
$albNames = @("$prefix-catalog-alb", "$prefix-orders-alb", "$prefix-analytics-alb", "$prefix-mcp-alb")
foreach ($albName in $albNames) {
    $albArn = (Invoke-Aws @(
        'elbv2', 'describe-load-balancers', '--names', $albName,
        '--query', 'LoadBalancers[0].LoadBalancerArn', '--output', 'text'
    ) -AllowFailure).ToString().Trim()
    if ($albArn -and $albArn -ne 'None') {
        Invoke-Aws @('elbv2', 'delete-load-balancer', '--load-balancer-arn', $albArn) -AllowFailure | Out-Null
    }
}
$tgNames = @("$prefix-catalog-tg", "$prefix-orders-tg", "$prefix-analytics-tg", "$prefix-mcp-tg")
foreach ($tgName in $tgNames) {
    $tgArn = (Invoke-Aws @(
        'elbv2', 'describe-target-groups', '--names', $tgName,
        '--query', 'TargetGroups[0].TargetGroupArn', '--output', 'text'
    ) -AllowFailure).ToString().Trim()
    if ($tgArn -and $tgArn -ne 'None') {
        Invoke-Aws @('elbv2', 'delete-target-group', '--target-group-arn', $tgArn) -AllowFailure | Out-Null
    }
}

# --- Cloud Map ---
$nsName = if ($cfg.CLOUDMAP_NAMESPACE) { $cfg.CLOUDMAP_NAMESPACE } else { "$prefix.local" }
$ns = Invoke-Aws @(
    'servicediscovery', 'list-namespaces',
    '--filters', "Name=NAME,Values=$nsName", '--output', 'json'
) -AllowFailure
if ($LASTEXITCODE -eq 0) {
    ($ns | ConvertFrom-Json).Namespaces | ForEach-Object {
        $svcs = Invoke-Aws @(
            'servicediscovery', 'list-services',
            '--filters', "Name=NAMESPACE_ID,Values=$($_.Id)", '--output', 'json'
        ) -AllowFailure
        if ($LASTEXITCODE -eq 0) {
            ($svcs | ConvertFrom-Json).Services | ForEach-Object {
                Invoke-Aws @('servicediscovery', 'delete-service', '--id', $_.Id) -AllowFailure | Out-Null
            }
        }
        Invoke-Aws @('servicediscovery', 'delete-namespace', '--id', $_.Id) -AllowFailure | Out-Null
    }
}

# --- SSM ---
$ssmParams = @('eh-connection', 'pg-catalog', 'pg-orders', 'pg-inventory', 'azurite-checkpoint')
foreach ($p in $ssmParams) {
    Invoke-Aws @('ssm', 'delete-parameter', '--name', "/$prefix/$p") -AllowFailure | Out-Null
}

# --- Log groups ---
$logs = @(
    "/ecs/$prefix-postgres", "/ecs/$prefix-azurite", "/ecs/$prefix-catalog",
    "/ecs/$prefix-inventory", "/ecs/$prefix-orders", "/ecs/$prefix-analytics", "/ecs/$prefix-mcp",
    "/aws/eks/$eksCluster/cluster"
)
foreach ($lg in $logs) {
    if ($lg) { Invoke-Aws @('logs', 'delete-log-group', '--log-group-name', $lg) -AllowFailure | Out-Null }
}

# --- ECR ---
if ($DeleteEcr) {
    Remove-EcrRepositories -Prefix $prefix -Region $region
}

# --- VPC lab ECS o EKS report ---
$vpcId = $null
if ($state -and $state.vpcId) { $vpcId = $state.vpcId }
elseif ($eksReport -and $eksReport.cluster.vpcId) { $vpcId = $eksReport.cluster.vpcId }
else {
    $vpcId = (Invoke-Aws @(
        'ec2', 'describe-vpcs', '--filters', "Name=tag:Name,Values=$prefix-vpc",
        '--query', 'Vpcs[0].VpcId', '--output', 'text'
    ) -AllowFailure).ToString().Trim()
    if ($vpcId -eq 'None') { $vpcId = $null }
}

if ($vpcId) {
    Write-Info "Limpiar VPC $vpcId (solo si no la usa EKS activo)..."
    # NAT gateways
    $natIds = Invoke-Aws @(
        'ec2', 'describe-nat-gateways', '--filter', "Name=vpc-id,Values=$vpcId",
        '--query', 'NatGateways[?State!=`deleted`].NatGatewayId', '--output', 'text'
    ) -AllowFailure
    foreach ($nat in (($natIds -split "`t") | Where-Object { $_ })) {
        Invoke-Aws @('ec2', 'delete-nat-gateway', '--nat-gateway-id', $nat) -AllowFailure | Out-Null
    }
    Start-Sleep -Seconds 5
    $subnets = Invoke-Aws @(
        'ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$vpcId",
        '--query', 'Subnets[].SubnetId', '--output', 'text'
    ) -AllowFailure
    foreach ($sn in (($subnets -split "`t") | Where-Object { $_ })) {
        Invoke-Aws @('ec2', 'delete-subnet', '--subnet-id', $sn) -AllowFailure | Out-Null
    }
    $sgs = Invoke-Aws @(
        'ec2', 'describe-security-groups', '--filters', "Name=vpc-id,Values=$vpcId", '--output', 'json'
    ) -AllowFailure
    if ($LASTEXITCODE -eq 0) {
        ($sgs | ConvertFrom-Json).SecurityGroups | Where-Object { $_.GroupName -ne 'default' } | ForEach-Object {
            Invoke-Aws @('ec2', 'delete-security-group', '--group-id', $_.GroupId) -AllowFailure | Out-Null
        }
    }
    $igw = (Invoke-Aws @(
        'ec2', 'describe-internet-gateways',
        '--filters', "Name=attachment.vpc-id,Values=$vpcId",
        '--query', 'InternetGateways[0].InternetGatewayId', '--output', 'text'
    ) -AllowFailure).ToString().Trim()
    if ($igw -and $igw -ne 'None') {
        Invoke-Aws @('ec2', 'detach-internet-gateway', '--internet-gateway-id', $igw, '--vpc-id', $vpcId) -AllowFailure | Out-Null
        Invoke-Aws @('ec2', 'delete-internet-gateway', '--internet-gateway-id', $igw) -AllowFailure | Out-Null
    }
    Invoke-Aws @('ec2', 'delete-vpc', '--vpc-id', $vpcId) -AllowFailure | Out-Null
}

# --- IAM rol ECS execution ---
$roleName = "$prefix-ecs-execution"
Invoke-Aws @('iam', 'delete-role-policy', '--role-name', $roleName, '--policy-name', 'ShopDemoSsmRead') -AllowFailure | Out-Null
Invoke-Aws @(
    'iam', 'detach-role-policy', '--role-name', $roleName,
    '--policy-arn', 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'
) -AllowFailure | Out-Null
Invoke-Aws @('iam', 'delete-role', '--role-name', $roleName) -AllowFailure | Out-Null

# --- Políticas IAM del lab ---
if ($accountId) {
    Remove-IamLabPolicies -AccountId $accountId
}

if (Test-Path $StatePath) { Remove-Item $StatePath -Force }

Write-Host ""
Write-Ok "Limpieza ejecutada. Verifica en Consola: EKS, EC2, CloudFormation, ECR, Billing."
Write-Host "Cuenta del reporte: $accountId (us-east-2)" -ForegroundColor DarkGray

if (-not $SkipAccountClosureGuide) {
    Show-AccountClosureGuide
}
