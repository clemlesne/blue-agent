function Write-Header() {
  Write-Host "➡️ $1" -ForegroundColor Cyan
}

function Write-Warning() {
  Write-Host "⚠️ $1" -ForegroundColor Yellow
}

function Raise-Error() {
  throw "❌ $1"
}

if ($null -eq $Env:AZP_URL -or $Env:AZP_URL -eq "") {
  Raise-Error "Missing AZP_URL environment variable"
}

if ($null -eq $Env:AZP_TOKEN -or $Env:AZP_TOKEN -eq "") {
  Raise-Error "Missing AZP_TOKEN environment variable"
}
# Configure the Azure DevOps CLI to use the provided token
$env:AZURE_DEVOPS_EXT_PAT = $Env:AZP_TOKEN

if ($null -eq $Env:AZP_POOL -or $Env:AZP_POOL -eq "") {
  Raise-Error "Missing AZP_POOL environment variable"
}

# If name is not set, use the hostname
if ($null -eq $Env:AZP_AGENT_NAME -or $Env:AZP_AGENT_NAME -eq "") {
  Write-Warning "Missing AZP_AGENT_NAME environment variable, using hostname"
  $Env:AZP_AGENT_NAME = $Env:COMPUTERNAME
}

if ($null -eq $Env:AZP_WORK -or $Env:AZP_WORK -eq "") {
  Raise-Error "Missing AZP_WORK environment variable"
}

if (!(Test-Path $Env:AZP_WORK)) {
  Write-Warning "Work dir AZP_WORK ($Env:AZP_WORK) does not exist, creating it, but reliability is not guaranteed"
  New-Item -Path $Env:AZP_WORK -ItemType Directory
}

$isTemplateJob = $false
if ($Env:AZP_TEMPLATE_JOB -eq "1") {
  Write-Warning "Template job enabled, agent cannot be used for running jobs"
  $isTemplateJob = $true
  $Env:AZP_AGENT_NAME = "$Env:AZP_AGENT_NAME-template"
}

function Unregister-Now {
  Write-Header "Removing agent"

  # A job with the deployed configuration need to be kept in the server history, so a pipeline can be run and KEDA detect it from the queue
  if ($isTemplateJob) {
    Write-Host "Ignoring cleanup"
    return
  }

  # If the agent has some running jobs, the configuration removal process will fail; so, give it some time to finish the job
  while ($true) {
    try {
      # If the agent is removed successfully, exit the loop
      & config.cmd remove `
        --auth PAT `
        --token $Env:AZP_TOKEN `
        --unattended
      break
    } catch {
      Write-Host "Retrying in 15 secs"
      Start-Sleep -Seconds 15
    }
  }
}

function Unregister-If-Not-Used {
  Write-Header "Checking if agent can be removed"

  # Get pool id
  $poolId = az pipelines pool list `
    --pool-name $Env:AZP_POOL `
    --query "[0].id"
  # Get agent requests
  $agent = az pipelines agent list `
    --include-assigned-request `
    --include-last-completed-request `
    --pool-id $poolId `
    --query "[?name=='$Env:AZP_AGENT_NAME'] | [0]" | ConvertFrom-Json
  $assignedRequest = $agent.assignedRequest
  $lastCompletedRequest = $agent.lastCompletedRequest

  # If the agent has requests, abort
  if ($null -ne $assignedRequest -or $null -ne $lastCompletedRequest) {
    Write-Host "Agent has requests, cannot be removed"
    return
  }

  # Remove the agent
  Write-Host "Agent has no requests, removing it"
  Unregister-Now
}

function Add-CustomSSLCertificates {
  Write-Header "Adding custom SSL certificates"

  if (-not (Test-Path $Env:AZP_CUSTOM_CERT_PEM) -or ((Get-ChildItem $Env:AZP_CUSTOM_CERT_PEM).Count -eq 0)) {
    Write-Host "No custom SSL certificate provided"
    return
  }

  Write-Host "Searching for *.crt in $Env:AZP_CUSTOM_CERT_PEM"

  Get-ChildItem $Env:AZP_CUSTOM_CERT_PEM -Filter *.crt | ForEach-Object {
    Write-Host "Certificate $($_.Name)"

    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($_.FullName)
    Write-Host "  Valid from: " $cert.NotBefore
    Write-Host "  Valid to:   " $cert.NotAfter

    Write-Host "Updating certificates keychain"
    Import-Certificate -FilePath $_.FullName -CertStoreLocation Cert:\LocalMachine\Root
  }
}

function Configure-Agent {
  Write-Header "Configuring agent"

  Set-Location $(Split-Path -Parent $MyInvocation.MyCommand.Definition)

  & config.cmd `
    --acceptTeeEula `
    --agent $Env:AZP_AGENT_NAME `
    --auth PAT `
    --pool $Env:AZP_POOL `
    --replace `
    --token $Env:AZP_TOKEN `
    --unattended `
    --url $Env:AZP_URL `
    --work $Env:AZP_WORK
}

function Run-Agent {
  Write-Header "Running agent $Env:AZP_AGENT_NAME in pool $Env:AZP_POOL"

  # Running it with the --once flag at the end will shut down the agent after the build is executed
  try {
    if ($isTemplateJob) {
      Write-Host "Agent will be stopped after 1 min"
      # Run the agent for a minute
      Start-Job -ScriptBlock {
        Start-Sleep -Seconds 60
        & run.cmd $Args --once
      }
    } else {
      # Run the countdown
      Start-Job -ScriptBlock {
        Start-Sleep -Seconds 60
        Unregister-If-Not-Used
      }
      # Run the agent
      & run.cmd $Args --once
    }
  } finally {
    # Unregister on success, Ctrl+C, and SIGTERM
    Unregister-Now
  }

  Write-Header "Printing agent diag logs"

  Get-Content $AGENT_DIAGLOGPATH/*.log
}

Write-Header "Configuring Azure CLI"
az devops configure --defaults organization=$Env:AZP_URL

Add-CustomSSLCertificates

Configure-Agent

Run-Agent
