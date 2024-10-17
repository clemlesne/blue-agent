function Write-Header() {
  Write-Host "➡️ $1" -ForegroundColor Cyan
}

function Write-Warning() {
  Write-Host "⚠️ $1" -ForegroundColor Yellow
}

function Raise-Error() {
  throw "❌ $1"
}

$AZP_AGENT_NAME = $Env:AZP_AGENT_NAME
$AZP_CUSTOM_CERT_PEM = $Env:AZP_CUSTOM_CERT_PEM
$AZP_POOL = $Env:AZP_POOL
$AZP_TOKEN = $Env:AZP_TOKEN
$AZP_URL = $Env:AZP_URL
$AZP_WORK = $Env:AZP_WORK

if ($null -eq $AZP_URL -or $AZP_URL -eq "") {
  Raise-Error "Missing AZP_URL environment variable"
}

if ($null -eq $AZP_TOKEN -or $AZP_TOKEN -eq "") {
  Raise-Error "Missing AZP_TOKEN environment variable"
}

if ($null -eq $AZP_POOL -or $AZP_POOL -eq "") {
  Raise-Error "Missing AZP_POOL environment variable"
}

# If name is not set, use the container hostname
if ($null -eq $AZP_AGENT_NAME -or $AZP_AGENT_NAME -eq "") {
  Write-Warning "Missing AZP_AGENT_NAME environment variable"
  $AZP_AGENT_NAME = $Env:COMPUTERNAME
}

if ($null -eq $AZP_WORK -or $AZP_WORK -eq "") {
  Raise-Error "Missing AZP_WORK environment variable"
}

if (!(Test-Path $AZP_WORK)) {
  Write-Warning "Work dir AZP_WORK ($AZP_WORK) does not exist, creating it, but reliability is not guaranteed"
  New-Item -Path $AZP_WORK -ItemType Directory
}

$isTemplateJob = $false
if ($Env:AZP_TEMPLATE_JOB -eq "1") {
  Write-Warning "Template job enabled, agent cannot be used for running jobs"
  $isTemplateJob = $true
}

Write-Header "Running agent $AZP_AGENT_NAME in pool $AZP_POOL"

function Unregister {
  # A job with the deployed configuration need to be kept in the server history, so a pipeline can be run and KEDA detect it from the queue
  if ($isTemplateJob) {
    Write-Host "Ignoring cleanup, disabling agent instead"
    curl `
      --data-raw "{""id"":""$AZP_AGENT_NAME"",""enabled"":false}" `
      -H "authorization: Bearer $AZP_TOKEN" `
      -H "content-type: application/json" `
      -X PATCH `
      "$AZP_URL/_apis/distributedtask/pools/$AZP_POOL/agents/$AZP_AGENT_NAME"
    return
  }

  Write-Host "Removing agent"

  # If the agent has some running jobs, the configuration removal process will fail; so, give it some time to finish the job
  while ($true) {
    try {
      # If the agent is removed successfully, exit the loop
      & config.cmd remove `
        --auth PAT `
        --token $AZP_TOKEN `
        --unattended
      break
    } catch {
      Write-Host "Retrying in 15 secs"
      Start-Sleep -Seconds 15
    }
  }
}

Write-Header "Adding custom SSL certificates"
if ((Test-Path $AZP_CUSTOM_CERT_PEM) -and ((Get-ChildItem $AZP_CUSTOM_CERT_PEM).Count -gt 0)) {
  Write-Host "Searching for *.crt in $AZP_CUSTOM_CERT_PEM"

  Get-ChildItem $AZP_CUSTOM_CERT_PEM -Filter *.crt | ForEach-Object {
    Write-Host "Certificate $($_.Name)"

    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($_.FullName)
    Write-Host "  Valid from: " $cert.NotBefore
    Write-Host "  Valid to:   " $cert.NotAfter

    Write-Host "Updating certificates keychain"
    Import-Certificate -FilePath $_.FullName -CertStoreLocation Cert:\LocalMachine\Root
  }
} else {
  Write-Host "No custom SSL certificate provided"
}

Write-Header "Configuring agent"

Set-Location $(Split-Path -Parent $MyInvocation.MyCommand.Definition)

& config.cmd `
  --acceptTeeEula `
  --agent $AZP_AGENT_NAME `
  --auth PAT `
  --pool $AZP_POOL `
  --replace `
  --token $AZP_TOKEN `
  --unattended `
  --url $AZP_URL `
  --work $AZP_WORK

Write-Header "Running agent"

# Running it with the --once flag at the end will shut down the agent after the build is executed
try {
  if ($isTemplateJob) {
    Write-Host "Agent will be stopped after 1 min"
    Start-Job -ScriptBlock {
      Start-Sleep -Seconds 60
      & run.cmd $Args --once
    }
  } else {
    & run.cmd $Args --once
  }
} finally {
  # Unregister on success, Ctrl+C, and SIGTERM
  Unregister
}

Write-Header "Printing agent diag logs"

Get-Content $AGENT_DIAGLOGPATH/*.log
