#!/bin/bash

# Read user input and store in variables
echo "Please enter your sudo password..."
sudo echo "Thank you. Continuing..."

# If no sudo - quit
if [[ $? -eq 1 ]]
then
    echo "Incorrect sudo password, cannot continue. Exiting..."
    exit 1
fi

read -p 'Is this a work desktop [Y/y]? ' WORKPC

if [[ ! ${WORKPC} =~ [Yy] ]]; then
    # Comment the below if the user is different
    NAS_USER=admin
    # Uncomment he below for user input instead
    # read -p 'NAS Username: ' NAS_USER
    read -sp 'NAS Password: ' NAS_PASS
fi

# Getting things ready
PS3='Please enter your choice: '
options=("Fedora/CentOS" "Ubuntu" "Quit")
echo "Please select your OS:"
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
            echo "You have chosen to quit this program, exiting..."
            exit 0
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

# Creating dir structure and properties
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GIT_DIR=~/git
sudo mkdir $GIT_DIR
chown -R $USER:$USER $GIT_DIR
chmod 755 $GIT_DIR
mkdir -p ~/work /mnt/NAS/Samis_folder

# Installing required packages
$INSTALL_COMMAND update
$INSTALL_COMMAND upgrade
$INSTALL_COMMAND install -y cifs-utils openvpn facter ruby python3.8 firefox git bash-completion vim pip npm curl wget telnet shellcheck xclip
if [[ $? -ne 0 ]]; then
    echo "Could not download some/all of the packages, please check package manager history."
fi

##################
### Work Stuff ###
##################

if [[ ${WORKPC} =~ [Yy] ]]; then
    $INSTALL_COMMAND install -y sipcalc
    if [[ $? -ne 0 ]]; then
        echo "Could not download some/all of the work packages, please check package manager history."
    fi
fi

# If not a work PC...
# VPN to connect to work network -> https://sslvpn01.digitalpacific.com.au:942/?src=connect
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

#################
### LAMP TIME ###
#################

sestatus | grep 'SELinux status' | grep -qi enabled
if [[ ! $? -ge 1 ]]; then
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
fi

if [[ $INSTALL_COMMAND =~ (dnf|yum) ]]; then
    # Do installs
    sudo $INSTALL_COMMAND -y install httpd php php-cli php-php-gettext php-mbstring php-mcrypt php-mysqlnd php-pear php-curl php-gd php-xml php-bcmath php-zip mariadb-server
    sudo $INSTALL_COMMAND -y groupinstall "Development tools" && yum install php-devel autoconf automake

    # Configure Apache
    echo "Installing and configuring Apache..."
    sudo mv /etc/httpd/conf/httpd.conf{,.old}
    sudo cp $SCRIPT_DIR/configs/httpd.conf /etc/httpd/conf/httpd.conf
    sudo mv /etc/httpd/conf.d/userdir.conf{,.old}
    sudo cp $SCRIPT_DIR/configs/userdir.conf /etc/httpd/conf.d/userdir.conf
    chmod 711 ~
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo firewall-cmd --add-service={http,https} --permanent
    sudo firewall-cmd --reload
    echo "You can find your website at 'http://localhost/~${USER}'."
    echo "You can pull your git repo's in here to work on them locally."

    # Do PHP
    echo "Installing and configuring PHP..."
    sudo mv /etc/php.ini{,.old}
    sudo cp $SCRIPT_DIR/configs/php.ini /etc/php.ini
    sudo cp $SCRIPT_DIR/configs/info.php ~/git/
    sudo systemctl reload httpd
    sudo pecl install xdebug
    sudo systemctl restart php-fpm

    # Do MariaDB
    echo "Installing and configuring MariaDB..."
    sudo mv /etc/my.cnf.d/mariadb-server.cnf{,.old}
    sudo cp $SCRIPT_DIR/configs/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
    mysql_secure_installation
    sudo systemctl start mariadb
    sudo systemctl enable mariadb
    sudo firewall-cmd --add-service=mysql --permanent
    sudo firewall-cmd --reload
    sudo rm -rf /var/lib/mysql
    sudo mkdir /var/lib/mysql
    sudo mkdir /var/lib/mysql/mysql
    sudo chown -R mysql:mysql /var/lib/mysql
    sudo mysql_install_db
    # In lieu of using mysql_secure_installation, this will require no prompt from user
    rootpass=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
    echo "[client]" > ~/.my.cnf
    echo "user=root" >> ~/.my.cnf
    echo "password=${rootpass}" >> ~/.my.cnf
    echo "Mysql root password stored in ~/.my.cnf"
    mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('$rootpass') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
FLUSH PRIVILEGES;
EOF
elif [[ $INSTALL_COMMAND =~ apt ]]; then
    sudo tasksel install lamp-server
    if [[ $? -ge 1 ]]; then
        sudo $INSTALL_COMMAND -y install mysql-server mysql-client libmysqlclient-dev apache2 apache2-doc apache2-npm-prefork apache2-utils libexpat1 ssl-cert \
        libapache2-mod-php7.0 php7.0 php7.0-common php7.0-curl php7.0-dev php7.0-gd php-pear php-imagick php7.0-mcrypt php7.0-mysql php7.0-ps php7.0-xsl phpmyadmin
    fi
    sudo ufw allow in "Apache Full"
    sudo a2enmod mpm_event
    sudo systemctl restart apache2
else
    echo "Cannot install Lamp Stack on machine. This is due to unknown package manager or OS."
fi

##############################
### Setup bash environment ###
##############################

if [[ $(grep bash_alias ~/.bashrc | wc -l) -lt 2 ]]
then
    cat << EOF >> ~/.bashrc

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
    touch ~/.bash_aliases
fi

# .bashrc
cat << EOF
eval `ssh-agent` &> /dev/null
ssh-add ~/.ssh/sami-openssh-private-key.ppk &> /dev/null
ssh-add ~/.ssh/SShakir-openssh-private-key &> /dev/null

# Change Password and you also need to install samba if this fails - sudo dnf install samba
EOF >> ~/.bashrc
echo -e "#sudo mount -t cifs -o username=${NAS_USER},password=${NAS_PASS},vers=1.0 //10.0.0.3/Samis_Folder /mnt/NAS/Samis_folder/" >> ~/.bashrc

# .bash_aliases
cat << EOF
alias dnf='sudo dnf'
alias apt='sudo apt'
alias yum='sudo yum'
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
alias ovpn='sudo openvpn --config ~/work/hostopia.ovpn &'
alias ss='sudo ss'
alias systemctl='sudo systemctl'
alias copy='xclip -sel clip'
EOF >> ~/.bash_aliases

##############
### Others ###
##############

sudo cp $SCRIPT_DIR/configs/.vimrc ~/