#!/bin/bash


####################################################################################################################
#
#This script installs the referenced prometheus tar into a /opt/prometheus directory, creates a 'prometheus' user
#and installs prometheus as a service.
#It must be run with root privilages
#
#Created by James Bain
#Date 4/2/22
#
###################################################################################################################

#Set the tarfile variable based on user input
tarfile=$1

#Create a working directory to hold the files until they are moved into /opt/prometheus
mkdir work

#Untar the referenced tar into the working directory
tar -xvf $tarfile -C work

#Create the prometheus directory and move the install into there
mkdir /opt/prometheus
mv work/prometheus*/* /opt/prometheus

#Create the prometheus user with no login
useradd --no-create-home --shell /bin/false prometheus

#Copy the prometheus and promtool binary to /usr/local/bin
cp /opt/prometheus/prometheus /usr/local/bin
cp /opt/prometheus/promtool /usr/local/bin

#Make the promethus user the owner of the /opt/prometheus directory and the prometheus and promtool binary
chown -R prometheus:prometheus /opt/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

#Create the service file in /etc/systemd/system
echo '
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
	--config.file /opt/prometheus/prometheus.yml \
	--storage.tsdb.path /opt/prometheus/ \
	--storage.tsdb.retention.size 2GB

[Install]
WantedBy=multi-user.target' > /etc/systemd/system/prometheus.service

#Reload the systemd service to register the new prometheus service 
systemctl daemon-reload

#Finally, clean up the work directory
rm -rf work
