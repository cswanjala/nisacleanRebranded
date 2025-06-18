#!/bin/bash

# Update package list
sudo apt-get update

# Install Nginx
sudo apt-get install nginx -y

# Install certbot for SSL
sudo apt-get install certbot python3-certbot-nginx -y

# Copy our Nginx configuration
sudo cp nginx.conf /etc/nginx/nginx.conf

# Test Nginx configuration
sudo nginx -t

# If the test is successful, restart Nginx
if [ $? -eq 0 ]; then
    sudo systemctl restart nginx
    echo "Nginx has been installed and configured successfully!"
else
    echo "There was an error in the Nginx configuration. Please check the error messages above."
fi

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Get SSL certificate (uncomment and modify the domain when ready)
# sudo certbot --nginx -d nisaclean.com -d www.nisaclean.com 