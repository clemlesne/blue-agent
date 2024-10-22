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
  Raise-Error "Work dir AZP_WORK ($AZP_WORK) is not writeable or does not exist"
}

Write-Header "Running agent $Env:AZP_AGENT_NAME in pool $Env:AZP_POOL"

function Unregister {
  Write-Host "Removing agent"

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

Write-Header "Running agent"

# Unregister on success, Ctrl+C, and SIGTERM
try {
  # Running it with the --once flag at the end will shut down the agent after the build is executed
  & run.cmd $Args --once
} finally {
  Unregister
}

Write-Header "Printing agent diag logs"

Get-Content $AGENT_DIAGLOGPATH/*.log
