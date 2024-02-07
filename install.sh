#!/bin/bash
#
# +-------------------------------------------------------+
# | This script is distributed under the CeCILL-A License |
# |                                                       |
# |   Ce script est distributé sous la licence CeCILL-A   |
# +-------------------------------------------------------+
#
# +-------------------------------------------------------+
# |                    AUTHORS/AUTEURS                    |
# |                                                       |
# |              Project Team/Equipe du Projet            |
# |                  Sylvain BOUTEILLER                   |
# |                   Damien SCHAEFFER                    |
# |                                                       |
# |             Project Leader/Chef de Projet             |
# |                Jean-François BELLANGER                |
# +-------------------------------------------------------+
#
# SCRIPT D'INSTALLATION ET DE CONFIGURATION D'OPENDIODE
#
# Penser à activer VT-X dans la configuration de la VM hôte Mageia (si OpenDiode est virtualisée) pour permettre à VirtualBox de fonctionner au sein de l'hôte
#
# Bien penser à configurer la NIC du PC admin distant sur 10.103.0.0/24 (mais pas avec l'IP 10.103.0.1 ni avec 10.103.0.100). Ex : 10.103.0.70/24
#
# Lancer ce script après l'installation minimale de Mageia 8 (donc sans GUI) dans "/home/opendiode/", à côté des fichiers d'OpenDiode (vm1.ova, ..., vm4.ova, start.sh, stop.sh, etc...).
# Pour cela, suivre la documentation.

# Usage ./install.sh <nic_internet> <nic_input> <nic_output> <nic_admin>

usage () {
  echo "Usage: $0 <internet_nic> <input_nic> <output_nic> <admin_nic>"
}

# Nombre d'étapes dans l'installation
nb_steps="22"
version="0.2.00"

clear
echo
echo "##########################"
echo "# OpenDiode setup script #"
echo "#         v$version        #"
echo "#       2023 02 08       #"
echo "##########################"
echo

if [ "$#" -ne 4 ]; then
  echo "Bad number of parameters"
  echo
  usage
  echo
  exit 0
fi

internet_nic=$1
input_nic=$2
output_nic=$3
admin_nic=$4

start_date=$(date)

mkdir /var/log/opendiode
touch /var/log/opendiode/install.log
touch /var/log/opendiode/run.log
touch /var/log/opendiode/stop.log
chown -R opendiode:opendiode /var/log/opendiode

log_file="/var/log/opendiode/install.log"
echo &>> $log_file
echo "Current date:" &>> $log_file
echo $start_date &>> $log_file
echo "Trying to install OpenDiode..." &>> $log_file
echo "Temporary Internet NIC: $internet_nic" &>> $log_file
echo "Diode input:  $input_nic" &>> $log_file
echo "Diode output: $output_nic" &>> $log_file
echo "Diode admin:  $admin_nic" &>> $log_file
echo &>> $log_file

config_file="/home/opendiode/config"
echo > $config_file
echo "admin_nic $admin_nic" >> $config_file
echo "admin_ip 10.103.0.100" >> $config_file
echo "admin_netmask 255.255.255.0" >> $config_file
echo "admin_ssh_port 19427" >> $config_file

echo "You can watch the logs in real time in $log_file"
echo
echo "Temporary Internet NIC: $internet_nic"
echo
echo "Diode input:  $input_nic"
echo "Diode output: $output_nic"
echo "Diode admin:  $admin_nic"
echo

# Stopper l'instance actuelle d'OpenDiode
echo "[0/$nb_steps] Stopping current OpenDiode instance"
sudo -u opendiode ./stop.sh &>> $log_file

# Récupérer une IP via DHCP pour l'accès à Internet
echo "[1/$nb_steps] Configuring temporary Internet NIC"
ifdown $internet_nic &>> $log_file
sleep 1
ifup $internet_nic &>> $log_file
sleep 1

# Désactiver le pare-feu
echo "[2/$nb_steps] Disabling firewall temporarily"
systemctl stop shorewall &>> $log_file
systemctl disable shorewall &>> $log_file


# Activer et installer les modules requis (tout accepter automatiquement)
echo "[3/$nb_steps] Installing dkms"
dnf install dkms --assumeyes &>> $log_file
echo "[4/$nb_steps] Installing kernel-desktop-devel"
dnf install kernel-desktop-devel kernel-desktop-devel-5.10.16-1.mga8 --assumeyes &>> $log_file
echo "[5/$nb_steps] Installing wget"
dnf install wget --assumeyes &>> $log_file
echo "[6/$nb_steps] Installing sshpass"
dnf install sshpass --assumeyes &>> $log_file

# Télécharger le script d'installation de VirtualBox
echo "[7/$nb_steps] Downloading VirtualBox install script"
if test -f "vbox.run"; then
echo "       -> vbox.run is already present - Downloading skipped"
else
  wget -O vbox.run https://download.virtualbox.org/virtualbox/7.0.4/VirtualBox-7.0.4-154605-Linux_amd64.run &>> $log_file
fi
# Ajouter les droits d'exécution sur le script
echo "[8/$nb_steps] Adding execution permission on VirtualBox script"
chmod u+x vbox.run &>> $log_file

# Exécuter le script
echo "[9/$nb_steps] Executing VirtualBox install script"
./vbox.run &>> $log_file
/sbin/vboxconfig &>> $log_file

# Autoriser les réseaux privés hôtes d'administration des VMS 1,2,4 pour VirtualBox
echo "[10/$nb_steps] Allowing host-only administration networks in VirtualBox"
echo "* 10.101.0.0/24 10.102.0.0/24 10.104.0.0/24" > /etc/vbox/networks.conf

# Arrêter puis supprimer les anciennes machines virtuelles
echo "[11/$nb_steps] Cleaning old Virtual Machines (VMs)"
echo "       -> Cleaning vm1 (1/4)"
sudo -u opendiode vboxmanage controlvm vm1 poweroff &>> $log_file
sudo -u opendiode vboxmanage unregistervm vm1 --delete &>> $log_file
sudo -u opendiode VBoxManage hostonlyif remove vboxnet0 &>> $log_file
echo "       -> Cleaning vm2 (2/4)"
sudo -u opendiode vboxmanage controlvm vm2 poweroff &>> $log_file
sudo -u opendiode vboxmanage unregistervm vm2 --delete &>> $log_file
sudo -u opendiode VBoxManage hostonlyif remove vboxnet1 &>> $log_file
echo "       -> Cleaning vm3 (3/4)"
sudo -u opendiode vboxmanage controlvm vm3 poweroff &>> $log_file
sudo -u opendiode vboxmanage unregistervm vm3 --delete &>> $log_file
echo "       -> Cleaning vm4 (4/4)"
sudo -u opendiode vboxmanage controlvm vm4 poweroff &>> $log_file
sudo -u opendiode vboxmanage unregistervm vm4 --delete &>> $log_file
sudo -u opendiode VBoxManage hostonlyif remove vboxnet2 &>> $log_file

# Importer les machines virtuelles
echo "[12/$nb_steps] Importing Virtual Machines (VMs): it might last several minutes"
echo "       -> Importing vm1    (1/4)"
sudo -u opendiode vboxmanage import vm1.ova &>> $log_file
echo "       -> Importing vm2    (2/4)"
sudo -u opendiode vboxmanage import vm2.ova &>> $log_file
echo "       -> Importing vm3    (3/4)"
sudo -u opendiode vboxmanage import vm3.ova &>> $log_file
echo "       -> Importing vm4    (4/4)"
sudo -u opendiode vboxmanage import vm4.ova &>> $log_file


# Configurer les interfaces réseau des VM
echo "[13/$nb_steps] Configuring Virtual Machines networks"
echo "        -> vm1 (1/4)"
sudo -u opendiode VBoxManage modifyvm "vm1" --nic1 bridged &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm1" --bridgeadapter1 $input_nic &>> $log_file

sudo -u opendiode VBoxManage modifyvm "vm1" --nic2 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm1" --intnet2 "intnet_vm1_vm2" &>> $log_file

sudo -u opendiode VBoxManage hostonlyif create &>> $log_file
sudo -u opendiode VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.101.0.100 --netmask 255.255.255.0 &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm1" --nic3 hostonly --hostonlyadapter3 vboxnet0 &>> $log_file


echo "        -> vm2 (2/4)"
sudo -u opendiode VBoxManage modifyvm "vm2" --nic1 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm2" --intnet1 "intnet_vm1_vm2" &>> $log_file

sudo -u opendiode VBoxManage modifyvm "vm2" --nic2 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm2" --intnet2 "intnet_vm2_vm3" &>> $log_file

sudo -u opendiode VBoxManage hostonlyif create &>> $log_file
sudo -u opendiode VBoxManage hostonlyif ipconfig vboxnet1 --ip 10.102.0.100 --netmask 255.255.255.0 &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm2" --nic3 hostonly --hostonlyadapter3 vboxnet1 &>> $log_file


echo "        -> vm3 (3/4)"
sudo -u opendiode VBoxManage modifyvm "vm3" --nic1 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm3" --intnet1 "intnet_vm2_vm3" &>> $log_file

sudo -u opendiode VBoxManage modifyvm "vm3" --nic2 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm3" --intnet2 "intnet_vm3_vm4" &>> $log_file

sudo -u opendiode VBoxManage modifyvm "vm3" --nic3 bridged &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm3" --bridgeadapter3 $admin_nic &>> $log_file


echo "        -> vm4 (4/4)"
sudo -u opendiode VBoxManage modifyvm "vm4" --nic1 intnet &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm4" --intnet1 "intnet_vm3_vm4" &>> $log_file

sudo -u opendiode VBoxManage modifyvm "vm4" --nic2 bridged &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm4" --bridgeadapter2 $output_nic &>> $log_file

sudo -u opendiode VBoxManage hostonlyif create &>> $log_file
sudo -u opendiode VBoxManage hostonlyif ipconfig vboxnet2 --ip 10.104.0.100 --netmask 255.255.255.0 &>> $log_file
sudo -u opendiode VBoxManage modifyvm "vm4" --nic3 hostonly --hostonlyadapter3 vboxnet2 &>> $log_file


# Configurer la carte réseau d'administration physique pour accéder à l'hôte à distance via SSH
echo "[14/$nb_steps] Configuring physical Admin interface"
echo "DEVICE=\"$admin_nic\"" > /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "BOOTPROTO=\"static\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "IPADDR=\"10.103.0.100\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "NETMASK=\"255.255.255.0\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic
ifdown $admin_nic &>> $log_file
ifup $admin_nic &>> $log_file


# Installer et activer le serveur SSH
echo "[15/$nb_steps] Installing, enabling, configuring and starting SSH server"
dnf install openssh-server --assumeyes &>> $log_file
systemctl enable sshd &>> $log_file
systemctl start sshd &>> $log_file

ssh_file="/etc/ssh/sshd_config"

echo > $ssh_file
echo "Include /etc/ssh/sshd_config.d/*.conf" >> $ssh_file
echo "Port 19427" >> $ssh_file
echo "ListenAddress 10.103.0.100" >> $ssh_file
echo "X11Forwarding no" >> $ssh_file
echo "IgnoreRhosts yes" >> $ssh_file
echo "PermitEmptyPasswords no" >> $ssh_file
echo "MaxAuthTries 3" >> $ssh_file
echo "PermitRootLogin no" >> $ssh_file
echo "Protocol 2" >> $ssh_file

systemctl restart sshd &>> $log_file

# Désactiver l'interface réseau temporaire pour l'accès à Internet
echo "[16/$nb_steps] Disabling temporary internet NIC"
ifdown $internet_nic &>> $log_file

# Ajouter une règle de Cron pour démarrer la diode en même temps que l'hôte
echo "[17/$nb_steps] Adding Cron job to start the diode at boot"
#(crontab -l 2>/dev/null; echo "@reboot /root/opendiode/start.sh") | crontab -
echo "@reboot /home/opendiode/start.sh" > /var/spool/cron/opendiode

# Rétablir les droits des fichiers d'OpenDiode à l'utilisateur opendiode
echo "[18/$nb_steps] Setting rights to opendiode"
chown -R opendiode:opendiode /home/opendiode &>> $log_file

# Démarrer la diode en tant que opendiode
echo "[19/$nb_steps] Starting the diode"
sudo -u opendiode ./start.sh &>> $log_file

# Changer les mots de passe des utilisateurs des VMs 1, 2 et 4
echo "[20/$nb_steps] Setting VMs passwords"
echo "Please wait while OpenDiode is starting up (60s)"
sleep 60
echo "It is now time to setup VMs passwords"
echo "VM1:"
sudo -u opendiode sshpass -p share ssh -t share@10.101.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user share:"; su root -c "passwd share"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
echo "Done."

echo "VM2:"
sudo -u opendiode sshpass -p user ssh -t user@10.102.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user user:"; su root -c "passwd user"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
echo "Done."

echo "VM4:"
sudo -u opendiode sshpass -p share ssh -t share@10.104.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user share:"; su root -c "passwd share"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
echo "Done."

# Ajouter un message à chaque connexion précisant le rôle de chaque interface 
echo "[21/$nb_steps] Setting motd"
echo > /etc/motd
echo "#######################################################" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#                    OpenDiode $version                 #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#               An Open-Source Data Diode" >> /etc/motd
echo "#                   Based on Mageia 8                 #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#######################################################" >> /etc/motd
echo >> /etc/motd
echo "#######################################################" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#                        INPUT                        #" >> /etc/motd
echo "#                     NIC: $input_nic" >> /etc/motd
echo "#                    IP: 10.0.1.12                    #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#######################################################" >> /etc/motd
echo >> /etc/motd
echo "#######################################################" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#                        OUTPUT                       #" >> /etc/motd
echo "#                     NIC: $output_nic" >> /etc/motd
echo "#                    IP: 10.0.2.11                    #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#######################################################" >> /etc/motd
echo >> /etc/motd
echo "#######################################################" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#                        ADMIN                        #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#                     NIC: $admin_nic" >> /etc/motd
echo "#                 Host IP: 10.103.0.100:19427 (SSH)   #" >> /etc/motd
echo "#        VM3 (PfSense) IP: 10.103.0.1:443 (HTTPS)     #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#            Accessible from the inside (SSH):        #" >> /etc/motd
echo "#                   VM1: 10.101.0.1                   #" >> /etc/motd
echo "#                   VM2: 10.102.0.1                   #" >> /etc/motd
echo "#                   VM4: 10.104.0.1                   #" >> /etc/motd
echo "#                                                     #" >> /etc/motd
echo "#######################################################" >> /etc/motd
echo >> /etc/motd

echo
echo "#######################################################"
echo "# OpenDiode is successfully installed, configured and #"
echo "#                        started!                     #"
echo "#                                                     #"
echo "#OpenDiode will start automatically after every reboot#"
echo "#######################################################"
echo
echo "#######################################################"
echo "#                        INPUT                        #"
echo "#                     NIC: $input_nic"
echo "#                    IP: 10.0.1.12                    #"
echo "#######################################################"
echo
echo "#######################################################"
echo "#                        OUTPUT                       #"
echo "#                     NIC: $output_nic"
echo "#                    IP: 10.0.2.11                    #"
echo "#######################################################"
echo
echo "#######################################################"
echo "#                        ADMIN                        #"
echo "#                     NIC: $admin_nic"
echo "#              Host IP: 10.103.0.100:19427            #"
echo "#              PfSense IP (vm3): 10.103.0.1           #"
echo "#######################################################"

# Remplacer le shell par défaut de l'utilisateur opendiode (/bin/bash) par le script d'administration d'OpenDiode (/home/opendiode/admin.sh)
echo "[22/$nb_steps] Replacing default shell for user opendiode"
sed -i "s/home\/opendiode:\/bin\/bash/home\/opendiode:\/home\/opendiode\/admin.sh/" /etc/passwd

end_date=$(date)
echo "OpenDiode is successfully installed!" &>> $log_file
echo "From $start_date to $end_date" &>> $log_file
echo &>> $log_file
