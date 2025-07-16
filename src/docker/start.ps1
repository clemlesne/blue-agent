# Start the Azure DevOps agent in a Windows container
#
# This script handles both regular agent execution and template container creation.
# Template containers are special agents that serve as references for KEDA auto-scaling.
#
# Template Container Logic:
# - When AZP_TEMPLATE_JOB=1, the agent runs as a template container
# - Template containers register with Azure DevOps but don't process jobs
# - They run for 1 minute to establish capabilities, then stop
# - KEDA uses the template agent as a reference for scaling decisions
# - This prevents scaling errors when no agents are initially available
#
# Agent is always registered. It is removed from the server only when the agent is not a template job. After 60 secs, it tries to shut down the agent gracefully, waiting for the current job to finish, if any.
#
# Environment variables:
# - AZP_AGENT_NAME: Agent name (default: hostname)
# - AZP_CUSTOM_CERT_PEM: Custom SSL certificates directory (default: empty)
# - AZP_POOL: Agent pool name
# - AZP_TEMPLATE_JOB: Template job flag (default: 0) - when set to 1, creates template container
# - AZP_TOKEN: Personal access token
# - AZP_URL: Server URL
# - AZP_WORK: Work directory

##
# Misc functions
##

function Write-Header() {
  Write-Host "➡️ $1" -ForegroundColor Cyan
}

function Write-Warning() {
  Write-Host "⚠️ $1" -ForegroundColor Yellow
}

function Raise-Error() {
  throw "❌ $1"
}

##
# Argument parsing
##

if ($null -eq $Env:AZP_URL -or $Env:AZP_URL -eq "") {
  Raise-Error "Missing AZP_URL environment variable"
}

if ($null -eq $Env:AZP_TOKEN -or $Env:AZP_TOKEN -eq "") {
  Raise-Error "Missing AZP_TOKEN environment variable"
}

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
  Write-Warning "Template job enabled, agent cannot be used for running jobs - see documentation for details"
  $isTemplateJob = $true
  $Env:AZP_AGENT_NAME = "$Env:AZP_AGENT_NAME-template"
}

Write-Header "Running agent $Env:AZP_AGENT_NAME in pool $Env:AZP_POOL"

##
# Cleanup function
##

function Unregister {
  Write-Header "Removing agent"

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
      Write-Host "A job is still running, waiting 15 seconds before retrying the removal"
      Start-Sleep -Seconds 15
    }
  }
}

##
# Custom SSL certificates
##

Write-Header "Adding custom SSL certificates"

if ((Test-Path $Env:AZP_CUSTOM_CERT_PEM) -and ((Get-ChildItem $Env:AZP_CUSTOM_CERT_PEM).Count -gt 0)) {
  Write-Host "Searching for *.crt in $Env:AZP_CUSTOM_CERT_PEM"

  Get-ChildItem $Env:AZP_CUSTOM_CERT_PEM -Filter *.crt | ForEach-Object {
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

##
# Agent configuration
##

Write-Header "Configuring agent"

Set-Location $(Split-Path -Parent $MyInvocation.MyCommand.Definition)

& config.cmd `
  --acceptTeeEula `
  --agent $Env:AZP_AGENT_NAME `
  --auth PAT `
  --gitUseSChannel `
  --pool $Env:AZP_POOL `
  --replace `
  --token $Env:AZP_TOKEN `
  --unattended `
  --url $Env:AZP_URL `
  --work $Env:AZP_WORK

##
# Agent execution
##

Write-Header "Running agent"

# Running it with the --once flag at the end will shut down the agent after the build is executed
if ($isTemplateJob) {
  Write-Host "Agent will be stopped after 1 min"
  # Run the agent for a minute to allow registration and capability detection
  Start-Job -ScriptBlock {
    Start-Sleep -Seconds 60
    & run.cmd $Args --once
  }
} else {
  try {
    # Run the countdown for fast-clean if no job is using the agent after a delay
    Start-Job -ScriptBlock {
      Start-Sleep -Seconds 60
      Unregister
    }
    # Run the agent
    & run.cmd $Args --once
  } finally {
    # Unregister on success, Ctrl+C, and SIGTERM
    Unregister
  }
}

##
# Diagnostics
##

Write-Header "Printing agent diag logs"

Get-Content $AGENT_DIAGLOGPATH/*.log
