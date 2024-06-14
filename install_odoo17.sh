#!/bin/bash

# Step 1: Update the System
sudo apt-get update -y && sudo apt-get upgrade -y

# Step 2: Install Python and Required Libraries
sudo apt-get install -y python3-pip python3-dev python3-venv \
    libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev \
    build-essential libssl-dev libffi-dev libmysqlclient-dev \
    libjpeg-dev libpq-dev libjpeg8-dev liblcms2-dev libblas-dev \
    libatlas-base-dev -y

# Step 3: Install NPM and CSS plugins
sudo apt-get install -y npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less

# Step 4: Install Wkhtmltopdf
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo apt install -f

# Step 5: Install PostgreSQL
sudo apt-get install postgresql -y
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Step 6: Create Odoo and PostgreSQL users
sudo useradd -m -U -r -d /opt/odoo17 -s /bin/bash odoo17
sudo passwd odoo17  # Set password for Odoo user
sudo su - postgres -c "createuser -s odoo17"

# Step 7: Install and Configure Odoo 17
sudo su - odoo17
git clone https://www.github.com/odoo/odoo --depth 1 --branch 17.0 /opt/odoo17/odoo17
cd /opt/odoo17
python3 -m venv odoo17-venv
source odoo17-venv/bin/activate
pip install --upgrade pip
pip3 install wheel
pip3 install -r odoo17/requirements.txt
deactivate
mkdir /opt/odoo17/odoo17-custom-addons
chown -R odoo17:odoo17 /opt/odoo17/odoo17-custom-addons
sudo mkdir -p /var/log/odoo17
sudo touch /var/log/odoo17/odoo17.log
sudo chown -R odoo17:odoo17 /var/log/odoo17

# Step 8: Create Odoo 17 configuration file
sudo touch /etc/odoo17.conf
sudo nano /etc/odoo17.conf

# Paste the following configuration and save the file (adjust passwords as needed):
cat <<EOF | sudo tee /etc/odoo17.conf
[options]
admin_passwd = YourStrongPasswordHere
db_host = False
db_port = False
db_user = odoo17
db_password = False
xmlrpc_port = 8069
logfile = /var/log/odoo17/odoo17.log
addons_path = /opt/odoo17/odoo17/addons,/opt/odoo17/odoo17-custom-addons
EOF

# Step 9: Create an Odoo systemd unit file
sudo touch /etc/systemd/system/odoo17.service
sudo nano /etc/systemd/system/odoo17.service

# Paste the following systemd unit file content and save the file:
cat <<EOF | sudo tee /etc/systemd/system/odoo17.service
[Unit]
Description=odoo17
After=network.target postgresql.service

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
EOF

# Reload systemd and start Odoo 17
sudo systemctl daemon-reload
sudo systemctl start odoo17
sudo systemctl enable odoo17

# Check Odoo 17 service status
sudo systemctl status odoo17
