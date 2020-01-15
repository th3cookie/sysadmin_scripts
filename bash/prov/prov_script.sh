#!/bin/bash
# Things to check before running:
# Xampp link - Search "XAMPP_LINK"

GIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Please enter your sudo password..."
sudo echo "Thank you. Continuing..."

# If no sudo - quit
if [[ $? -eq 1 ]]
then
    exit 1
fi

if [[ -x $(command -v apt) ]]; then
    INSTALL_COMMAND=$(command -v apt)
    INSTALL_METHOD="apt"
elif [[ -x $(command -v yum) ]]; then
    INSTALL_COMMAND=$(command -v yum)
    INSTALL_METHOD="yum"
elif [[ -x $(command -v dnf) ]]; then
    INSTALL_COMMAND=$(command -v dnf)
    INSTALL_METHOD="dnf"
else
    echo "Cannot determine package manager, exiting..."
    exit 1
fi

# Read user input and store in variables
# Comment the below if the user is different
NAS_USER=admin
# Uncomment he below for user input instead
# read -p 'NAS Username: ' NAS_USER
read -sp 'NAS Password: ' NAS_PASS
read -p 'Is this a work desktop [Y/y]? ' WORKPC

# Setup bash environment
if [[ $(grep bash_alias .bashrc | wc -l) -eq 0 ]]
then
    cat << EOF
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF >> ~/.bashrc
    touch ~/.bash_aliases
fi

# Creating dir structure
mkdir -p ~/git ~/work /mnt/NAS/Samis_folder

# Installing required packages
$INSTALL_COMMAND update
$INSTALL_COMMAND upgrade
$INSTALL_COMMAND install -y cifs-utils openvpn facter ruby python3.8 firefox git bash-completion vim pip npm curl wget telnet
if [[ $? -ne 0 ]]; then
    echo "Could not download some/all of the packages, please check package manager history."
fi

# Install further packages for work
if [[ ${WORKPC} =~ [Yy] ]]; then
    $INSTALL_COMMAND install -y sipcalc
    if [[ $? -ne 0 ]]; then
        echo "Could not download some/all of the work packages, please check package manager history."
    fi
fi

# If not a work PC...
if [[ ! ${WORKPC} =~ [Yy] ]]; then
    # Downloading files from NAS
    sudo mount -t cifs -o username=${NAS_USER},password=${NAS_PASS},vers=1.0 //10.0.0.3/Samis_Folder /mnt/NAS/Samis_folder/
    if [[ $? -ne 0 ]]; then
        echo -e "Could not download openvpn profile and SSH keys from NAS.\nCheck if you can mount cifs or not."
    else
        cp /mnt/NAS/Samis_Folder/hostopia.ovpn ~/work
        cp /mnt/NAS/Samis_Folder/ssh_keys/sami-openssh-private-key.ppk ~/.ssh/sami-openssh-private-key.ppk
        cp /mnt/NAS/Samis_Folder/ssh_keys/Work/SShakir-openssh-private-key ~/.ssh/SShakir-openssh-private-key
    fi
    echo -e 'Downloading tor. It then needs to be extracted and placed in a $PATH directory to be able to start.'
    echo -e 'If TOR Fails to download, do it yourself :).'
    TORVERS='9.0.4'
    cd ~
    # Double check the link is right if this fails...
    wget --progress=bar https://www.torproject.org/dist/torbrowser/${TORVERS}/tor-browser-linux64-${TORVERS}_en-US.tar.xz
    if [[ $? -ge 1 ]]; then
        echo "Could not download TOR. Go to 'https://www.torproject.org/download/' to download and extract it manually\n"
    else
        tar -xvf tor-browser-linux64-${TORVERS}_en-US.tar.xz
        if [[ $? -ne 0 ]]; then
            echo -e "Could not extract the file '$(pwd)/tor-browser-linux64-${TORVERS}_en-US.tar.xz'\nPlease do so manually with the following command."
            echo -e "tar -xvf tor-browser-linux64-${TORVERS}_en-US.tar.xz"
        else
            echo -e "Tor has been downloaded to '$(pwd)'. Call it directly in shell or put it in a \$PATH dir to open the program."
        fi
    fi
fi

##################
### Work Stuff ###
##################
# VPN -> https://sslvpn01.digitalpacific.com.au:942/?src=connect

#################
### LAMP TIME ###
#################

sestatus | grep 'SELinux status' | grep -qi enabled
if [[ ! $? -ge 1 ]]; then
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

if [[ $INSTALL_METHOD =~ (dnf|yum) ]]; then
    # Do installs
    sudo $INSTALL_COMMAND -y install httpd php php-cli php-php-gettext php-mbstring php-mcrypt php-mysqlnd php-pear php-curl php-gd php-xml php-bcmath php-zip mariadb-server

    # Configure Apache
    sudo mv /etc/httpd/conf/httpd.conf{,.old}
    sudo cp $GIT_DIR/configs/httpd.conf /etc/httpd/conf/httpd.conf
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo firewall-cmd --add-service={http,https} --permanent
    sudo firewall-cmd --reload

    # Do PHP
    sudo mv /etc/php.ini{,.old}
    sudo cp $GIT_DIR/configs/php.ini /etc/php.ini
    sudo cp $GIT_DIR/configs/info.php /var/www/html/
    sudo systemctl reload httpd

    # Do MariaDB
    ### THIS ONE NEEDS WORK, I CAN'T GET MARIADB WORKING ON FEDORA 31... ###
    sudo mv /etc/my.cnf.d/mariadb-server.cnf{,.old}
    sudo cp $GIT_DIR/configs/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
    mysql_secure_installation
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
    sudo firewall-cmd --add-service=mysql --permanent
    sudo firewall-cmd --reload
elif [[ $INSTALL_METHOD =~ apt ]]; then
    sudo tasksel install lamp-server
    if [[ $? -ge 1 ]]; then
        sudo $INSTALL_COMMAND -y install mysql-server mysql-client libmysqlclient-dev apache2 apache2-doc apache2-npm-prefork apache2-utils libexpat1 ssl-cert \
        libapache2-mod-php7.0 php7.0 php7.0-common php7.0-curl php7.0-dev php7.0-gd php-pear php-imagick php7.0-mcrypt php7.0-mysql php7.0-ps php7.0-xsl phpmyadmin
    fi
    sudo ufw allow in "Apache Full"
    sudo a2dismod mpm_event
    sudo a2enmod mpm_prefork
    sudo systemctl restart apache2
else
    echo "Cannot install Lamp Stack on machine. This is due to unknown package manager or OS."
fi

###############
### .bashrc ###
###############

cat << EOF
eval `ssh-agent` &> /dev/null
ssh-add ~/.ssh/sami-openssh-private-key.ppk &> /dev/null
ssh-add ~/.ssh/SShakir-openssh-private-key &> /dev/null

# Change Password and you also need to install samba if this fails - sudo dnf install samba
EOF >> ~/.bashrc
echo -e "sudo mount -t cifs -o username=${NAS_USER},password=${NAS_PASS},vers=1.0 //10.0.0.3/Samis_Folder /mnt/NAS/Samis_folder/" >> ~/.bashrc

#####################
### .bash_aliases ###
#####################

cat << EOF
alias dnf='sudo dnf'
alias apt='sudo apt'
alias yum='sudo yum'
alias hosts='sudo vim /etc/hosts'
alias ssh='ssh -oStrictHostKeyChecking=no'
alias xstart='sudo /opt/lampp/lampp start'
alias xstop='sudo /opt/lampp/lampp stop'
alias crucial='ssh root@182.160.155.217'
alias dpded='ssh ded.somethinglikesami.net -p 7022'
alias reslack='pkill slack && slack'
alias gitpushall='echo -e "\n$PWD\n------------------------\n" && git status && git add . && git commit -m "auto commit from $(hostname)" && git push origin'
alias gitpullall='echo -e "\n$PWD\n------------------------\n" && git status && git pull'
alias traceroute='sudo traceroute -I'
alias fireth3cookie='(firefox -P th3cookie &> /dev/null &disown)'
alias firework='(firefox -P Work &> /dev/null &disown)'
alias ovpn='sudo openvpn --config ~/work/hostopia.ovpn &'
alias xampp='sudo /opt/lampp/lampp'
EOF >> ~/.bash_aliases

##############
### Others ###
##############

# Deprecated Xampp install - Going LAMP instead - Like a pro sysadmin should..
# cd ~/Downloads/
# XAMPP_LINK="https://www.apachefriends.org/xampp-files/7.4.1/xampp-linux-x64-7.4.1-0-installer.run"
# XAMPP_RET=$?
# XAMPP_FILE=$(echo "${XAMPP_LINK}" | awk -F "/" '{print $NF}')
# echo "Downloading '${XAMPP_FILE}'"
# wget $XAMPP_LINK
# if [[ $? -ge 1 ]]; then
#     echo "Could not download Xampp using the following wget command:"
#     echo "${XAMPP_LINK}"
#     echo "Please check the link and install it manually. Skipping it..."
# else
#     echo "Installing '${XAMPP_FILE}'"
#     chmod +x $XAMPP_FILE
#     sudo ./$XAMPP_FILE &disown
#     echo "Please finish the Xampp installation using the GUI installer."
#     # Xampp fix for fedora/RHEL machines to get apache working
#     sudo ln -s /lib64/libnsl.so.2 /lib64/libnsl.so.1
# fi