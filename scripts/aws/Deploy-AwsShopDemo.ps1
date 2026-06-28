<#
.SYNOPSIS
    Provisiona la infraestructura AWS de ShopDemo (ECS Fargate, EKS o ambos).

.DESCRIPTION
    Script del curso Lite Thinking - ShopDemo.
    NO construye ni publica imágenes Docker (usar GitHub Actions o build manual).

    Modos:
      ECS  - VPC, ECR, SSM, ECS cluster, PostgreSQL/Azurite Fargate, 5 APIs + MCP (ALB/Cloud Map)
      EKS  - ECR, cluster EKS (eksctl), Ingress Helm, genera k8s/secrets.yaml
      All  - ECS + EKS

    Event Hubs: connection string de Azure (cross-cloud) - ver INTEGRACION-AZURE-EVENT-HUBS.md

    Documentación:
      - docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md
      - docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md
      - docs/integracion-ia/IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md
      - scripts/aws/README.md

.PARAMETER Mode
    ECS | EKS | All

.PARAMETER EnvFile
    Ruta al archivo .env.aws (por defecto: junto a este script).

.EXAMPLE
    cd I:\Curso\ShopDemo\scripts\aws
    copy .env.aws.example .env.aws
    aws configure
    .\Deploy-AwsShopDemo.ps1 -Mode ECS
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ECS', 'EKS', 'All')]
    [string] $Mode,

    [string] $EnvFile = (Join-Path $PSScriptRoot '.env.aws')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$StatePath = Join-Path $PSScriptRoot '.deploy-state.json'
$script:AwsGlobalArgs = @()

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------

function Write-Step { param([string]$Message) Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Info { param([string]$Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Warn { param([string]$Message) Write-Host "    [AVISO] $Message" -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message) Write-Host "    [OK] $Message" -ForegroundColor Green }

function Import-EnvFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "No se encontró '$Path'. Copia .env.aws.example a .env.aws." }
    $config = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $val = $line.Substring($idx + 1).Trim()
        if ($val -match '^<<<.*>>>$') {
            if ($key -eq 'EVENT_HUBS_CONNECTION_STRING') {
                Write-Warn 'EVENT_HUBS_CONNECTION_STRING pendiente - infra AWS continua; actualiza SSM /shopdemo/eh-connection cuando tengas Azure Event Hubs'
                $config[$key] = 'PENDING_AZURE_EVENT_HUBS'
            }
            else { throw "Completa '$key' en $Path" }
        }
        $config[$key] = $val
    }
    return $config
}

function Invoke-AwsCli {
    param(
        [string]$Label,
        [string[]]$AwsArguments,
        [switch]$AllowFailure
    )
    Write-Info $Label
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & aws @script:AwsGlobalArgs @AwsArguments 2>&1
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
    if ($LASTEXITCODE -ne 0 -and -not $AllowFailure) {
        throw "Falló: aws $($AwsArguments -join ' ')`n$output"
    }
    return $output
}

function Save-DeployState {
    param([hashtable]$State)
    ($State | ConvertTo-Json -Depth 6) | Set-Content -Path $StatePath -Encoding UTF8
    Write-Ok "Estado guardado en $StatePath (para Remove-AwsShopDemo.ps1)"
}

function Write-JsonFileNoBom {
    param([string]$Path, [string]$Json)
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Json, $utf8)
}

function ConvertTo-AwsFileUri {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path) -replace '\\', '/'
    return "file://$full"
}

function Test-EcsServiceExists {
    param([string]$Cluster, [string]$ServiceName)
    $json = Invoke-AwsCli "Comprobar servicio $ServiceName" @(
        'ecs', 'describe-services', '--cluster', $Cluster, '--services', $ServiceName, '--output', 'json'
    ) -AllowFailure | ConvertFrom-Json
    return ($json.services.Count -gt 0 -and $json.services[0].status -ne 'INACTIVE')
}

function Get-SsmParameterArn {
    param([string]$AccountId, [string]$Region, [string]$Name)
    return "arn:aws:ssm:${Region}:${AccountId}:parameter${Name}"
}

function Ensure-EksToolchain {
    $eksctlLocal = Join-Path $env:LOCALAPPDATA 'eksctl\eksctl.exe'
    if ((Test-Path $eksctlLocal) -and -not (Get-Command eksctl -ErrorAction SilentlyContinue)) {
        $env:Path = "$(Split-Path $eksctlLocal -Parent);$env:Path"
    }
    $helmLinks = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    if ((Test-Path $helmLinks) -and -not (Get-Command helm -ErrorAction SilentlyContinue)) {
        $env:Path = "$helmLinks;$env:Path"
    }
}

function Test-EksClusterExists {
    param([string]$ClusterName, [string]$Region)
    $null = Invoke-AwsCli 'Comprobar cluster EKS' @(
        'eks', 'describe-cluster', '--name', $ClusterName, '--region', $Region, '--output', 'json'
    ) -AllowFailure
    return ($LASTEXITCODE -eq 0)
}

function Deploy-K8sWorkloads {
    param(
        [string]$RepoRoot,
        [string]$Registry,
        [string]$Tag
    )
    $k8s = Join-Path $RepoRoot 'k8s'
    kubectl apply -f (Join-Path $k8s 'namespace.yaml') | Out-Null
    kubectl apply -f (Join-Path $k8s 'secrets.yaml') | Out-Null
    kubectl apply -f (Join-Path $k8s 'postgres\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'azurite\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'catalog\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'orders\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'inventory\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'analytics\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'mcp\') | Out-Null
    kubectl apply -f (Join-Path $k8s 'ingress\') | Out-Null

    $images = @(
        @{ Deploy = 'shopdemo-catalog'; Container = 'catalog-api'; Repo = 'shopdemo-catalog' }
        @{ Deploy = 'shopdemo-orders'; Container = 'orders-api'; Repo = 'shopdemo-orders' }
        @{ Deploy = 'shopdemo-inventory'; Container = 'inventory-api'; Repo = 'shopdemo-inventory' }
        @{ Deploy = 'shopdemo-analytics'; Container = 'analytics-api'; Repo = 'shopdemo-analytics' }
        @{ Deploy = 'shopdemo-mcp'; Container = 'mcp-api'; Repo = 'shopdemo-mcp' }
    )
    foreach ($img in $images) {
        kubectl set image "deployment/$($img.Deploy)" "$($img.Container)=$Registry/$($img.Repo):$Tag" -n shopdemo | Out-Null
    }
    Write-Ok 'Manifiestos k8s aplicados e imagenes ECR configuradas'
}

function Get-EksReleaseReport {
    param(
        [string]$ClusterName,
        [string]$Region,
        [string]$AccountId,
        [string]$EcrUri,
        [hashtable]$State
    )
    $report = @{
        generatedAt = (Get-Date).ToString('o')
        accountId   = $AccountId
        region      = $Region
        mode        = 'EKS'
        clusterName = $ClusterName
        ecrUri      = $EcrUri
        cluster     = $null
        nodegroups  = @()
        ingress     = $null
        workloads   = @()
        privateDns  = @{}
        publicUrls  = @{}
        eventHubs   = @{
            provider = 'Azure Event Hubs (cross-cloud)'
            hubName  = $State.eventHubName
            note     = 'Connection string en k8s/secrets.yaml (EVENT_HUBS_CONNECTION_STRING)'
        }
        ecrRepositories = @()
    }

    foreach ($repo in @('shopdemo-catalog', 'shopdemo-orders', 'shopdemo-inventory', 'shopdemo-analytics', 'shopdemo-mcp', 'postgres', 'azurite')) {
        $repoOut = Invoke-AwsCli "ECR repo $repo" @(
            'ecr', 'describe-repositories', '--repository-names', $repo, '--region', $Region, '--output', 'json'
        ) -AllowFailure
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($repoOut)) {
            $repoJson = $repoOut | ConvertFrom-Json
            if ($repoJson -and $repoJson.repositories) {
                $r = $repoJson.repositories[0]
                $report.ecrRepositories += @{
                    name = $r.repositoryName
                    arn  = $r.repositoryArn
                    uri  = $r.repositoryUri
                }
            }
        }
    }

    if (Test-EksClusterExists -ClusterName $ClusterName -Region $Region) {
        $clusterJson = Invoke-AwsCli 'Detalle cluster EKS' @(
            'eks', 'describe-cluster', '--name', $ClusterName, '--region', $Region, '--output', 'json'
        ) | ConvertFrom-Json
        $c = $clusterJson.cluster
        $report.cluster = @{
            arn                  = $c.arn
            endpoint             = $c.endpoint
            version              = $c.version
            status               = $c.status
            vpcId                = $c.resourcesVpcConfig.vpcId
            subnetIds            = @($c.resourcesVpcConfig.subnetIds)
            securityGroupIds     = @($c.resourcesVpcConfig.securityGroupIds)
            clusterSecurityGroup = $c.resourcesVpcConfig.clusterSecurityGroupId
            publicAccess         = $c.resourcesVpcConfig.endpointPublicAccess
            privateAccess        = $c.resourcesVpcConfig.endpointPrivateAccess
        }
        $ngJson = Invoke-AwsCli 'Nodegroups EKS' @(
            'eks', 'list-nodegroups', '--cluster-name', $ClusterName, '--region', $Region, '--output', 'json'
        ) -AllowFailure | ConvertFrom-Json
        if ($ngJson.nodegroups) {
            foreach ($ngName in $ngJson.nodegroups) {
                $ng = Invoke-AwsCli "Nodegroup $ngName" @(
                    'eks', 'describe-nodegroup', '--cluster-name', $ClusterName,
                    '--nodegroup-name', $ngName, '--region', $Region, '--output', 'json'
                ) | ConvertFrom-Json
                $report.nodegroups += @{
                    name          = $ngName
                    arn           = $ng.nodegroup.nodegroupArn
                    status        = $ng.nodegroup.status
                    instanceTypes = @($ng.nodegroup.instanceTypes)
                    scaling       = $ng.nodegroup.scalingConfig
                    subnets       = @($ng.nodegroup.subnets)
                }
            }
        }
    }

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $ingSvc = kubectl get svc -n ingress-nginx ingress-nginx-controller -o json 2>$null | ConvertFrom-Json
        if ($ingSvc) {
            $lbHost = ($ingSvc.status.loadBalancer.ingress | Select-Object -First 1).hostname
            $report.ingress = @{
                namespace    = 'ingress-nginx'
                service      = 'ingress-nginx-controller'
                loadBalancer = $lbHost
            }
            if ($lbHost) {
                $base = "http://$lbHost"
                $report.publicUrls = @{
                    catalog   = "$base/catalog/swagger"
                    orders    = "$base/orders/swagger"
                    inventory = "$base/inventory/health"
                    analytics = "$base/analytics/api/analytics/events"
                    mcp       = "$base/mcp/health"
                }
            }
        }
        $svcs = kubectl get svc -n shopdemo -o json 2>$null | ConvertFrom-Json
        if ($svcs) {
            foreach ($item in $svcs.items) {
                $port = $item.spec.ports[0].port
                $report.privateDns[$item.metadata.name] = "$($item.metadata.name).shopdemo.svc.cluster.local:$port"
                $report.workloads += @{
                    kind      = 'Service'
                    name      = $item.metadata.name
                    clusterIp = $item.spec.clusterIP
                    dns       = "$($item.metadata.name).shopdemo.svc.cluster.local"
                    port      = $port
                }
            }
        }
    }
    finally {
        $ErrorActionPreference = $prevEap
    }

    $reportPath = Join-Path $PSScriptRoot 'deploy-eks-report.json'
    ($report | ConvertTo-Json -Depth 8) | Set-Content -Path $reportPath -Encoding UTF8
    Write-Ok "Reporte EKS: $reportPath"
    return $report
}

function New-K8sSecretsFile {
    param(
        [string]$RepoRoot,
        [string]$EventHubsConn,
        [string]$PostgresPassword,
        [string]$PostgresUser
    )
    $outPath = Join-Path $RepoRoot 'k8s\secrets.yaml'
    $ehEscaped = $EventHubsConn -replace '"', '\"'
    @"
# GENERADO por Deploy-AwsShopDemo.ps1 - NO COMMITEAR
# Aplicar: kubectl apply -f k8s/secrets.yaml
# Guía: docs/despliegue/eks/IMPLEMENTACION-DESPLIEGUE-EKS.md

apiVersion: v1
kind: Secret
metadata:
  name: shopdemo-secrets
  namespace: shopdemo
type: Opaque
stringData:
  POSTGRES_USER: $PostgresUser
  POSTGRES_PASSWORD: $PostgresPassword
  EVENT_HUBS_CONNECTION_STRING: "$ehEscaped"
  PG_CATALOG_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoCatalog;Username=$PostgresUser;Password=$PostgresPassword"
  PG_ORDERS_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoOrders;Username=$PostgresUser;Password=$PostgresPassword"
  PG_INVENTORY_CONN: "Host=shopdemo-postgres;Port=5432;Database=ShopDemoInventory;Username=$PostgresUser;Password=$PostgresPassword"
  AZURITE_CHECKPOINT_CONN: "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://shopdemo-azurite:10000/devstoreaccount1;"
"@ | Set-Content -Path $outPath -Encoding UTF8
    Write-Ok "Generado $outPath (checkpoints Azurite in-cluster para EKS)"
}

function Ensure-EcsExecutionRole {
    param([string]$AccountId, [string]$Region, [string]$Prefix)
    $roleName = "$Prefix-ecs-execution"
    $null = Invoke-AwsCli 'Comprobar rol ECS execution' @(
        'iam', 'get-role', '--role-name', $roleName
    ) -AllowFailure
    if ($LASTEXITCODE -ne 0) {
        $trust = @{
            Version   = '2012-10-17'
            Statement = @(@{
                    Effect    = 'Allow'
                    Principal = @{ Service = 'ecs-tasks.amazonaws.com' }
                    Action    = 'sts:AssumeRole'
                })
        } | ConvertTo-Json -Depth 5 -Compress
        $trustFile = Join-Path $env:TEMP 'shopdemo-ecs-trust.json'
        Write-JsonFileNoBom -Path $trustFile -Json $trust
        Invoke-AwsCli 'Crear rol ECS execution' @(
            'iam', 'create-role', '--role-name', $roleName,
            '--assume-role-policy-document', (ConvertTo-AwsFileUri -Path $trustFile)
        ) | Out-Null
        Invoke-AwsCli 'Adjuntar política ECS execution' @(
            'iam', 'attach-role-policy', '--role-name', $roleName,
            '--policy-arn', 'arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy'
        ) | Out-Null
        $ssmPolicy = @{
            Version   = '2012-10-17'
            Statement = @(@{
                    Effect   = 'Allow'
                    Action   = @('ssm:GetParameters', 'ssm:GetParameter')
                    Resource = "arn:aws:ssm:${Region}:${AccountId}:parameter/$Prefix/*"
                })
        } | ConvertTo-Json -Depth 5 -Compress
        $polFile = Join-Path $env:TEMP 'shopdemo-ssm-policy.json'
        Write-JsonFileNoBom -Path $polFile -Json $ssmPolicy
        Invoke-AwsCli 'Política SSM para tasks' @(
            'iam', 'put-role-policy', '--role-name', $roleName,
            '--policy-name', 'ShopDemoSsmRead',
            '--policy-document', (ConvertTo-AwsFileUri -Path $polFile)
        ) | Out-Null
        Start-Sleep -Seconds 10
    }
    return "arn:aws:iam::${AccountId}:role/${roleName}"
}

function Register-EcsTaskDefinition {
    param(
        [string]$Family,
        [string]$ExecutionRoleArn,
        [string]$ImageUri,
        [string]$ContainerName,
        [int]$ContainerPort = 8080,
        [string]$Cpu = '512',
        [string]$Memory = '1024',
        [string]$LogGroup,
        [string]$Region,
        [array]$Environment = @(),
        [array]$Secrets = @(),
        [array]$Command = $null
    )
    $null = Invoke-AwsCli "Log group $LogGroup" @(
        'logs', 'create-log-group', '--log-group-name', $LogGroup
    ) -AllowFailure

    $container = @{
        name      = $ContainerName
        image     = $ImageUri
        essential = $true
        portMappings = @(@{ containerPort = $ContainerPort; protocol = 'tcp' })
        environment   = $Environment
        secrets       = $Secrets
        logConfiguration = @{
            logDriver = 'awslogs'
            options   = @{
                'awslogs-group'         = $LogGroup
                'awslogs-region'        = $Region
                'awslogs-stream-prefix' = 'ecs'
            }
        }
    }
    if ($Command) { $container.command = $Command }

    $taskDef = @{
        family                  = $Family
        networkMode             = 'awsvpc'
        requiresCompatibilities = @('FARGATE')
        cpu                     = $Cpu
        memory                  = $Memory
        executionRoleArn        = $ExecutionRoleArn
        containerDefinitions    = @($container)
    } | ConvertTo-Json -Depth 10 -Compress

    $taskFile = Join-Path $env:TEMP "shopdemo-task-$Family.json"
    Write-JsonFileNoBom -Path $taskFile -Json $taskDef
    Invoke-AwsCli "Registrar task definition $Family" @(
        'ecs', 'register-task-definition', '--cli-input-json', (ConvertTo-AwsFileUri -Path $taskFile)
    ) | Out-Null
}

function New-EcsServiceSimple {
    param(
        [string]$Cluster,
        [string]$ServiceName,
        [string]$TaskFamily,
        [string[]]$Subnets,
        [string]$SecurityGroup,
        [int]$DesiredCount = 1
    )
    $null = Invoke-AwsCli "Comprobar servicio $ServiceName" @(
        'ecs', 'describe-services', '--cluster', $Cluster, '--services', $ServiceName
    ) -AllowFailure
    $exists = $false
    if ($LASTEXITCODE -eq 0) {
        $svc = (& aws @script:AwsGlobalArgs ecs describe-services --cluster $Cluster --services $ServiceName --output json | ConvertFrom-Json)
        if ($svc.services.Count -gt 0 -and $svc.services[0].status -ne 'INACTIVE') { $exists = $true }
    }
    if ($exists) {
        Write-Warn "Servicio ECS '$ServiceName' ya existe"
        return
    }
    $net = "awsvpcConfiguration={subnets=[$($Subnets -join ',')],securityGroups=[$SecurityGroup],assignPublicIp=ENABLED}"
    Invoke-AwsCli "Crear servicio $ServiceName" @(
        'ecs', 'create-service',
        '--cluster', $Cluster,
        '--service-name', $ServiceName,
        '--task-definition', $TaskFamily,
        '--desired-count', "$DesiredCount",
        '--launch-type', 'FARGATE',
        '--network-configuration', $net
    ) | Out-Null
}

function Get-EcsServiceTaskPrivateIp {
    param([string]$Cluster, [string]$ServiceName)
    for ($i = 0; $i -lt 24; $i++) {
        $tasks = Invoke-AwsCli 'Listar tasks' @(
            'ecs', 'list-tasks', '--cluster', $Cluster, '--service-name', $ServiceName, '--desired-status', 'RUNNING', '--query', 'taskArns[0]', '--output', 'text'
        ).Trim()
        if ($tasks -and $tasks -ne 'None') {
            $ip = Invoke-AwsCli 'IP privada task' @(
                'ecs', 'describe-tasks', '--cluster', $Cluster, '--tasks', $tasks,
                '--query', "tasks[0].attachments[0].details[?name=='privateIPv4Address'].value | [0]",
                '--output', 'text'
            ).Trim()
            if ($ip -and $ip -ne 'None') { return $ip }
        }
        Start-Sleep -Seconds 10
    }
    throw "No se obtuvo IP privada del servicio $ServiceName"
}

function Wait-CloudMapOperation {
    param([string]$OperationId)
    for ($i = 0; $i -lt 36; $i++) {
        $op = Invoke-AwsCli 'Estado Cloud Map' @(
            'servicediscovery', 'get-operation', '--operation-id', $OperationId, '--output', 'json'
        ) | ConvertFrom-Json
        $status = $op.Operation.Status
        if ($status -eq 'SUCCESS') {
            $targets = $op.Operation.Targets
            if ($null -ne $targets -and $targets.PSObject.Properties['NAMESPACE']) {
                return $targets.NAMESPACE
            }
            if ($op.Operation.PSObject.Properties['TargetId']) {
                return $op.Operation.TargetId
            }
            throw "Cloud Map SUCCESS sin namespace id en operation $OperationId"
        }
        if ($status -eq 'FAIL') { throw "Cloud Map operation failed: $OperationId" }
        Start-Sleep -Seconds 5
    }
    throw "Timeout esperando Cloud Map operation $OperationId"
}

function New-EcsAlbService {
    param(
        [string]$Cluster,
        [string]$ServiceName,
        [string]$TaskFamily,
        [string]$ContainerName,
        [string]$AlbName,
        [string]$TargetGroupName,
        [string[]]$Subnets,
        [string]$VpcId,
        [string]$SgAlb,
        [string]$SgApps
    )
    $null = Invoke-AwsCli "Comprobar ALB $AlbName" @(
        'elbv2', 'describe-load-balancers', '--names', $AlbName, '--query', 'LoadBalancers[0].LoadBalancerArn', '--output', 'text'
    ) -AllowFailure

    if ($LASTEXITCODE -ne 0) {
        $tgArn = Invoke-AwsCli 'Crear target group' @(
            'elbv2', 'create-target-group',
            '--name', $TargetGroupName,
            '--protocol', 'HTTP',
            '--port', '8080',
            '--vpc-id', $VpcId,
            '--target-type', 'ip',
            '--health-check-path', '/health',
            '--health-check-interval-seconds', '30',
            '--query', 'TargetGroups[0].TargetGroupArn',
            '--output', 'text'
        ).Trim()

        $albArn = Invoke-AwsCli 'Crear ALB' @(
            'elbv2', 'create-load-balancer',
            '--name', $AlbName,
            '--type', 'application',
            '--scheme', 'internet-facing',
            '--subnets', $Subnets[0], $Subnets[1],
            '--security-groups', $SgAlb,
            '--query', 'LoadBalancers[0].LoadBalancerArn',
            '--output', 'text'
        ).Trim()

        Invoke-AwsCli 'Listener HTTP 80' @(
            'elbv2', 'create-listener',
            '--load-balancer-arn', $albArn,
            '--protocol', 'HTTP',
            '--port', '80',
            '--default-actions', "Type=forward,TargetGroupArn=$tgArn"
        ) | Out-Null
    }
    else {
        $albArn = Invoke-AwsCli 'ARN ALB existente' @(
            'elbv2', 'describe-load-balancers', '--names', $AlbName,
            '--query', 'LoadBalancers[0].LoadBalancerArn', '--output', 'text'
        ).Trim()
        $tgArn = Invoke-AwsCli 'ARN TG' @(
            'elbv2', 'describe-target-groups', '--names', $TargetGroupName,
            '--query', 'TargetGroups[0].TargetGroupArn', '--output', 'text'
        ).Trim()
    }

    $exists = Test-EcsServiceExists -Cluster $Cluster -ServiceName $ServiceName
    if (-not $exists) {
        $net = "awsvpcConfiguration={subnets=[$($Subnets -join ',')],securityGroups=[$SgApps],assignPublicIp=ENABLED}"
        $lb = "targetGroupArn=$tgArn,containerName=$ContainerName,containerPort=8080"
        Invoke-AwsCli "Crear servicio ECS $ServiceName" @(
            'ecs', 'create-service',
            '--cluster', $Cluster,
            '--service-name', $ServiceName,
            '--task-definition', $TaskFamily,
            '--desired-count', '1',
            '--launch-type', 'FARGATE',
            '--network-configuration', $net,
            '--load-balancers', $lb
        ) | Out-Null
    }

    $dns = Invoke-AwsCli 'DNS ALB' @(
        'elbv2', 'describe-load-balancers', '--load-balancer-arns', $albArn,
        '--query', 'LoadBalancers[0].DNSName', '--output', 'text'
    ).Trim()
    return @{ AlbArn = $albArn; TgArn = $tgArn; Dns = $dns }
}

function New-PostgresDatabases {
    param([string]$PostgresHost, [string]$User, [string]$Password)
    $psql = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psql) {
        Write-Warn "psql no disponible - crea las BD manualmente contra $PostgresHost"
        return
    }
    $env:PGPASSWORD = $Password
    & psql -h $PostgresHost -U $User -d postgres -c 'CREATE DATABASE "ShopDemoCatalog";' 2>$null
    & psql -h $PostgresHost -U $User -d postgres -c 'CREATE DATABASE "ShopDemoOrders";' 2>$null
    & psql -h $PostgresHost -U $User -d postgres -c 'CREATE DATABASE "ShopDemoInventory";' 2>$null
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Write-Ok 'Bases de datos PostgreSQL creadas (si no existían)'
}

# -----------------------------------------------------------------------------
# Inicio
# -----------------------------------------------------------------------------
Write-Host "`nShopDemo - Provisionamiento AWS (modo: $Mode)" -ForegroundColor White
Write-Host "Ref: docs/despliegue/aws/IMPLEMENTACION-DESPLIEGUE-AWS.md" -ForegroundColor DarkGray

$cfg = Import-EnvFile -Path $EnvFile
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$prefix = $cfg.LAB_PREFIX
$region = $cfg.AWS_REGION
$deployEcs = $Mode -in 'ECS', 'All'
$deployEks = $Mode -in 'EKS', 'All'

if ($cfg.AWS_PROFILE) {
    $script:AwsGlobalArgs += @('--profile', $cfg.AWS_PROFILE)
}
$script:AwsGlobalArgs += @('--region', $region)

# -----------------------------------------------------------------------------
# Paso 0 - Prerrequisitos
# Ref: IMPLEMENTACION-DESPLIEGUE-AWS.md §3
# -----------------------------------------------------------------------------
Write-Step 'Paso 0 - Prerrequisitos (AWS CLI, credenciales)'
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    throw 'Instala AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html'
}
$identity = Invoke-AwsCli 'Identidad AWS' @('sts', 'get-caller-identity', '--output', 'json') | ConvertFrom-Json
$accountId = $identity.Account
Write-Ok "Cuenta AWS: $accountId ($($identity.Arn))"

$ehConn = $cfg.EVENT_HUBS_CONNECTION_STRING
$ecrUri = "$accountId.dkr.ecr.$region.amazonaws.com"
$state = @{
    region    = $region
    accountId = $accountId
    labPrefix = $prefix
    mode      = $Mode
    ecrUri    = $ecrUri
}

# -----------------------------------------------------------------------------
# Paso 1 - Repositorios ECR (ECS y EKS)
# Ref: IMPLEMENTACION-DESPLIEGUE-AWS.md §6
# -----------------------------------------------------------------------------
Write-Step 'Paso 1 - Repositorios Amazon ECR'
$repos = @(
    'shopdemo-catalog', 'shopdemo-orders', 'shopdemo-inventory',
    'shopdemo-analytics', 'shopdemo-mcp'
)
foreach ($repo in $repos) {
    $null = Invoke-AwsCli "ECR $repo" @(
        'ecr', 'create-repository', '--repository-name', $repo
    ) -AllowFailure
}
$missing = @()
foreach ($repo in $repos) {
    $imgCheck = Invoke-AwsCli "Imágenes $repo" @(
        'ecr', 'list-images', '--repository-name', $repo, '--query', 'imageIds[0].imageTag', '--output', 'text'
    ) -AllowFailure
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($imgCheck) -or $imgCheck.Trim() -eq 'None') {
        $missing += $repo
    }
}
if ($missing.Count -gt 0) {
    Write-Warn "Sin imágenes en ECR: $($missing -join ', ')"
    Write-Info 'Publica con .github/workflows/deploy-aws.yml o build manual (doc §7)'
}
Write-Ok "ECR registry: $ecrUri"

# -----------------------------------------------------------------------------
# Paso 2 - ECS: VPC, Security Groups, Cluster
# Ref: IMPLEMENTACION-DESPLIEGUE-AWS.md §4-9
# -----------------------------------------------------------------------------
if ($deployEcs) {
    Write-Step 'Paso 2 - VPC y subnets públicas (lab sin NAT)'
    $subnetA = $null
    $subnetB = $null
    $vpcId = (Invoke-AwsCli 'Buscar VPC existente' @(
        'ec2', 'describe-vpcs',
        '--filters', "Name=tag:Name,Values=$prefix-vpc",
        '--query', 'Vpcs[0].VpcId', '--output', 'text'
    ) -AllowFailure).Trim()

    if ([string]::IsNullOrWhiteSpace($vpcId) -or $vpcId -eq 'None') {
        $vpcId = Invoke-AwsCli 'Crear VPC' @(
            'ec2', 'create-vpc', '--cidr-block', $cfg.VPC_CIDR,
            '--query', 'Vpc.VpcId', '--output', 'text'
        ).Trim()
        Invoke-AwsCli 'Tag VPC' @(
            'ec2', 'create-tags', '--resources', $vpcId,
            '--tags', "Key=Name,Value=$prefix-vpc", "Key=Project,Value=ShopDemo"
        ) | Out-Null
        Invoke-AwsCli 'Habilitar DNS' @('ec2', 'modify-vpc-attribute', '--vpc-id', $vpcId, '--enable-dns-hostnames') | Out-Null

        $igw = Invoke-AwsCli 'Internet Gateway' @(
            'ec2', 'create-internet-gateway', '--query', 'InternetGateway.InternetGatewayId', '--output', 'text'
        ).Trim()
        Invoke-AwsCli 'Adjuntar IGW' @(
            'ec2', 'attach-internet-gateway', '--internet-gateway-id', $igw, '--vpc-id', $vpcId
        ) | Out-Null

        $azA = "${region}a"
        $azB = "${region}b"
        $subnetA = Invoke-AwsCli 'Subnet A' @(
            'ec2', 'create-subnet', '--vpc-id', $vpcId, '--cidr-block', '10.0.1.0/24',
            '--availability-zone', $azA, '--query', 'Subnet.SubnetId', '--output', 'text'
        ).Trim()
        $subnetB = Invoke-AwsCli 'Subnet B' @(
            'ec2', 'create-subnet', '--vpc-id', $vpcId, '--cidr-block', '10.0.2.0/24',
            '--availability-zone', $azB, '--query', 'Subnet.SubnetId', '--output', 'text'
        ).Trim()
        Invoke-AwsCli 'Subnets públicas' @(
            'ec2', 'modify-subnet-attribute', '--subnet-id', $subnetA, '--map-public-ip-on-launch'
        ) | Out-Null
        Invoke-AwsCli 'Subnets públicas B' @(
            'ec2', 'modify-subnet-attribute', '--subnet-id', $subnetB, '--map-public-ip-on-launch'
        ) | Out-Null

        $rt = Invoke-AwsCli 'Route table' @(
            'ec2', 'create-route-table', '--vpc-id', $vpcId,
            '--query', 'RouteTable.RouteTableId', '--output', 'text'
        ).Trim()
        Invoke-AwsCli 'Ruta default' @(
            'ec2', 'create-route', '--route-table-id', $rt,
            '--destination-cidr-block', '0.0.0.0/0', '--gateway-id', $igw
        ) | Out-Null
        Invoke-AwsCli 'Asociar subnet A' @(
            'ec2', 'associate-route-table', '--subnet-id', $subnetA, '--route-table-id', $rt
        ) | Out-Null
        Invoke-AwsCli 'Asociar subnet B' @(
            'ec2', 'associate-route-table', '--subnet-id', $subnetB, '--route-table-id', $rt
        ) | Out-Null
        Write-Ok "VPC nueva: $vpcId"
    }
    else {
        Write-Warn "VPC existente: $vpcId"
        $subnetA = (Invoke-AwsCli 'Subnet A' @(
            'ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$vpcId",
            '--query', 'Subnets[0].SubnetId', '--output', 'text'
        )).Trim()
        $subnetB = (Invoke-AwsCli 'Subnet B' @(
            'ec2', 'describe-subnets', '--filters', "Name=vpc-id,Values=$vpcId",
            '--query', 'Subnets[1].SubnetId', '--output', 'text'
        )).Trim()
    }

    Write-Step 'Paso 3 - Security Groups'
    function Get-OrCreateSg {
        param([string]$Name, [string]$Desc)
        $sg = Invoke-AwsCli "SG $Name" @(
            'ec2', 'describe-security-groups',
            '--filters', "Name=group-name,Values=$Name", "Name=vpc-id,Values=$vpcId",
            '--query', 'SecurityGroups[0].GroupId', '--output', 'text'
        ) -AllowFailure
        if ($LASTEXITCODE -eq 0 -and $sg.Trim() -ne 'None') { return $sg.Trim() }
        return (Invoke-AwsCli "Crear $Name" @(
            'ec2', 'create-security-group', '--group-name', $Name,
            '--description', $Desc, '--vpc-id', $vpcId,
            '--query', 'GroupId', '--output', 'text'
        ).Trim())
    }
    $sgAlb = Get-OrCreateSg "$prefix-alb" 'ALB ShopDemo'
    $sgApps = Get-OrCreateSg "$prefix-apps" 'ECS apps ShopDemo'
    $sgData = Get-OrCreateSg "$prefix-data" 'Postgres Azurite ShopDemo'

    $null = Invoke-AwsCli 'Regla ALB HTTP' @(
        'ec2', 'authorize-security-group-ingress', '--group-id', $sgAlb,
        '--protocol', 'tcp', '--port', '80', '--cidr', '0.0.0.0/0'
    ) -AllowFailure
    $null = Invoke-AwsCli 'Apps desde ALB' @(
        'ec2', 'authorize-security-group-ingress', '--group-id', $sgApps,
        '--protocol', 'tcp', '--port', '8080', '--source-group', $sgAlb
    ) -AllowFailure
    $null = Invoke-AwsCli 'Apps entre sí' @(
        'ec2', 'authorize-security-group-ingress', '--group-id', $sgApps,
        '--protocol', 'tcp', '--port', '8080', '--source-group', $sgApps
    ) -AllowFailure
    $null = Invoke-AwsCli 'Data Postgres' @(
        'ec2', 'authorize-security-group-ingress', '--group-id', $sgData,
        '--protocol', 'tcp', '--port', '5432', '--source-group', $sgApps
    ) -AllowFailure
    $null = Invoke-AwsCli 'Data Azurite' @(
        'ec2', 'authorize-security-group-ingress', '--group-id', $sgData,
        '--protocol', 'tcp', '--port', '10000', '--source-group', $sgApps
    ) -AllowFailure

    Write-Step 'Paso 4 - ECS Cluster y rol de ejecución'
    $cluster = $cfg.ECS_CLUSTER_NAME
    $null = Invoke-AwsCli 'Crear cluster ECS' @(
        'ecs', 'create-cluster', '--cluster-name', $cluster,
        '--capacity-providers', 'FARGATE', 'FARGATE_SPOT',
        '--default-capacity-provider-strategy', 'capacityProvider=FARGATE,weight=1'
    ) -AllowFailure
    $execRoleArn = Ensure-EcsExecutionRole -AccountId $accountId -Region $region -Prefix $prefix

    $state.vpcId = $vpcId
    $state.subnetA = $subnetA
    $state.subnetB = $subnetB
    $state.sgAlb = $sgAlb
    $state.sgApps = $sgApps
    $state.sgData = $sgData
    $state.ecsCluster = $cluster
    $state.executionRoleArn = $execRoleArn

    # SSM Parameter Store - placeholders
    Write-Step 'Paso 5 - SSM Parameter Store (secretos)'
    Invoke-AwsCli 'SSM eh-connection' @(
        'ssm', 'put-parameter', '--name', "/$prefix/eh-connection",
        '--value', $ehConn, '--type', 'SecureString', '--overwrite'
    ) | Out-Null

    # PostgreSQL + Azurite en ECS
    Write-Step 'Paso 6 - PostgreSQL y Azurite en Fargate'
    $tag = $cfg.IMAGE_TAG
    Register-EcsTaskDefinition -Family "$prefix-postgres" -ExecutionRoleArn $execRoleArn `
        -ImageUri 'postgres:16-alpine' -ContainerName 'postgres' -ContainerPort 5432 `
        -Cpu '512' -Memory '1024' -LogGroup "/ecs/$prefix-postgres" -Region $region `
        -Environment @(
            @{ name = 'POSTGRES_USER'; value = $cfg.POSTGRES_USER }
            @{ name = 'POSTGRES_PASSWORD'; value = $cfg.POSTGRES_PASSWORD }
        )

    Register-EcsTaskDefinition -Family "$prefix-azurite" -ExecutionRoleArn $execRoleArn `
        -ImageUri 'mcr.microsoft.com/azure-storage/azurite' -ContainerName 'azurite' -ContainerPort 10000 `
        -Cpu '512' -Memory '1024' -LogGroup "/ecs/$prefix-azurite" -Region $region `
        -Command @('azurite-blob', '--blobHost', '0.0.0.0', '--blobPort', '10000')

    New-EcsServiceSimple -Cluster $cluster -ServiceName "$prefix-postgres" `
        -TaskFamily "$prefix-postgres" -Subnets @($subnetA, $subnetB) -SecurityGroup $sgData
    New-EcsServiceSimple -Cluster $cluster -ServiceName "$prefix-azurite" `
        -TaskFamily "$prefix-azurite" -Subnets @($subnetA, $subnetB) -SecurityGroup $sgData

    Write-Info 'Esperando IPs de PostgreSQL y Azurite...'
    $pgIp = Get-EcsServiceTaskPrivateIp -Cluster $cluster -ServiceName "$prefix-postgres"
    $azIp = Get-EcsServiceTaskPrivateIp -Cluster $cluster -ServiceName "$prefix-azurite"
    Write-Ok "PostgreSQL: $pgIp | Azurite: $azIp"

    $pgCatalog = "Host=$pgIp;Port=5432;Database=ShopDemoCatalog;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD)"
    $pgOrders = "Host=$pgIp;Port=5432;Database=ShopDemoOrders;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD)"
    $pgInventory = "Host=$pgIp;Port=5432;Database=ShopDemoInventory;Username=$($cfg.POSTGRES_USER);Password=$($cfg.POSTGRES_PASSWORD)"
    $azConn = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://${azIp}:10000/devstoreaccount1;"

    foreach ($pair in @(
            @{ N = "/$prefix/pg-catalog"; V = $pgCatalog }
            @{ N = "/$prefix/pg-orders"; V = $pgOrders }
            @{ N = "/$prefix/pg-inventory"; V = $pgInventory }
            @{ N = "/$prefix/azurite-checkpoint"; V = $azConn }
        )) {
        Invoke-AwsCli "SSM $($pair.N)" @(
            'ssm', 'put-parameter', '--name', $pair.N,
            '--value', $pair.V, '--type', 'SecureString', '--overwrite'
        ) | Out-Null
    }
    New-PostgresDatabases -PostgresHost $pgIp -User $cfg.POSTGRES_USER -Password $cfg.POSTGRES_PASSWORD

    # Cloud Map para Inventory
    Write-Step 'Paso 7 - AWS Cloud Map (DNS privado Inventory)'
    $nsId = $null
    $null = Invoke-AwsCli 'Namespace existente' @(
        'servicediscovery', 'list-namespaces', '--filters', "Name=NAME,Values=$($cfg.CLOUDMAP_NAMESPACE)", '--output', 'json'
    ) -AllowFailure
    if ($LASTEXITCODE -eq 0) {
        $listed = (& aws @script:AwsGlobalArgs servicediscovery list-namespaces --filters "Name=NAME,Values=$($cfg.CLOUDMAP_NAMESPACE)" --output json | ConvertFrom-Json)
        if ($listed.Namespaces.Count -gt 0) { $nsId = $listed.Namespaces[0].Id }
    }
    if (-not $nsId) {
        $opId = Invoke-AwsCli 'Crear namespace' @(
            'servicediscovery', 'create-private-dns-namespace',
            '--name', $cfg.CLOUDMAP_NAMESPACE, '--vpc', $vpcId,
            '--description', 'ShopDemo service discovery',
            '--query', 'OperationId', '--output', 'text'
        ).Trim()
        $nsId = Wait-CloudMapOperation -OperationId $opId
    }
    $invSdArn = Invoke-AwsCli 'Servicio discovery inventory' @(
        'servicediscovery', 'create-service',
        '--name', 'inventory',
        '--namespace-id', $nsId,
        '--dns-config', "NamespaceId=$nsId,DnsRecords=[{Type=A,TTL=10}]",
        '--health-check-custom-config', 'FailureThreshold=1',
        '--query', 'Service.Arn', '--output', 'text'
    ) -AllowFailure
    if ($LASTEXITCODE -ne 0) {
        $invSdArn = Invoke-AwsCli 'ARN inventory SD' @(
            'servicediscovery', 'list-services', '--filters', "Name=NAMESPACE_ID,Values=$nsId",
            '--query', "Services[?Name=='inventory'].Arn | [0]", '--output', 'text'
        ).Trim()
    }
    else { $invSdArn = $invSdArn.Trim() }

    $ssm = "/$prefix"
    function SsmRef([string]$paramSuffix, [string]$envName) {
        return @{
            name      = $envName
            valueFrom = (Get-SsmParameterArn -AccountId $accountId -Region $region -Name "$ssm/$paramSuffix")
        }
    }
    $ehEnv = @(
        @{ name = 'ASPNETCORE_ENVIRONMENT'; value = 'Production' }
        @{ name = 'EventHubs__Enabled'; value = 'true' }
        @{ name = 'EventHubs__EventHubName'; value = $cfg.EVENT_HUB_NAME }
    )

    Write-Step 'Paso 8 - Task definitions APIs (Catalog, Inventory, Orders, Analytics, MCP)'
    $catalogSecrets = @(
        (SsmRef 'pg-catalog' 'ConnectionStrings__DefaultConnection')
        (SsmRef 'eh-connection' 'EventHubs__ConnectionString')
    )
    Register-EcsTaskDefinition -Family "$prefix-catalog" -ExecutionRoleArn $execRoleArn `
        -ImageUri "$ecrUri/shopdemo-catalog:$tag" -ContainerName 'catalog-api' `
        -LogGroup "/ecs/$prefix-catalog" -Region $region -Environment $ehEnv -Secrets $catalogSecrets

    $inventorySecrets = @(
        (SsmRef 'pg-inventory' 'ConnectionStrings__DefaultConnection')
        (SsmRef 'eh-connection' 'EventHubs__ConnectionString')
        (SsmRef 'azurite-checkpoint' 'EventHubs__CheckpointStorageConnectionString')
    )
    $inventoryEnv = $ehEnv + @(
        @{ name = 'EventHubs__ConsumerGroup'; value = 'inventory-service' }
        @{ name = 'EventHubs__CheckpointContainerName'; value = 'inventory-checkpoints' }
    )
    Register-EcsTaskDefinition -Family "$prefix-inventory" -ExecutionRoleArn $execRoleArn `
        -ImageUri "$ecrUri/shopdemo-inventory:$tag" -ContainerName 'inventory-api' `
        -LogGroup "/ecs/$prefix-inventory" -Region $region -Environment $inventoryEnv -Secrets $inventorySecrets

    $analyticsSecrets = @(
        (SsmRef 'eh-connection' 'EventHubs__ConnectionString')
        (SsmRef 'azurite-checkpoint' 'EventHubs__CheckpointStorageConnectionString')
    )
    $analyticsEnv = $ehEnv + @(
        @{ name = 'EventHubs__ConsumerGroup'; value = 'analytics-service' }
        @{ name = 'EventHubs__CheckpointContainerName'; value = 'analytics-checkpoints' }
    )
    Register-EcsTaskDefinition -Family "$prefix-analytics" -ExecutionRoleArn $execRoleArn `
        -ImageUri "$ecrUri/shopdemo-analytics:$tag" -ContainerName 'analytics-api' `
        -LogGroup "/ecs/$prefix-analytics" -Region $region -Environment $analyticsEnv -Secrets $analyticsSecrets

    Write-Step 'Paso 9 - ECS Services + ALB (APIs públicas) y Cloud Map (Inventory)'
    $albCatalog = New-EcsAlbService -Cluster $cluster -ServiceName "$prefix-catalog" `
        -TaskFamily "$prefix-catalog" -ContainerName 'catalog-api' `
        -AlbName "$prefix-catalog-alb" -TargetGroupName "$prefix-catalog-tg" `
        -Subnets @($subnetA, $subnetB) -VpcId $vpcId -SgAlb $sgAlb -SgApps $sgApps

    # Inventory con service discovery (sin ALB)
    if (-not (Test-EcsServiceExists -Cluster $cluster -ServiceName "$prefix-inventory")) {
        $net = "awsvpcConfiguration={subnets=[$subnetA],securityGroups=[$sgApps],assignPublicIp=ENABLED}"
        Invoke-AwsCli 'Crear inventory + Cloud Map' @(
            'ecs', 'create-service',
            '--cluster', $cluster,
            '--service-name', "$prefix-inventory",
            '--task-definition', "$prefix-inventory",
            '--desired-count', '1',
            '--launch-type', 'FARGATE',
            '--network-configuration', $net,
            '--service-registries', "registryArn=$invSdArn,containerName=inventory-api"
        ) | Out-Null
    }

    $inventoryUrl = "http://inventory.$($cfg.CLOUDMAP_NAMESPACE):8080"
    $ordersSecrets = @(
        (SsmRef 'pg-orders' 'ConnectionStrings__DefaultConnection')
        (SsmRef 'eh-connection' 'EventHubs__ConnectionString')
    )
    $ordersEnv = $ehEnv + @(@{ name = 'InventoryApi__BaseUrl'; value = $inventoryUrl })
    Register-EcsTaskDefinition -Family "$prefix-orders" -ExecutionRoleArn $execRoleArn `
        -ImageUri "$ecrUri/shopdemo-orders:$tag" -ContainerName 'orders-api' `
        -LogGroup "/ecs/$prefix-orders" -Region $region -Environment $ordersEnv -Secrets $ordersSecrets

    $albOrders = New-EcsAlbService -Cluster $cluster -ServiceName "$prefix-orders" `
        -TaskFamily "$prefix-orders" -ContainerName 'orders-api' `
        -AlbName "$prefix-orders-alb" -TargetGroupName "$prefix-orders-tg" `
        -Subnets @($subnetA, $subnetB) -VpcId $vpcId -SgAlb $sgAlb -SgApps $sgApps

    $albAnalytics = New-EcsAlbService -Cluster $cluster -ServiceName "$prefix-analytics" `
        -TaskFamily "$prefix-analytics" -ContainerName 'analytics-api' `
        -AlbName "$prefix-analytics-alb" -TargetGroupName "$prefix-analytics-tg" `
        -Subnets @($subnetA, $subnetB) -VpcId $vpcId -SgAlb $sgAlb -SgApps $sgApps

    # MCP - ref: IMPLEMENTACION-DESPLIEGUE-MCP-AWS.md
    $mcpEnv = @(
        @{ name = 'ASPNETCORE_ENVIRONMENT'; value = 'Production' }
        @{ name = 'ShopDemo__CatalogApiBaseUrl'; value = "http://$($albCatalog.Dns)" }
        @{ name = 'ShopDemo__InventoryApiBaseUrl'; value = $inventoryUrl }
        @{ name = 'ShopDemo__AnalyticsApiBaseUrl'; value = "http://$($albAnalytics.Dns)" }
    )
    Register-EcsTaskDefinition -Family "$prefix-mcp" -ExecutionRoleArn $execRoleArn `
        -ImageUri "$ecrUri/shopdemo-mcp:$tag" -ContainerName 'mcp-api' `
        -LogGroup "/ecs/$prefix-mcp" -Region $region -Environment $mcpEnv

    $albMcp = New-EcsAlbService -Cluster $cluster -ServiceName "$prefix-mcp" `
        -TaskFamily "$prefix-mcp" -ContainerName 'mcp-api' `
        -AlbName "$prefix-mcp-alb" -TargetGroupName "$prefix-mcp-tg" `
        -Subnets @($subnetA, $subnetB) -VpcId $vpcId -SgAlb $sgAlb -SgApps $sgApps

    $state.albDns = @{
        catalog   = $albCatalog.Dns
        orders    = $albOrders.Dns
        analytics = $albAnalytics.Dns
        mcp       = $albMcp.Dns
    }
    $state.inventoryUrl = $inventoryUrl
    Write-Ok 'Servicios ECS desplegados'
}

# -----------------------------------------------------------------------------
# Paso EKS - cluster + secrets.yaml
# Ref: IMPLEMENTACION-DESPLIEGUE-EKS.md
# -----------------------------------------------------------------------------
if ($deployEks) {
    Write-Step "Paso EKS - Cluster $($cfg.EKS_CLUSTER_NAME)"
    Ensure-EksToolchain

    if (-not (Get-Command eksctl -ErrorAction SilentlyContinue)) {
        Write-Warn 'eksctl no instalado - https://eksctl.io/installation/'
        Write-Info 'Coloca eksctl.exe en PATH o en %LOCALAPPDATA%\eksctl\'
    }

    $clusterExists = Test-EksClusterExists -ClusterName $cfg.EKS_CLUSTER_NAME -Region $region
    if (-not $clusterExists) {
        if (-not (Get-Command eksctl -ErrorAction SilentlyContinue)) {
            throw 'No se puede crear EKS sin eksctl. Instala eksctl o adjunta iam-policy-shopdemo-lab-eks.json al usuario IAM.'
        }
        Write-Info 'Creando cluster EKS (eksctl, ~15 min)...'
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        & eksctl create cluster `
            --name $cfg.EKS_CLUSTER_NAME `
            --region $region `
            --nodegroup-name "$prefix-ng" `
            --node-type $cfg.EKS_NODE_TYPE `
            --nodes $cfg.EKS_NODE_COUNT `
            --managed
        $eksExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        if ($eksExit -ne 0 -and -not (Test-EksClusterExists -ClusterName $cfg.EKS_CLUSTER_NAME -Region $region)) {
            Write-Warn 'Fallo la creacion del cluster. Verifica permisos IAM: scripts/aws/iam-policy-shopdemo-lab-eks.json'
            Write-Warn "eksctl exit $eksExit - se genera reporte parcial con ECR y recursos existentes"
        }
    }

    $clusterExists = Test-EksClusterExists -ClusterName $cfg.EKS_CLUSTER_NAME -Region $region
    if ($clusterExists) {
        Write-Ok "Cluster EKS: $($cfg.EKS_CLUSTER_NAME)"

        $ngJson = Invoke-AwsCli 'Listar nodegroups' @(
            'eks', 'list-nodegroups', '--cluster-name', $cfg.EKS_CLUSTER_NAME, '--region', $region, '--output', 'json'
        ) -AllowFailure | ConvertFrom-Json
        $hasNg = ($ngJson -and $ngJson.nodegroups -and $ngJson.nodegroups.Count -gt 0)
        if (-not $hasNg -and (Get-Command eksctl -ErrorAction SilentlyContinue)) {
            Write-Info "Creando nodegroup ${prefix}-ng ($($cfg.EKS_NODE_TYPE))..."
            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            & eksctl create nodegroup `
                --cluster $cfg.EKS_CLUSTER_NAME `
                --region $region `
                --name "$prefix-ng" `
                --node-type $cfg.EKS_NODE_TYPE `
                --nodes $cfg.EKS_NODE_COUNT `
                --managed
            $ngExit = $LASTEXITCODE
            $ErrorActionPreference = $prevEap
            if ($ngExit -ne 0) {
                Write-Warn "Nodegroup fallo (exit $ngExit). Verifica tipo de instancia Free Tier en .env.aws (EKS_NODE_TYPE=t3.micro)"
            }
        }

        Invoke-AwsCli 'kubeconfig' @(
            'eks', 'update-kubeconfig', '--name', $cfg.EKS_CLUSTER_NAME, '--region', $region
        ) | Out-Null

        if (Get-Command helm -ErrorAction SilentlyContinue) {
            $prevEapIng = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            $ingressNs = kubectl get namespace ingress-nginx -o name 2>$null
            $ErrorActionPreference = $prevEapIng
            if (-not $ingressNs) {
                helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$null
                helm repo update 2>$null
                helm install ingress-nginx ingress-nginx/ingress-nginx `
                    --namespace ingress-nginx --create-namespace `
                    --set controller.admissionWebhooks.enabled=false `
                    --set controller.resources.requests.cpu=100m `
                    --set controller.resources.requests.memory=128Mi
                if ($LASTEXITCODE -eq 0) { Write-Ok 'Ingress NGINX (Helm)' }
                else { Write-Warn 'Helm ingress-nginx fallo - instala manualmente (doc EKS §6)' }
            }
            else { Write-Ok 'Ingress NGINX ya instalado' }
        }
        else {
            Write-Warn 'helm no encontrado - instala Helm para Ingress NGINX'
        }

        New-K8sSecretsFile -RepoRoot $repoRoot `
            -EventHubsConn $ehConn `
            -PostgresPassword $cfg.POSTGRES_PASSWORD `
            -PostgresUser $cfg.POSTGRES_USER

        $tag = $cfg.IMAGE_TAG
        $missingEcr = @()
        foreach ($repo in @('shopdemo-catalog', 'shopdemo-orders', 'shopdemo-inventory', 'shopdemo-analytics', 'shopdemo-mcp')) {
            $imgCheck = Invoke-AwsCli "Imagen ECR $repo" @(
                'ecr', 'list-images', '--repository-name', $repo,
                '--query', 'imageIds[0].imageTag', '--output', 'text'
            ) -AllowFailure
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($imgCheck) -or $imgCheck.Trim() -eq 'None') {
                $missingEcr += $repo
            }
        }
        if ($missingEcr.Count -gt 0) {
            Write-Warn "Imagenes faltantes en ECR: $($missingEcr -join ', ')"
        }
        else {
            Deploy-K8sWorkloads -RepoRoot $repoRoot -Registry $ecrUri -Tag $tag
        }
    }
    else {
        Write-Warn "Cluster EKS $($cfg.EKS_CLUSTER_NAME) no disponible - omitiendo kubeconfig, Helm y workloads"
        New-K8sSecretsFile -RepoRoot $repoRoot `
            -EventHubsConn $ehConn `
            -PostgresPassword $cfg.POSTGRES_PASSWORD `
            -PostgresUser $cfg.POSTGRES_USER
    }

    $state.eksCluster = $cfg.EKS_CLUSTER_NAME
    $state.eventHubName = $cfg.EVENT_HUB_NAME
    $state.mode = $Mode
    $eksReport = Get-EksReleaseReport -ClusterName $cfg.EKS_CLUSTER_NAME -Region $region `
        -AccountId $accountId -EcrUri $ecrUri -State $state
    $state.eksReportPath = (Join-Path $PSScriptRoot 'deploy-eks-report.json')
}

Save-DeployState -State $state

# -----------------------------------------------------------------------------
# Resumen
# -----------------------------------------------------------------------------
Write-Step 'Resumen'
if ($deployEcs -and $state.albDns) {
    Write-Host "  Catalog   : http://$($state.albDns.catalog)/swagger" -ForegroundColor White
    Write-Host "  Orders    : http://$($state.albDns.orders)/swagger" -ForegroundColor White
    Write-Host "  Analytics : http://$($state.albDns.analytics)/api/analytics/events" -ForegroundColor White
    Write-Host "  MCP       : http://$($state.albDns.mcp)/health" -ForegroundColor White
    Write-Host "  Inventory : $($state.inventoryUrl) (Cloud Map, interno)" -ForegroundColor White
}
if ($deployEks -and $state.eksCluster) {
    Write-Host "  EKS cluster: $($state.eksCluster) ($region)" -ForegroundColor White
    if ($state.eksReportPath -and (Test-Path $state.eksReportPath)) {
        Write-Host "  Reporte:     $($state.eksReportPath)" -ForegroundColor White
    }
}
Write-Host 'Event Hubs: Azure (cross-cloud) - connection string en k8s/secrets.yaml' -ForegroundColor DarkGray
Write-Host 'Validación: docs/GUIA-ENDPOINTS.md' -ForegroundColor DarkGray
Write-Host 'Limpieza:   .\Remove-AwsShopDemo.ps1' -ForegroundColor DarkGray
Write-Host ''
