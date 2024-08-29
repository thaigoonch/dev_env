# Katherine's dev env installs
Some scripts to automate some of the needed installs for my preferred dev environment.

For linux-amd64

## setupEnv.sh
Installs:
- copyq (clipboard manager)
- terminator (terminal)
- meld (diff-ing tool)
- pip3
- git
- curl
- vim
- pre-commit
- helm
- helmfile
- stern
- kubefwd
- VS code (IDE)
- kubectl

To run: `sudo setupEnv.sh`

Be sure to modify the script's env vars to set the desired versions of apps.

This script's logs are (over)written to `/home/${USER}/install_logs.txt`

## installGo.sh
Installs:
- Go
- gorelease
- grpcurl

To run: `installGo.sh 1.23.0`, where the arg is the desired Go version.

Get the latest Go vers num at https://go.dev/doc/install.

This script's logs are (over)written to `/home/${USER}/install_go_logs.txt`

This script can be run to update Go too (removes old Go install).

gorelease and grpcurl will not be reinstalled if they already are.
