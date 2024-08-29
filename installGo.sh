#!/bin/bash

LOG_FILE="/home/goonch/install_go_logs.txt"
DOWNLOAD_DIR="/home/goonch/Downloads"

# Define environment variables for versioning
GO_VERSION="$1" # get latest vers num at https://go.dev/doc/install
# Check if GO_VERSION is set
if [ -z "$GO_VERSION" ]; then
  echo "Error: GO_VERSION (arg) is required and not set."
  echo "e.g. to run:"
  echo "  installGo.sh 1.23.0"
  echo "Get the latest Go vers num at https://go.dev/doc/install"
  echo "Exiting."
  exit 1
fi

# Check if the script is being run with sudo or as root
if [ "$EUID" -eq 0 ]; then
  echo "Error: This script should NOT be run as root or with sudo. Exiting."
  exit 1
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
  echo "Error: Directory $DOWNLOAD_DIR does not exist."
  echo "Modify \$DOWNLOAD_DIR in the script. Exiting"
  exit 1
fi

echo "Go installation script started at $(date)" > $LOG_FILE

# since not running as sudo, create the log file
sudo touch $LOG_FILE
sudo chmod +w $LOG_FILE

function install_go {
    local pkg_name=$1
    local url=$2
    local verify_cmd=$3

    echo "Deleting old go" | tee -a $LOG_FILE
    sudo rm -rf /usr/local/go 2>&1 | tee -a $LOG_FILE
    echo ">>> running: curl -Lo $DOWNLOAD_DIR/$pkg_name $url" | tee -a $LOG_FILE
    curl -Lo $DOWNLOAD_DIR/$pkg_name $url 2>&1 | tee -a $LOG_FILE
    echo ">>> running: sudo tar -xvf $DOWNLOAD_DIR/$pkg_name -C $DOWNLOAD_DIR" | tee -a $LOG_FILE
    sudo tar -C /usr/local -xvf $DOWNLOAD_DIR/$pkg_name 2>&1 | tee -a $LOG_FILE
    if [ $? -eq 0 ]; then
        echo "Verifying install was successful: $verify_cmd" | tee -a $LOG_FILE
        eval $verify_cmd 2>&1 | tee -a $LOG_FILE
        echo "Cleaning up $pkg_name binary..." | tee -a $LOG_FILE
        sudo rm -rf $DOWNLOAD_DIR/$pkg_name 2>&1 | tee -a $LOG_FILE
    else
        echo "Error installing $pkg_name. Do you want to skip this install? (y/n)" | tee -a $LOG_FILE
        read choice
        if [ "$choice" = "n" ]; then
            exit 1
	fi
    fi
}

function install_go_tools {
    local pkg_name=$1
    local install_cmd=$2
    local verify_cmd=$3

    if ! command -v $pkg_name &> /dev/null; then
        echo "$pkg_name is not installed. Installing..." | tee -a $LOG_FILE
        eval $install_cmd 2>&1 | tee -a $LOG_FILE
        if [ $? -eq 0 ]; then
            echo "Verifying install was successful: $verify_cmd" | tee -a $LOG_FILE
            eval $verify_cmd 2>&1 | tee -a $LOG_FILE
        else
            echo "Error installing $pkg_name. Do you want to skip this install? (y/n)" | tee -a $LOG_FILE
            read choice
            if [ "$choice" = "n" ]; then
                exit 1
            fi
        fi
    else
        echo "$pkg_name is already installed. Skipping..." | tee -a $LOG_FILE
    fi
}

# Install Go
install_go "go" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" "go version"

# Install Go tools
install_go_tools "gorelease" "go install golang.org/x/exp/cmd/gorelease@latest" "gorelease --version"
install_go_tools "grpcurl" "go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest" "grpcurl --version"

echo "Go installation script completed at $(date)" | tee -a $LOG_FILE
