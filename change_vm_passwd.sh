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
# SCRIPT DE CHANGEMENT DE MOT DE PASSE DES MACHINES VIRTUELLES D'OPENDIODE
#

# Ce script est appelé par admin.sh
# Doit être exécuté en tant qu'utilisateur "opendiode"

# Usage ./change_vm_passwd.sh <mode> <vm_ip> <username>

usage () {
  echo "Usage: $0 onlyuser <vm_ip> <username>"
  echo "       $0 onlyroot <vm_ip> <username>"
  echo "       $0 both     <vm_ip> <username>"
}

if [ "$#" -ne 3 -a "$#" -ne 2 ]; then
  echo "Bad number of parameters"
  echo
  usage
  echo
  exit 0
fi

version="0.2.00"

mode=$1
ip=$2
user=$3

echo "Enter $user password:"
if [ "$mode" = "onlyroot" ]; then
  command="stty -echo; echo \"Give current root password then new root password:\"; su root -c \"passwd root\"; stty echo"
  ssh -t $user@$ip $command
elif [ "$mode" = "onlyuser" ]; then
  command="stty -echo; echo \"Give root password then new password for user $user:\"; su root -c \"passwd $user\"; stty echo"
  ssh -t $user@$ip $command
elif [ "$mode" = "both" ]; then
  command="stty -echo; echo \"Give root password then new password for user $user:\"; su root -c \"passwd $user\"; echo \"Give root password then new root password:\"; su root -c \"passwd root\"; stty echo"
  ssh -t $user@$ip $command
fi

