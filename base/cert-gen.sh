#!/usr/bin/env bash

# Specify where we will install
# the biogen.com certificate
SSL_DIR="/etc/nginx/ssl"

# Set the wildcarded domain
# we want to use
DOMAIN="*.biogen.com"

# A blank passphrase
PASSPHRASE=""

# Set our CSR variables
SUBJ="
C=US
ST=Berlin
O=
localityName=Berlin
commonName=$DOMAIN
organizationalUnitName=
emailAddress=
"

# Create our SSL directory
# in case it doesn't exist
sudo mkdir -p "$SSL_DIR"

# Generate our Private Key, CSR and Certificate
sudo openssl genrsa -out "$SSL_DIR/biogen.com.key" 4096
sudo openssl req -new -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key "$SSL_DIR/biogen.com.key" -out "$SSL_DIR/biogen.com.csr" -passin pass:$PASSPHRASE
sudo openssl x509 -req -days 365 -in "$SSL_DIR/biogen.com.csr" -signkey "$SSL_DIR/biogen.com.key" -out "$SSL_DIR/biogen.com.crt"