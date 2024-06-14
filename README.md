# Install odoo 17 
## Prerequisites

-   A  Linux server with Ubuntu 22.04 and at least 2GB of RAM
-   User privileges: root or non-root user with sudo privileges

## How to Install Odoo 17: Step 1. Update the System

Every fresh installation of Ubuntu 22.04 needs the packages to be updated to the latest versions available. To do that, execute the following command:

    sudo apt-get update -y && sudo apt-get upgrade -y

## Step 2. Install Python and Required Libraries

Before we start with the installation, we need to install some dependencies for PostgreSQL and Odoo itself.

    sudo apt-get install -y python3-pip python3-dev python3-venv libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev libatlas-base-dev -y

## Step 3. Install NPM and CSS plugins

Once the dependencies are installed, we will install package management for the JavaScript programming language:

    sudo apt-get install -y npm
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo npm install -g less less-plugin-clean-css
    sudo apt-get install -y node-less

## Step 4. Install Wkhtmltopdf

In this step we will install the  `Wkhtmltopdf`  command line tool, used for converting HTML pages to PDF files. Run these three commands one by one:

    sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
    sudo dpkg -i wkhtmltox_0.12.6-1.bionic_amd64.deb
    sudo apt install -f

## Step 5. Install PostgreSQL

Step by step, we are getting closer to the Odoo installation. Before we install Odoo, we will need to install the PostgreSQL service which is responsible for storing Odoo’s data.

    sudo apt-get install postgresql -y

Once installed, start and enable the PostgreSQL service.

    sudo systemctl start postgresql && sudo systemctl enable postgresql

To check the status execute the following command:

    sudo systemctl status postgresql

You should receive the following output:

    root@host:/# sudo systemctl status postgresql
    ● postgresql.service - PostgreSQL RDBMS
         Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
         Active: active (exited) since Thu 2023-11-23 03:42:11 CST; 18s ago
       Main PID: 20712 (code=exited, status=0/SUCCESS)
            CPU: 3ms
    
    Nov 23 03:42:11 host.test.vps systemd[1]: Starting PostgreSQL RDBMS...
    Nov 23 03:42:11 host.test.vps systemd[1]: Finished PostgreSQL RDBMS.

## Step 6. Create Odoo and PostgreSQL users

Next we will create Odoo and PostgreSQL users. To create the Odoo user, execute the following command:

    useradd -m -U -r -d /opt/odoo17 -s /bin/bash odoo17
    
    Set the user password for  `odoo17`:
    
    passwd odoo17
    New password: **YourStrongPasswordHere**
    Retype new password: **YourStrongPasswordHere**
    passwd: password updated successfully

Make sure to replace  `YourStrongPasswordHere`  with a strong password. To create a PostgreSQL user, execute the following command:

    sudo su - postgres -c "createuser -s odoo17"

## Step 7. Install and Configure Odoo 17

First log in as the Odoo user and clone the latest version of Odoo in the  `/opt/`  directory:

    su - odoo17
    
    git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo17/odoo17
    
    Next, activate the Python virtual environment and begin installing the Odoo requirements.
    
    cd /opt/odoo17
    
    python3 -m venv odoo17-venv
    
    source odoo17-venv/bin/activate
    
    pip install --upgrade pip
    
    pip3 install wheel
    
    pip3 install -r odoo17/requirements.txt

Once done, deactivate the environment and create the Odoo add-on directories and Odoo log file.

    deactivate
    
    mkdir /opt/odoo17/odoo17-custom-addons
    
    chown -R odoo17:odoo17 /opt/odoo17/odoo17-custom-addons
    
    sudo mkdir -p /var/log/odoo17
    
    sudo touch /var/log/odoo17.log
    
    sudo chown -R odoo17:odoo17 /var/log/odoo17

## Step 8. Create Odoo 17 configuration file

Next we need to create the configuration file for Odoo’s configuration.

    sudo touch /etc/odoo17.conf

Open the configuration file with your favorite editor and paste the following lines of code, remembering to change  `YourStrongPasswordHere`  to a strong password:

    [options]
    admin_passwd = YourStrongPasswordHere
    db_host = False
    db_port = False
    db_user = odoo17
    db_password = False
    xmlrpc_port = 8069
    logfile = /var/log/odoo17/odoo17.log
    addons_path = /opt/odoo17/odoo17/addons,/opt/odoo17/odoo17-custom-addons 

Save the file and close it.

## Step 9. Create an Odoo systemd unit file

We now need a Systemd service unit file in order to control our Odoo instance more easily. This lets us easily start, stop and set Odoo to run on system boot. To create the Odoo systemd unit file, execute the following command:

    sudo touch /etc/systemd/system/odoo17.service

Open the systemd unit file with your preferred text editor and paste the following lines of code:

    [Unit]
    Description=odoo17
    After=network.target postgresql@14-main.service
    
    [Service]
    Type=simple
    SyslogIdentifier=odoo17
    PermissionsStartOnly=true
    User=odoo17
    Group=odoo17
    ExecStart=/opt/odoo17/odoo17-venv/bin/python3 /opt/odoo17/odoo17/odoo-bin -c /etc/odoo17.conf
    StandardOutput=journal+console
    
    [Install]
    WantedBy=multi-user.target

Reload the daemon, then start and enable the Odoo service:

    sudo systemctl daemon-reload

    sudo systemctl start odoo17 && sudo systemctl enable odoo17

To check the status of the service, execute the command below:

    sudo systemctl status odoo17

You should get the following output:

    root@host:~# sudo systemctl status odoo17
    ● odoo17.service - odoo17
         Loaded: loaded (/etc/systemd/system/odoo17.service; enabled; vendor preset: enabled)
         Active: active (running) since Thu 2023-11-23 06:34:36 CST; 6s ago
       Main PID: 44663 (python3)
          Tasks: 4 (limit: 4558)
         Memory: 72.0M
            CPU: 2.406s
         CGroup: /system.slice/odoo17.service
                 └─44663 /opt/odoo17/odoo17-venv/bin/python3 /opt/odoo17/odoo17/odoo-bin -c /etc/odoo17.conf
    
    Nov 23 06:34:36 host.test.vps systemd[1]: Started odoo17.

As you can see, the service is up and running. To access your Odoo website, you need to access your server’s IP address in your web browser on port  **8069**.

http://YourServerIPAddress:8069

Congratulations! You successfully installed Odoo 17 on Ubuntu 22.04. Now you can install modules, add your personal details and get your business up and running through Odoo.
