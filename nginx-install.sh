#!/bin/bash

# Update the package repository
sudo apt-get update

# Install NGINX
sudo apt-get install nginx -y

# Start NGINX
sudo service nginx start

