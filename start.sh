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
# SCRIPT DE DEMARRAGE DES MACHINES VIRTUELLES
#
# Doit être exécuté avec l'utilisateur opendiode

version="0.2.00"

sleep 3

log_file="/var/log/opendiode/run.log"

#echo "Starting Virtual Machines (VMs): it might last several minutes"
#echo "-> vm1"
vboxmanage startvm vm1 --type headless &>> $log_file
#echo "-> vm2"
vboxmanage startvm vm2 --type headless &>> $log_file
sleep 5
#echo "-> vm3"
vboxmanage startvm vm3 --type headless &>> $log_file
sleep 5
#echo "-> vm4"
vboxmanage startvm vm4 --type headless &>> $log_file

#echo "VMs successfully started!"
