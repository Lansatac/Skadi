#!/bin/bash
tempdir=$(mktemp -d)
buildskadi_tgz="$tempdir/buildskadi.tgz"
pubkey="LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUF5c2E1MHRJUkNsZm56VVNYeE9zeQpkRTcxUlFXendsajJ1cHFLaHEyVlJtem9HRVdQSWllZ1NDUGtGUEJKUXZlVnFLN3JqdGJxaUF4aElwZ3lWS052CkF5M3pMMGNPcmFEUXYySUs1R0t0SWhqVkltZWw0cXQzc1QrWDBvWUxOTWhtMHRrSUxqWW52aUZjU1lEY1hIbzAKa0Z1WUhTOXdPRjY5d3ZiZWpXTldpOUZjMmZvVWxPL1dFK0g0QitRTUtxRitjZlVXUUFKM3ZYMVNuTmV3bDMwRgpFQkdWV3oxWkszNXgyaGgxamlRdVNIdzIrbXNZc2wxcC85dlkyOFVMZmg0bEJwRFVPcHA0aU1LSUpDRS84SmpKCndWLzFNTjZYWjBNUFI3U1Q2VVk2TmhHVG1oUFVkV0pjUW1wOVg2cjV6a1MzZ2tGNzNnN01oUFo1NTMyTCt1Q3AKUG4raUtUbGorNHpGM2o5c1Z1Y0p5TnZMMEx2QnZjZDhXbUNPMFhIS0RRY1MxQTF2M3p5MVlZRVdzb0xVSWZMaApVajlFcFEyMzh2bWlscW1WdXZjRnRxaFJsbFBUV3dEcEFtOW5aTlFnaUVKNjBzbHVUUVNEVzNhYjA0Y2ZLZldJCmt3aDc4bUUxNnIzem0yNnRaMUN6ZTBPVzNKdFNPbVpDc3dicis4RDU0ZVZmaUZya01LdnZ0K1ErVWU4UjZyeVQKUWJIZThSWnZJeTZvMXdPNDEwZUJnQ3pVV1BkR3ZiQzRxVHJFdG5MdXBzOXZYV2xFa0dzNUUvbjdWdTZWcldJYwpVdlQwLzErS1VXNFlWSEFtME1BOFRGS21EcnQ5dHBqaXVDRUZ2OURXVFV2NXVVYk8yTFd2WXlCK2F0cVpRaWYwCmVhQTV5ZzZyOUNnbmNXQS95TEp3TFZjQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo="
buildskadi_pem="$tempdir/buildskadi.pem"
buildskadi_sig="$tempdir/buildskadi.sig"
buildskadi_sh="$tempdir/signedbuildskadi.sh"
update_sh="$tempdir/update.sh"

# Verify wget is installed and attempt to install it if it is missing
which wget > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Warning: wget is not installed. Attempting to install wget"
  sudo apt install wget -y
  if [ $? -ne 0 ]; then
    echo "ERROR: Unable to install wget. Exiting"
    rm -rf $tempdir
    exit 1
  fi
fi

# Download install file and verify it was successful
wget -O $buildskadi_tgz --quiet https://raw.githubusercontent.com/orlikoski/skadi/master/scripts/buildskadi.tgz 
if [ $? -ne 0 ]; then
  echo "ERROR: Download was not successful. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Download signature file and verify it was successful
wget -O $buildskadi_sig --quiet https://raw.githubusercontent.com/orlikoski/skadi/master/scripts/buildskadi.sig
if [ $? -ne 0 ]; then
  echo "ERROR: Download was not successful. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Verify openssl is installed and attempt to install it if it is missing
which openssl > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Warning: openssl is not installed. Attempting to install openssl"
  sudo apt install -y openssl
  if [ $? -ne 0 ]; then
    echo "ERROR: Unable to install openssl. Exiting"
    rm -rf $tempdir
    exit 1
  fi
fi

# Verify installation files using openssl
echo $pubkey |base64 -d > $buildskadi_pem
verify=$(openssl dgst -sha256 -verify $buildskadi_pem -signature $buildskadi_sig $buildskadi_tgz)

if [ "$verify" == "Verified OK" ]; then
  echo "OpenSSL digital signature verified; launching installation"
  echo ""
  echo ""
else
  echo "ERROR: Unable to verify installation file. Exiting"
  rm -rf $tempdir
  exit 1
fi

# Extract verified installation file and execute it
tar xzf $buildskadi_tgz -C $tempdir
chmod +x $buildskadi_sh
$buildskadi_sh

# Remove all files associated with build
rm -rf $tempdir
exec bash
