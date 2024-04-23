$AZP_AGENT_NAME = $Env:AZP_AGENT_NAME
$AZP_CUSTOM_CERT_PEM = $Env:AZP_CUSTOM_CERT_PEM
$AZP_POOL = $Env:AZP_POOL
$AZP_TOKEN = $Env:AZP_TOKEN
$AZP_URL = $Env:AZP_URL
$AZP_WORK = $Env:AZP_WORK

if ($null -eq $AZP_URL -or $AZP_URL -eq "") {
  throw "error: missing AZP_URL environment variable"
}

if ($null -eq $AZP_TOKEN -or $AZP_TOKEN -eq "") {
  throw "error: missing AZP_TOKEN environment variable"
}

if ($null -eq $AZP_POOL -or $AZP_POOL -eq "") {
  throw "error: missing AZP_POOL environment variable"
}

# If AZP_AGENT_NAME is not set, use the container hostname
if ($null -eq $AZP_AGENT_NAME -or $AZP_AGENT_NAME -eq "") {
  Write-Host "warn: missing AZP_AGENT_NAME environment variable"
  $AZP_AGENT_NAME = $Env:COMPUTERNAME
}

if ($null -eq $AZP_WORK -or $AZP_WORK -eq "") {
  throw "error: missing AZP_WORK environment variable"
}

if (!(Test-Path $AZP_WORK)) {
  throw "error: work dir AZP_WORK ($AZP_WORK) is not writeable or does not exist"
}

function Write-Header() {
  Write-Host "> $1" -ForegroundColor Cyan
}

function Unregister {
  Write-Host "Unregister, removing agent from server"

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

if ((Test-Path $AZP_CUSTOM_CERT_PEM) -and ((Get-ChildItem $AZP_CUSTOM_CERT_PEM).Count -gt 0)) {
  Write-Header "Adding custom SSL certificates"
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
  Write-Header "No custom SSL certificate provided"
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

# Unregister on success, Ctrl+C, and SIGTERM
try {
  # Running it with the --once flag at the end will shut down the agent after the build is executed
  & run.cmd $Args --once
} finally {
  Unregister
}

Write-Header "Printing agent diag logs"

Get-Content $AGENT_DIAGLOGPATH/*.log
