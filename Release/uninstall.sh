#!/bin/bash
echo "Uninstalling FiSSH completely"
rm -v -r -f /mnt/*/FiSSH
rm -v -f /tmp/fissh.crt
rm -v -f /tmp/fissh.key
rm -v -f /usr/bin/fissh
echo
echo "Also delete your FiSSH certificate from Manage user certificates!"
echo


