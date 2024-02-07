#!/bin/bash
#
# +-------------------------------------------------------+
# | This script is distributed under the CeCILL-A License |
# |                                                       |
# |   Ce script est distributé sous la licence CeCILL-A   |
# +-------------------------------------------------------+
#
# +-------------------------------------------------------+
# |                     AUTHOR/AUTEUR                     |
# |                                                       |
# |                  Sylvain BOUTEILLER                   |
# +-------------------------------------------------------+
#
# SCRIPT DE DESINSTALLATION D'OPENDIODE
#
# Doit être exécuté avec l'utilisateur root

# Usage ./uninstall.sh <nic_internet> <nic_input> <nic_output> <nic_admin>

version="0.2.00"

usage () {
  echo "Usage: $0 <internet_nic> <input_nic> <output_nic> <admin_nic>"
}

clear
echo "Removing OpenDiode..."
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

rm -rf /var/log/opendiode

systemctl enable shorewall
systemctl start shorewall

dnf remove dkms --assumeyes

dnf remove kernel-desktop-devel kernel-desktop-devel-5.10.16-1.mga8 --assumeyes

dnf remove wget --assumeyes

dnf remove sshpass --assumeyes

rm /home/opendiode/vbox.run

echo "       -> Cleaning vm1 (1/4)"
sudo -u opendiode vboxmanage controlvm vm1 poweroff
sudo -u opendiode vboxmanage unregistervm vm1 --delete
sudo -u opendiode VBoxManage hostonlyif remove vboxnet0
echo "       -> Cleaning vm2 (2/4)"
sudo -u opendiode vboxmanage controlvm vm2 poweroff
sudo -u opendiode vboxmanage unregistervm vm2 --delete
sudo -u opendiode VBoxManage hostonlyif remove vboxnet1
echo "       -> Cleaning vm3 (3/4)"
sudo -u opendiode vboxmanage controlvm vm3 poweroff
sudo -u opendiode vboxmanage unregistervm vm3 --delete
echo "       -> Cleaning vm4 (4/4)"
sudo -u opendiode vboxmanage controlvm vm4 poweroff
sudo -u opendiode vboxmanage unregistervm vm4 --delete
sudo -u opendiode VBoxManage hostonlyif remove vboxnet2

dnf remove VirtualBox-*

systemctl stop sshd
systemctl disable sshd
dnf remove openssh-server --assumeyes

echo > /var/spool/cron/opendiode

echo > /etc/motd

ifdown $internet_nic
ifdown $input_nic
ifdown $output_nic
ifdown $admin_nic

echo "DEVICE=\"$internet_nic\"" > /etc/sysconfig/network-scripts/ifcfg-$internet_nic
echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-$internet_nic
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$internet_nic

echo "DEVICE=\"$input_nic\"" > /etc/sysconfig/network-scripts/ifcfg-$input_nic
echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-$input_nic
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$input_nic

echo "DEVICE=\"$output_nic\"" > /etc/sysconfig/network-scripts/ifcfg-$output_nic
echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-$output_nic
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$output_nic

echo "DEVICE=\"$admin_nic\"" > /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "BOOTPROTO=\"dhcp\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic
echo "ONBOOT=\"yes\"" >> /etc/sysconfig/network-scripts/ifcfg-$admin_nic

ifup $internet_nic
ifup $input_nic
ifup $output_nic
ifup $admin_nic

echo
echo "Uninstallation successful!"
echo
echo "OpenDiode installation and uninstallation files are remaining in /home/opendiode"
echo "You can delete them if you do not want to reinstall OpenDiode"
echo
echo "Command : rm -rf /home/opendiode/*"