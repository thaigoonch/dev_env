#!/bin/bash

LOG_FILE="/home/goonch/install_logs.txt"
DOWNLOAD_DIR="/home/goonch/Downloads"
INSTALL_DIR="/usr/local/bin"

# Define environment variables for versioning
GO_VERSION="1.23.0" # get latest num at https://go.dev/doc/install
HELM_VERSION="3.15.4" # get latest vers at https://github.com/helm/helm/releases
HELMFILE_VERSION="0.167.1" # get latest num at https://github.com/helmfile/helmfile/releases
STERN_VERSION="1.30.0" # get latest num at https://github.com/stern/stern/releases
KUBEFWD_VERSION="1.22.5" # get latest num at https://github.com/txn2/kubefwd/releases

# Check if the script is being run as root (with sudo)
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

if [ ! -d "$DOWNLOAD_DIR" ]; then
  echo "Error: Directory $DOWNLOAD_DIR does not exist."
  echo "Modify \$DOWNLOAD_DIR in the script. Exiting"
  exit 1
fi

echo "Installation script started at $(date)" > $LOG_FILE

function install_via_cmd {
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

function install_gz {
    local pkg_name=$1
    local url=$2
    local verify_cmd=$3

    # rarely needed
    # specifies the dir the app was extracted into -- since it may not always be root.
    # e.g. helm extracts into linux-amd64/
    # exclude this input param if the app extracts without nested dir(s).
    # it will be set to the pkg_name if you exclude it
    local extracted_dir=$4
    if [ -n "$extracted_dir" ]; then
      extracted_dir="${extracted_dir}/${pkg_name}"
    else
      extracted_dir="${pkg_name}"
    fi


    if ! command -v $pkg_name &> /dev/null; then
        echo "$pkg_name is not installed. Downloading binary..." | tee -a $LOG_FILE
	echo ">>> running: curl -Lo $DOWNLOAD_DIR/$pkg_name $url" | tee -a $LOG_FILE
        curl -Lo $DOWNLOAD_DIR/$pkg_name $url 2>&1 | tee -a $LOG_FILE
	echo ">>> running: sudo tar -xvf $DOWNLOAD_DIR/$pkg_name -C $DOWNLOAD_DIR" | tee -a $LOG_FILE
        sudo tar -xvf $DOWNLOAD_DIR/$pkg_name -C $DOWNLOAD_DIR 2>&1 | tee -a $LOG_FILE
	echo ">>> running: sudo mv $DOWNLOAD_DIR/$pkg_name $INSTALL_DIR" | tee -a $LOG_FILE
	sudo mv $DOWNLOAD_DIR/$extracted_dir $INSTALL_DIR 2>&1 | tee -a $LOG_FILE
        if [ $? -eq 0 ]; then
            echo "Verifying install was successful: $verify_cmd" | tee -a $LOG_FILE
            eval $verify_cmd 2>&1 | tee -a $LOG_FILE
            echo "Cleaning up $pkg_name binary..." | tee -a $LOG_FILE
            sudo rm -f $DOWNLOAD_DIR/$extracted_dir 2>&1 | tee -a $LOG_FILE
	    sudo rm -f $DOWNLOAD_DIR/LICENSE*
	    sudo rm -f $DOWNLOAD_DIR/README*
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

function install_deb {
    local pkg_name=$1
    local url=$2
    local verify_cmd=$3

    if ! command -v $pkg_name &> /dev/null; then
        echo "$pkg_name is not installed. Downloading binary..." | tee -a $LOG_FILE
        echo ">>> running: curl -Lo $DOWNLOAD_DIR/$pkg_name.deb $url" | tee -a $LOG_FILE
        curl -Lo $DOWNLOAD_DIR/$pkg_name.deb $url 2>&1 | tee -a $LOG_FILE
        echo ">>> running: sudo apt-get install $DOWNLOAD_DIR/$pkg_name.deb" | tee -a $LOG_FILE
        sudo apt-get install $DOWNLOAD_DIR/$pkg_name.deb | tee -a $LOG_FILE
        if [ $? -eq 0 ]; then
            echo "Verifying install was successful: $verify_cmd" | tee -a $LOG_FILE
            eval $verify_cmd 2>&1 | tee -a $LOG_FILE
            echo "Cleaning up $pkg_name binary..." | tee -a $LOG_FILE
            sudo rm -f $DOWNLOAD_DIR/$pkg_name 2>&1 | tee -a $LOG_FILE
            sudo rm -f $DOWNLOAD_DIR/LICENSE*
            sudo rm -f $DOWNLOAD_DIR/README*
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

# Install applications via apt
install_via_cmd "copyq" "sudo apt-get install -y copyq" "copyq --version"
install_via_cmd "terminator" "sudo apt-get install -y terminator" "terminator --version"
install_via_cmd "meld" "sudo apt-get install -y meld" "meld --version"
install_via_cmd "pip3" "sudo apt update && sudo apt install -y python3-pip" "pip3 --version"
install_via_cmd "git" "sudo apt install -y git" "git --version"
install_via_cmd "curl" "sudo apt install -y curl" "curl --version"
install_via_cmd "vim" "sudo apt install -y vim" "vim --version"
install_via_cmd "pre-commit" "pip install pre-commit" "pre-commit --version"

# Install other binary applications
install_gz "helm" "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" "helm version" "linux-amd64"
install_gz "helmfile" "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz" "helmfile --version"
install_gz "stern" "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz" "stern --version"
install_gz "kubefwd" "https://github.com/txn2/kubefwd/releases/download/${KUBEFWD_VERSION}/kubefwd_Linux_x86_64.tar.gz" "kubefwd --version"
install_deb "code" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" "code --version"


function install_kubectl {
    local pkg_name="kubectl"
    local verify_cmd="kubectl version --client"

    if ! command -v $pkg_name &> /dev/null; then
        echo "$pkg_name is not installed. Downloading binary..." | tee -a $LOG_FILE
        echo ">>> running: curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"" | tee -a $LOG_FILE
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>&1 | tee -a $LOG_FILE
        echo ">>> running: sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl" | tee -a $LOG_FILE
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl | tee -a $LOG_FILE
        if [ $? -eq 0 ]; then
            echo "Verifying install was successful: $verify_cmd" | tee -a $LOG_FILE
            eval $verify_cmd 2>&1 | tee -a $LOG_FILE
            echo "Cleaning up $pkg_name binary..." | tee -a $LOG_FILE
            sudo rm -f $DOWNLOAD_DIR/$pkg_name 2>&1 | tee -a $LOG_FILE
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

install_kubectl

echo "Installation script completed at $(date)" | tee -a $LOG_FILE
