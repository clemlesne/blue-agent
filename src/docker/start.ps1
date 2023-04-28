$AZP_URL = $Env:AZP_URL
$AZP_TOKEN = $Env:AZP_TOKEN
$AZP_POOL = $Env:AZP_POOL
$AZP_AGENT_NAME = $Env:AZP_AGENT_NAME
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

if ($null -eq $AZP_AGENT_NAME -or $AZP_AGENT_NAME -eq "") {
  throw "error: missing AZP_AGENT_NAME environment variable"
}

if ($null -eq $AZP_WORK -or $AZP_WORK -eq "") {
  throw "error: missing AZP_WORK environment variable"
}

if (!(Test-Path $AZP_WORK)) {
  throw "error: work dir AZP_WORK ($AZP_WORK) is not writeable or does not exist"
}

function Display-Header() {
  Write-Host "> $1" -ForegroundColor Cyan
}

Set-Location $(Split-Path -Parent $MyInvocation.MyCommand.Definition)

Display-Header "Configuring agent..."

.\config.cmd `
  --acceptTeeEula `
  --agent $AZP_AGENT_NAME `
  --auth PAT `
  --pool $AZP_POOL `
  --replace `
  --token $AZP_TOKEN `
  --unattended `
  --url $AZP_URL `
  --work $AZP_WORK

Display-Header "Running agent..."

# Running it with the --once flag at the end will shut down the agent after the build is executed
.\run.cmd $Args --once
