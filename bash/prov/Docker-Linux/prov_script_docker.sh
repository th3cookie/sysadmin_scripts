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

read -p "Is this the correct docker user on the system: ${REAL_USER}? [Y/y] " ACTION

if [[ ! ${ACTION} =~ [Yy] ]]; then
    echo -e "List of users on the system:\n"
    awk -F: '{print $1}' /etc/passwd
    echo ""
    read -p "Which user will be running the docker containers? " REAL_USER
fi

# Getting things ready
if [[ ! $(lsb_release -is | grep -i ubuntu) ]]
then
    echo "This script will only work on an ubuntu machine."
    exit 1
fi
if [[ -x $(which apt) ]]; then
    INSTALL_COMMAND=$(which apt)
    echo -e "\nI have found your package manager '${INSTALL_COMMAND}'. Continuing...\n"
elif [[ -x $(which apt-get) ]]; then
    INSTALL_COMMAND=$(which apt-get)
    echo -e "\nI have found your package manager '${INSTALL_COMMAND}'. Continuing...\n"
else
    echo -e "\nI could not find your package manager, something went wrong, exiting.\n"
    exit 1
fi

# This is a menu creation function with an undefined amount of arguments passed to it.
menu_from_array () {
    select item; do
        # Check the selected menu item number
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
            echo "The selected item is $item"
            SELECTED_ITEM=$item
            break;
        else
            echo "Wrong selection: Select any number from 1-$#"
        fi
    done
}

# Read user input and store in variables
read -p 'Please set your computer hostname: ' PC_HOSTNAME
hostnamectl set-hostname ${PC_HOSTNAME}
VPN_PROVIDER="NORDVPN"
read -p "Is your VPN Provider still ${VPN_PROVIDER}? [Y/y]: " VPN_ANSWER
if [[ ! ${VPN_ANSWER} =~ [Yy] ]]; then
    echo "Please enter your VPN provider from this list: (ensure you input an item from the \"config value\" column)"
    echo "https://haugene.github.io/docker-transmission-openvpn/supported-providers/"
    read -p "Who is your VPN provider? " VPN_PROVIDER
fi
read -p 'VPN Username: ' VPN_USER
read -sp 'VPN Password: ' VPN_PASS
read -p 'Transmission Username: ' TRANSMISSION_USER
read -sp 'Transmission Password: ' TRANSMISSION_PASS
read -p "Would you like your MariaDB root password generated automatically? Type anything else to set it manually: [Yy] " MYSQL_PW_SET
if [[ ${MYSQL_PW_SET} =~ [Yy] ]]; then
    MYSQL_ROOT_PASSWORD=$(date +%s | sha256sum | base64 | head -c 12)
else
    read -sp "Please enter your MariaDB password for the root user: " MYSQL_ROOT_PASSWORD
fi

# Comment the below if the user is different
NAS_USER=admin
if [[ -z ${NAS_USER} ]]; then
    read -p 'NAS Username: ' NAS_USER
fi
read -sp 'NAS Password: ' NAS_PASS

# Setting up the menu of interface on the machine to allow the user to specify which interface to allow local traffic to transmission on.
# Declare the array and add the interfaces to it
INTERFACE_OPTIONS=()
for i in $(ip a | grep -oP "(?<=\d: )(.*)(?=:)"); do
    IP=$(ip -4 a show ${i} | grep -oP '(?<=inet\s)\d+(\.\d+){3}\/\d+')
    INTERFACE_OPTIONS=( "${INTERFACE_OPTIONS[@]}" "${i} -> ${IP}" )
done
# Call the subroutine to create the menu
echo -e "\nPlease specify the subnet which transmission will allow local connections to the webui from (i.e. which network should transmission allow to bypass the VPN tunnel interface inside the container)?"
echo "This is generally the interface which has your devices private NAT IP from your router (e.g. 10.0.0.7 or 192.168.0.7 etc.)"
echo "Unfortunately, this script will only work on /24 subnets. No logic has been done on any other subnet."
menu_from_array "${INTERFACE_OPTIONS[@]}"
# LOCAL_INTERFACE=$(echo "${SELECTED_ITEM}" | awk '{print $1}')
LOCAL_SUBNET=$(echo "${SELECTED_ITEM}" | awk '{print $3}' | awk -F. '{print $1"."$2"."$3".0/24"}')
TRANSMISSION_WHITELIST=$(echo "${LOCAL_SUBNET}" | awk -F. '{print "\"127.0.0.1,"$1"."$2"."$3".*\""}')

$INSTALL_COMMAND update
$INSTALL_COMMAND upgrade -y
$INSTALL_COMMAND install -y cifs-utils bash-completion vim curl wget telnet nfs-common apt-transport-https ca-certificates software-properties-common \
jq python3.8 python3 python3-venv python3-pip git apache2-utils
# Determine Python version to parse yaml and add to MOTD. If no python, exit.
PY_VERSION=$(which python3.8)
if [[ -z ${PY_VERSION} ]]; then
    PY_VERSION=$(which python3.6)
fi
if [[ -z ${PY_VERSION} ]]; then
    PY_VERSION=$(which python3)
fi
if [[ -z ${PY_VERSION} ]]; then
    echo "Could not find your python version from either '3.8', '3.6' or '3'. Please manually install one of these with \"${INSTALL_COMMAND} install -y python3\"."
    echo "Exiting the script, please re-run it after installing python 3."
    exit 1
fi
pip3 install -U pip
sudo pip install -U pip
pip3 install pyyaml
pip3 install -U pyyaml
${PY_VERSION} -m pip install -U pyyaml
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
$INSTALL_COMMAND update
$INSTALL_COMMAND install -y docker-ce
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq '.name' | sed 's/"//g')
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${REAL_USER}
PUID=$(id -u ${REAL_USER})
PGID=$(grep docker /etc/group | grep -oP "\d+")
TZ="Australia/Sydney"
USERDIR="/home/${REAL_USER}"
echo "PUID=${PUID}" | sudo tee -a /etc/environment
echo "PGID=${PGID}" | sudo tee -a /etc/environment
echo "TZ=${TZ}" | sudo tee -a /etc/environment
echo "USERDIR=${USERDIR}" | sudo tee -a /etc/environment
echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" | sudo tee -a /etc/environment
echo "VPN_PROVIDER=${VPN_PROVIDER}" | sudo tee -a /etc/environment
echo "VPN_USER=${VPN_USER}" | sudo tee -a /etc/environment
echo "VPN_PASS=${VPN_PASS}" | sudo tee -a /etc/environment
echo "TRANSMISSION_USER=${TRANSMISSION_USER}" | sudo tee -a /etc/environment
echo "TRANSMISSION_PASS=${TRANSMISSION_PASS}" | sudo tee -a /etc/environment
echo "LOCAL_SUBNET=${LOCAL_SUBNET}" | sudo tee -a /etc/environment
echo "TRANSMISSION_WHITELIST=${TRANSMISSION_WHITELIST}" | sudo tee -a /etc/environment
echo "TRANSMISSION_DOWNLOAD_LOCATION=${TRANSMISSION_DOWNLOAD_LOCATION}" | sudo tee -a /etc/environment

# Creating dir structure and properties
mkdir -p ${USERDIR}/mount/Downloads ${USERDIR}/mount/Video ${USERDIR}/docker
sudo chmod -R 775 ${USERDIR}/docker
sudo setfacl -Rdm g:docker:rwx ${USERDIR}/docker
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat << EOF | sudo tee -a /etc/fstab

# Custom ones

10.0.0.3:/volume1/Downloads ${USERDIR}/mount/Downloads nfs rsize=8192,wsize=8192,timeo=14,intr
10.0.0.3:/volume1/Video ${USERDIR}/mount/Video nfs rsize=8192,wsize=8192,timeo=14,intr
EOF

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

cp $SCRIPT_DIR/docker-compose.yml ${USERDIR}/docker
chmod +x ./parse-yaml.py
sudo ${PY_VERSION} ./parse-yaml.py