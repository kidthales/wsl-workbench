<#
.SYNOPSIS
WSL workbench management frontend.

.DESCRIPTION
USAGE
    .\workbench.ps1 <command>

COMMANDS
    build       build workbench container
    install     install workbench container to wsl2
    backup      backup home directory from workbench installed in wsl2
    uninstall   uninstall workbench from wsl2
    help, -?    show this help message
#>
Param(
  [Parameter(Position=0)][ValidateSet("build", "install", "backup", "uninstall", "help")][string]$Command,
  [Parameter(Position=1, ValueFromRemainingArguments=$true)]$Rest
)

function Invoke-Get-Help { Get-Help $PSCommandPath }

if (!$Command) {
  Invoke-Get-Help
  exit
}

function New-Workbench {
<#
.SYNOPSIS
Build workbench container.

.DESCRIPTION
USAGE
    .\workbench.ps1 build <user> [distro-name [, automount]]
#>
  Param(
    [Parameter(Position=0)][string]$User,
    [Parameter(Position=1)][string]$WSLName = "workbench",
    [Parameter(Position=2)][string]$WSLAutomount = "/mnt"
  )

  if (!$User) {
    Get-Help New-Workbench
    exit
  }

  New-Item -Path .\dist\builds -ItemType Directory -Force | Out-Null

  docker build --build-arg user="$User" --build-arg wsl_automount="$WSLAutomount" --build-arg wsl_name="$WSLName" -t "$WSLName" .
  docker run --name "$WSLName" "$WSLName"
  docker export --output="dist/builds/$WSLName.tar.gz" "$WSLName"

  docker container rm "$WSLName"
  docker rmi "$WSLName"
}

function Install-Workbench {
<#
.SYNOPSIS
Install workbench container to wsl2.

.DESCRIPTION
USAGE
    .\workbench.ps1 install <distro-name>
#>
  Param(
    [Parameter(Position=0)][string]$WSLName
  )

  if (!$WSLName) {
    Get-Help Install-Workbench
    exit
  }

  New-Item -Path .\dist\installs\"$WSLName" -ItemType Directory -Force | Out-Null

  wsl --set-default-version 2
  wsl --import "$WSLName" .\dist\installs\"$WSLName" .\dist\builds\"$WSLName".tar.gz

  Remove-Item .\dist\builds\"$WSLName".tar.gz -Force
}

function Uninstall-Workbench {
<#
.SYNOPSIS
Uninstall workbench from wsl2.

.DESCRIPTION
USAGE
    .\workbench.ps1 uninstall <distro-name>
#>
  Param(
    [Parameter(Position=0)][string]$WSLName
  )

  if (!$WSLName) {
    Get-Help Uninstall-Workbench
    exit
  }

  Backup-Home "$WSLName"

  wsl --unregister "$WSLName"

  Remove-Item .\dist\installs\"$WSLName" -Force
}

function Backup-Home {
<#
.SYNOPSIS
Backup home directory from workbench installed in wsl2.

.DESCRIPTION
USAGE
    .\workbench.ps1 backup <distro-name>
#>
  Param(
    [Parameter(Position=0)][string]$WSLName
  )

  if (!$WSLName) {
    Get-Help Backup-Home
    exit
  }

  New-Item -Path .\dist\backups\"$WSLName" -ItemType Directory -Force | Out-Null

  wsl --distribution "$WSLName" tar -czf dist/backups/"$WSLName"/home-$(Get-Date -f yyyy-MM-dd-hh-mm-ss).tgz /home
}

switch ($Command) {
  "build"     { New-Workbench $Rest; break }
  "install"   { Install-Workbench $Rest; break }
  "uninstall" { Uninstall-Workbench $Rest; break }
  "backup"    { Backup-Home $Rest; break }
  "help"      { Invoke-Get-Help; break }
  default     { break }
}
