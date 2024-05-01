# WSL Workbench

Containerized development environment for WSL.

## Quick Start

In PowerShell:

1.  `.\workbench.ps1 build <username>`
2.  `.\workbench.ps1 install workbench`

Now ready for use in PowerShell (or as a dev container, etc):

-   `wsl --distribution workbench ls -al /home/<username>`

## Help

In PowerShell:

-   `.\workbench.ps1 help`

## Backup

Contents of the workbench home directory can be archived and written to this project's workspace in Windows.

In PowerShell:

-   `.\workbench.ps1 backup workbench`
-   Results in `.tgz` file written to `.\dist\backups\workbench`.

## Uninstall

In PowerShell:

-   `.\workbench.ps1 uninstall workbench`
-   Always performs a backup operation prior to uninstall.
