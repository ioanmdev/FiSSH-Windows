#!/bin/bash

echo "FiSSH Installation Script for WINDOWS SUBSYSTEM FOR LINUX"
echo "------------------------------------------------------------"
echo
read -p "Please enter installation drive letter (for example C): " drive
drive=$(echo $drive | tr '[:upper:]' '[:lower:]')
echo "Installing on $drive"
echo "It is recommended to use BitLocker drive encryption, or just encrypt the FiSSH folder."
echo
echo "Installing OpenSSL (if not installed)"
apt-get install openssl
echo
echo "Setting up directories"
mkdir -v -p /mnt/$drive/FiSSH
echo
echo "Downloading FiSSH.exe for x64"
wget https://gitlab.com/ioanm/fissh-windows/raw/master/Release/FiSSH.exe -O /mnt/$drive/FiSSH/FiSSH.exe
echo
echo "Creating /usr/bin/fissh"
cat > /usr/bin/fissh << EOL
#!/bin/bash
if [ -d /mnt/$drive/FiSSH ]; then
        export DISPLAY=:0
        export SSH_ASKPASS="/mnt/$drive/FiSSH/FiSSH.exe"
        setsid ssh "\$@"
else
        echo "FiSSH can NOT be found. Make sure that the drive is accessible!"
fi
EOL
chmod 555 /usr/bin/fissh
echo
echo "---------------------------------------------------------------------"
echo "WARNING: THE FOLLOWING SECURITY CHECK NEEDS TO BE PERFORMED MANUALLY!"
echo "---------------------------------------------------------------------"
echo
echo "Open $drive:\\FiSSH and right click the FiSSH.exe file and go to properties. Then click on Digital Signatures. Make SURE the signature says \"Moldovan Alexandru. Ioan Intreprindere Individuala\" and is validated by \"SSL.com Root Certification Authority RSA\". Make SURE the signature is trusted. This ensures the file's integrity"
echo
digsignok="UNKNOWN"
while [[ "$digsignok" != "YES" ]]; do
	read -p "Have you validated the Digital Signature? (respond with yes or no UPPERCASE): " digsignok

	if [[ "$digsignok" == "NO" ]]; then
		rm -f /mnt/$drive/FiSSH -r
		echo "FATAL ERROR! FiSSH was corrupted!"
		exit 1
	elif [[ "$digsignok" == "YES" ]]; then
		echo "OKAY! GREAT!"
	else
		echo "INVALID RESPONSE!"
	fi
done
echo
echo "Generating certificate"
password=$(openssl rand -base64 32)
openssl genrsa -aes256 -out /tmp/fissh.key -passout pass:$password 4096
openssl req -x509 -key /tmp/fissh.key -out /tmp/fissh.crt -days 3650 -subj '/CN=FiSSH' -passin pass:$password
echo
echo "Exporting PFX"
openssl pkcs12 -export -out /mnt/$drive/FiSSH/FiSSH.pfx -inkey /tmp/fissh.key -in /tmp/fissh.crt -passin pass:$password -passout pass:$password

if [[ $? -eq 0 ]]; then
	echo "SUCCESS!!!!"
	echo
	echo "------------"
	echo "IMPORTANT"
	echo "------------"
	echo
	echo "For FiSSH to FUNCTION you need to navigate to /mnt/$drive/FiSSH and double click on FiSSH.pfx and install it in the PERSONAL certificate store of your USER. DO NOT INSTALL FOR THE WHOLE MACHINE"
	echo
	echo "YOUR INSTALLATION PASSWORD IS: $password"
	echo
	echo "After you are done just run 'fissh'"
	echo
	echo "ALSO YOU SHOULD DELETE FiSSH.pfx after installation. DO NOT KEEP the PFX."
	shred -n 10 -z -x -u /tmp/fissh.crt
	shred -n 10 -z -x -u /tmp/fissh.key
else
	echo "Install has failed."
	rm -r -f /mnt/$drive/FiSSH
	shred -n 10 -z -x -u /tmp/fissh.crt
	shred -n 10 -z -x -u /tmp/fissh.key
	rm -f /usr/bin/fissh

	exit 1
fi


