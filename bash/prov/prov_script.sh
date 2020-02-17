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

# Read user input and store in variables
read -p 'Is this a work desktop [Y/y]? ' WORKPC
read -p 'Please set your computer hostname: ' PC_HOSTNAME
hostnamectl set-hostname ${PC_HOSTNAME}
read -p 'Git Config username: ' GIT_USERNAME
read -p 'Git Config Email: ' GIT_EMAIL

if [[ ! ${WORKPC} =~ [Yy] ]]; then
    # Comment the below if the user is different
    NAS_USER=admin

    if [[ -z ${NAS_USER} ]]; then
        read -p 'NAS Username: ' NAS_USER
    fi
    read -sp 'NAS Password: ' NAS_PASS
fi

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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
HOME_DIR=/home/${REAL_USER}
GIT_DIR=${HOME_DIR}/git
mkdir $GIT_DIR
chown -R $REAL_USER:$REAL_USER $GIT_DIR
chmod 755 $GIT_DIR
mkdir -p ${HOME_DIR}/work ${HOME_DIR}/Downloads /mnt/NAS/Samis_folder 

# Installing required packages
$INSTALL_COMMAND update
$INSTALL_COMMAND upgrade
$INSTALL_COMMAND install -y cifs-utils openvpn facter ruby puppet python3.8 firefox git bash-completion vim pip npm curl wget telnet ShellCheck xclip subnetcalc \
snapd
if [[ $? -ne 0 ]]; then
    echo "Could not download some/all of the packages, please check package manager history."
fi

##################
### Work Stuff ###
##################

if [[ ${WORKPC} =~ [Yy] ]]; then
    echo "work PC"
else
    # If not a work PC...
    # VPN to connect to work network -> https://sslvpn01.digitalpacific.com.au:942/?src=connect
    cat << EOF >> ${HOME_DIR}/.bash_aliases
alias ovpn='sudo openvpn --config ~/work/hostopia.ovpn &'
EOF
    # Downloading files from NAS
    mount -t cifs -o username=${NAS_USER},password=${NAS_PASS},vers=1.0 //10.0.0.3/Samis_Folder /mnt/NAS/Samis_folder/
    if [[ $? -ne 0 ]]; then
        echo -e "Could not download openvpn profile and SSH keys from NAS.\nCheck if you can mount cifs or not."
    else
        cp /mnt/NAS/Samis_folder/ops/hostopia.ovpn ${HOME_DIR}/work
        cp /mnt/NAS/Samis_folder/ops/ssh_keys/sami-openssh-private-key.ppk ${HOME_DIR}/.ssh/sami-openssh-private-key.ppk
        chmod 600 ${HOME_DIR}/.ssh/sami-openssh-private-key.ppk ${HOME_DIR}/.ssh/SShakir-openssh-private-key
        cp /mnt/NAS/Samis_folder/ops/ssh_keys/Work/SShakir-openssh-private-key ${HOME_DIR}/.ssh/SShakir-openssh-private-key
        cp /mnt/NAS/Samis_folder/ops/prov_apps/* ${HOME_DIR}/Downloads/
    fi
    echo -e 'Downloading tor. It then needs to be extracted and placed in a $PATH directory to be able to start.'
    echo -e 'If TOR Fails to download, do it yourself :).'
    TORVERS="9.0.4"
    TORFILE="tor-browser-linux64-${TORVERS}_en-US.tar.xz"
    cd ${HOME_DIR}
    # Double check the link is right if this fails...
    wget --progress=bar https://www.torproject.org/dist/torbrowser/${TORVERS}/${TORFILE}
    if [[ $? -ge 1 ]]; then
        echo "Could not download TOR. Go to 'https://www.torproject.org/download/' to download and extract it manually\n"
    else
        tar -xvf tor-browser-linux64-${TORVERS}_en-US.tar.xz
        if [[ $? -ne 0 ]]; then
            echo -e "Could not extract the file '$(pwd)/tor-browser-linux64-${TORVERS}_en-US.tar.xz'\nPlease do so manually with the following command."
            echo -e "tar -xvf tor-browser-linux64-${TORVERS}_en-US.tar.xz"
        else
            rm -f ${TORFILE}
            echo -e "Tor has been downloaded to '$(pwd)'. Call it directly in shell or put it in a \$PATH dir to open the program."
        fi
    fi
    echo "# Change Password and you also need to install samba if this fails - sudo dnf install samba" >> ${HOME_DIR}/.bashrc
    echo -e "#sudo mount -t cifs -o username=${NAS_USER},password=${NAS_PASS},vers=1.0 //10.0.0.3/Samis_Folder /mnt/NAS/Samis_folder/" >> ${HOME_DIR}/.bashrc
fi

#################
### LAMP TIME ###
#################

sestatus | grep 'SELinux status' | grep -qi enabled
if [[ ! $? -ge 1 ]]; then
    setenforce 0
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

if [[ $INSTALL_COMMAND =~ (dnf|yum) ]]; then
    # Do installs
    $INSTALL_COMMAND -y install httpd php php-cli php-php-gettext php-mbstring php-mcrypt php-mysqlnd php-pear php-curl php-gd php-xml php-bcmath php-zip mariadb-server
    $INSTALL_COMMAND -y groupinstall "Development tools" && $INSTALL_COMMAND -y install php-devel autoconf automake

    # Configure Apache
    echo "Installing and configuring Apache..."
    mv /etc/httpd/conf/httpd.conf{,.old}
    cp $SCRIPT_DIR/configs/httpd.conf /etc/httpd/conf/httpd.conf
    mv /etc/httpd/conf.d/userdir.conf{,.old}
    cp $SCRIPT_DIR/configs/userdir.conf /etc/httpd/conf.d/userdir.conf
    chmod 711 ${HOME_DIR}
    systemctl start httpd
    systemctl enable httpd
    firewall-cmd --add-service={http,https} --permanent
    firewall-cmd --reload
    echo "You can find your website at 'http://localhost/~${REAL_USER}'."
    echo "You can pull your git repo's in here to work on them locally."

    # Do PHP
    echo "Installing and configuring PHP..."
    mv /etc/php.ini{,.old}
    cp $SCRIPT_DIR/configs/php.ini /etc/php.ini
    cp $SCRIPT_DIR/configs/info.php ${HOME_DIR}/git/
    systemctl reload httpd
    pecl install xdebug
    systemctl restart php-fpm

    # Do MariaDB
    echo "Installing and configuring MariaDB..."
    chown -R mysql. /var/lib/mysql
    mv /etc/my.cnf.d/mariadb-server.cnf{,.old}
    cp $SCRIPT_DIR/configs/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
    systemctl start mariadb
    systemctl enable mariadb
    firewall-cmd --add-service=mysql --permanent
    firewall-cmd --reload
    # In lieu of using mysql_secure_installation, this will require no prompt from user
    rootpass=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
    echo "[client]" > ${HOME_DIR}/.my.cnf
    echo "user=root" >> ${HOME_DIR}/.my.cnf
    echo "password=${rootpass}" >> ${HOME_DIR}/.my.cnf
    echo "Mysql root password stored in ${HOME_DIR}/.my.cnf"
    mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$rootpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF
elif [[ $INSTALL_COMMAND =~ apt ]]; then
    tasksel install lamp-server
    if [[ $? -ge 1 ]]; then
        $INSTALL_COMMAND -y install mysql-server mysql-client libmysqlclient-dev apache2 apache2-doc apache2-npm-prefork apache2-utils libexpat1 ssl-cert \
        libapache2-mod-php7.0 php7.0 php7.0-common php7.0-curl php7.0-dev php7.0-gd php-pear php-imagick php7.0-mcrypt php7.0-mysql php7.0-ps php7.0-xsl phpmyadmin
    fi
    ufw allow in "Apache Full"
    a2enmod mpm_event
    systemctl restart apache2
else
    echo "Cannot install Lamp Stack on machine. This is due to unknown package manager or OS."
fi

##############################
### Setup bash environment ###
##############################

if [[ $(grep bash_alias ${HOME_DIR}/.bashrc | wc -l) -lt 2 ]]
then
    cat << EOF >> ${HOME_DIR}/.bashrc

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
    touch ${HOME_DIR}/.bash_aliases
fi

# .bashrc
cat << EOF >> ${HOME_DIR}/.bashrc

# SSH Stuff
eval \`ssh-agent\` &> /dev/null
ssh-add ~/.ssh/sami-openssh-private-key.ppk &> /dev/null
ssh-add ~/.ssh/SShakir-openssh-private-key &> /dev/null

EOF

# .bash_aliases
cat << EOF >> ${HOME_DIR}/.bash_aliases
alias hosts='sudo vim /etc/hosts'
alias ssh='ssh -oStrictHostKeyChecking=no'
alias crucial='ssh root@182.160.155.217'
alias dpded='ssh ded.somethinglikesami.net -p 7022'
alias reslack='pkill slack && slack'
alias gitpushall='echo -e "\n\$PWD\n------------------------\n" && git status && git add . && git commit -m "auto commit from \$(hostname)" && git push origin'
alias gitpullall='echo -e "\n\$PWD\n------------------------\n" && git status && git pull'
alias traceroute='sudo traceroute -I'
alias fireth3cookie='(firefox -P th3cookie &> /dev/null &disown)'
alias firework='(firefox -P Work &> /dev/null &disown)'
alias ss='sudo ss'
alias systemctl='sudo systemctl'
alias copy='xclip -sel clip'
alias spotify='spotify &'
EOF

. ${HOME_DIR}/.bash_aliases
. ${HOME_DIR}/.bashrc

##############
### Others ###
##############

# Installing local rpm's
cd ${HOME_DIR}/Downloads/
sudo dnf localinstall slack-* code-*

cp $SCRIPT_DIR/configs/.vimrc ${HOME_DIR}/

# Configuring Snapd
systemctl start snapd.service
systemctl start snapd.service

# Installing spotify
snap install spotify

eval `ssh-agent` &> /dev/null
ssh-add ${HOME_DIR}/.ssh/sami-openssh-private-key.ppk

cd ${HOME_DIR}/git
git config --global user.name "${GIT_USERNAME}"
git config --global user.email "${GIT_EMAIL}"

git clone git@github.com:th3cookie/StudyScripts.git
git clone git@github.com:th3cookie/sysadmin_scripts.git
git clone git@github.com:th3cookie/Website_Dev.git

echo "Please install NVIDIA Graphics drivers if you have an NVIDIA card -> https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/"