#!/bin/bash

# If no sudo - quit
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   echo "Please call it with --> sudo $0"
   exit 1
fi

if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

read -p "Is this the correct docker user on the system [Y/y]: ${REAL_USER}? " ACTION

if [[ ! ${ACTION} =~ [Yy] ]]; then
    echo -e "List of users on the system:\n"
    awk -F: '{print $1}' /etc/passwd
    echo ""
    read -p "What user will be running the docker containers? " REAL_USER
fi

# Read user input and store in variables
read -p 'Please set your computer hostname: ' PC_HOSTNAME
hostnamectl set-hostname ${PC_HOSTNAME}

# Comment the below if the user is different
NAS_USER=admin
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PUID=$(id -u ${REAL_USER})
PGID=$(id -u ${REAL_USER})
TZ="Australia/Sydney"
USERDIR="/home/${REAL_USER}"
MYSQL_ROOT_PASSWORD=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
echo "[client]" > ${USERDIR}/.my.cnf
echo "user=root" >> ${USERDIR}/.my.cnf
echo "password=${MYSQL_ROOT_PASSWORD}" >> ${USERDIR}/.my.cnf
echo "Mysql root password stored in ${USERDIR}/.my.cnf"

if [[ -z ${NAS_USER} ]]; then
    read -p 'NAS Username: ' NAS_USER
fi
read -sp 'NAS Password: ' NAS_PASS

# Getting things ready
PS3='Please select your OS: '
options=("Fedora/CentOS" "Ubuntu" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Fedora/CentOS")
            if [[ -x $(which dnf) ]]; then
                INSTALL_COMMAND=$(which dnf)
                echo "I have found your package manager '${INSTALL_COMMAND}' for $opt. Continuing..."
                break
            elif [[ -x $(which yum) ]]; then
                INSTALL_COMMAND=$(which yum)
                echo "I have found your package manager '${INSTALL_COMMAND}' for $opt. Continuing..."
                break
            else
                echo "I could not find your $opt package manager, try again..."
            fi
            ;;
        "Ubuntu")
            if [[ -x $(which apt) ]]; then
                INSTALL_COMMAND=$(which apt)
                echo "I have found your package manager '${INSTALL_COMMAND}' for $opt. Continuing..."
                break
            else
                echo "I could not find your $opt package manager, try again..."
            fi
            ;;
        "Quit")
            exit 0
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

# Creating dir structure and properties
mkdir -p /mnt/NAS/Downloads /mnt/NAS/Video ${USERDIR}/docker
sudo setfacl -Rdm g:docker:rwx ${USERDIR}/docker
sudo chmod -R 775 ${USERDIR}/docker
$INSTALL_COMMAND update
$INSTALL_COMMAND upgrade
$INSTALL_COMMAND install -y cifs-utils bash-completion vim curl wget telnet nfs-common apt-transport-https ca-certificates gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
$INSTALL_COMMAND install -y docker-ce
usermod -aG docker ${REAL_USER}
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

cat << EOF >> /etc/fstab

# Custom ones

10.0.0.3:/volume1/Downloads /mnt/NAS/Downloads nfs rsize=8192,wsize=8192,timeo=14,intr
10.0.0.3:/volume1/Video /mnt/NAS/Video nfs rsize=8192,wsize=8192,timeo=14,intr
EOF

sestatus | grep 'SELinux status' | grep -qi enabled
if [[ ! $? -ge 1 ]]; then
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

##############################
### Setup bash environment ###
##############################

if [[ $(grep bash_alias ${USERDIR}/.bashrc | wc -l) -lt 2 ]]
then
    cat << EOF >> ${USERDIR}/.bashrc

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
    touch ${USERDIR}/.bash_aliases
fi

##############
### Others ###
##############

cp $SCRIPT_DIR/configs/.vimrc ${USERDIR}/
cp $SCRIPT_DIR/configs/docker-compose.yml ${USERDIR}/docker
