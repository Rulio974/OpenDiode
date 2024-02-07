#!/bin/bash
#
# +-------------------------------------------------------+
# | This script is distributed under the CeCILL-A License |
# |                                                       |
# |   Ce script est distributé sous la licence CeCILL-A   |
# +------------------------------------------------------ +
#
# +-------------------------------------------------------+
# |                     AUTHOR/AUTEUR                     |
# |                                                       |
# |                  Sylvain BOUTEILLER                   |
# +-------------------------------------------------------+
#
# SCRIPT D'EXTINCTION DES MACHINES VIRTUELLES
#
# Doit être exécuté avec l'utilisateur opendiode

version="0.2.00"



log_file="/var/log/opendiode/stop.log"

echo "Stopping Virtual Machines (VMs): it might last several minutes"
echo "-> vm1"
vboxmanage controlvm vm1 poweroff &>> $log_file
echo "-> vm2"
vboxmanage controlvm vm2 poweroff &>> $log_file
echo "-> vm3"
vboxmanage controlvm vm3 poweroff &>> $log_file
echo "-> vm4"
vboxmanage controlvm vm4 poweroff &>> $log_file

echo "VMs successfully stopped!"
