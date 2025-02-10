#!/bin/bash

# Check if a URL is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

# Extract the domain name from the URL
URL="$1"
DOMAIN=$(echo "$URL" | awk -F[/:] '{print $4}')
if [ -z "$DOMAIN" ]; then
  DOMAIN="$URL"
fi

# Define paths
VHOST_DIR="/var/www/html/vhosts/$DOMAIN"
VHOST_CONF="/etc/httpd/conf.d/vhosts.conf"
LOGS_DIR="/var/log/httpd/vhosts"

# Create the directory for the virtual host
sudo mkdir -p "$VHOST_DIR"
sudo chown -R apache:apache "$VHOST_DIR"
sudo chmod -R 755 "$VHOST_DIR"

# Create index.html
sudo bash -c "cat > $VHOST_DIR/index.html <<EOF
<html>
  <head>
    <title>Welcome to $DOMAIN</title>
  </head>
  <body>
    <h1>Welcome to $DOMAIN!</h1>
    <p>This is the default page for $DOMAIN.</p>
  </body>
</html>
EOF"

# Create custom_403.html
sudo bash -c "cat > $VHOST_DIR/custom_403.html <<EOF
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>You do not have permission to access this resource on $DOMAIN.</p>
    <p>contact thibaut.beck@student.kuleuven.be.</p>

  </body>
</html>
EOF"

# Create logs directory if it doesn't exist
sudo mkdir -p "$LOGS_DIR"

# Add the VirtualHost configuration to vhosts.conf
sudo bash -c "cat >> $VHOST_CONF <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMAIN
    DocumentRoot "$VHOST_DIR"
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    ErrorLog "$LOGS_DIR/${DOMAIN}_error.log"
    CustomLog "$LOGS_DIR/${DOMAIN}_access.log" combined

    <Directory "$VHOST_DIR">
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorDocument 403 /custom_403.html
</VirtualHost>
EOF"

# Restart Apache to apply changes
sudo systemctl restart httpd

echo "Virtual host for $DOMAIN has been created successfully!"
echo "Document root: $VHOST_DIR"
echo "Configuration added to $VHOST_CONF"

