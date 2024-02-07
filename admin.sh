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
# SCRIPT D'ADMINISTRATION D'OPENDIODE
#

# Ce script remplace le shell par défaut de l'utilisateur opendiode, pour configurer la diode de façon plus efficace.
# Doit être exécuté avec l'utilisateur opendiode

# Usage ./admin.sh

version="0.2.00"

title () {
  echo "OpenDiode administration interface"
  echo "Version $version from 2023 02 08"
}

schema () {
  ip=`grep 'admin_ip' /home/opendiode/config | sed 's/^.* //'`
  port=`grep 'admin_ssh_port' /home/opendiode/config | sed 's/^.* //'`
  echo "          +-------+     +------------+     +------------+     +--------+"
  echo "10.0.1.12 | INPUT |---->| Firewall 1 |---->| Firewall 2 |---->| OUTPUT | 10.0.2.11"
  echo "          +-------+     +------------+     +------------+     +--------+"
  echo "          10.101.0.1      10.102.0.1         10.103.0.1       10.104.0.1"
  echo "            (SSH)           (SSH)              (HTTPS)           (SSH)      "
  echo
  echo "This host is available from the admin network via SSH at $ip:$port with user \"opendiode\"."
}

main_options () {
  echo " [MAIN MENU]"
  echo
  echo " 1) Configure VM1 (input)                   5) Configure host"
  echo " 2) Configure VM2 (firewall 1 - NetFilter)  6) Shutdown system"
  echo " 3) Configure VM3 (firewall 2 - PfSense)    7) Shell"
  echo " 4) Configure VM4 (output)                  "
  echo
  echo -ne "Enter an option (1-7): "
}

header () {
  clear
  title
  echo
  schema
  echo
}

admin_ip () {
  ip=`grep 'admin_ip' /home/opendiode/config | sed 's/^.* //'`
  netmask=`grep 'admin_netmask' /home/opendiode/config | sed 's/^.* //'`
  nic=`grep 'admin_nic' /home/opendiode/config | sed 's/^.* //'`
  echo "Current admin IP: $ip"
  echo "Current admin netmask: $netmask"
  echo
  echo -ne "Enter new IP address (ex: 10.103.0.200): "
  read new_ip
  
  sed -i "s/admin_ip $ip/admin_ip $new_ip/" /home/opendiode/config
  echo "[1/4] Enter root password:"
  su root -c "sed -i 's/IPADDR=\"$ip\"/IPADDR=\"$new_ip\"/' /etc/sysconfig/network-scripts/ifcfg-$nic"
  echo "[2/4] Enter root password:"
  su root -c "sed -i 's/ListenAddress $ip/ListenAddress $new_ip/' /etc/ssh/sshd_config"

  echo -ne "Enter new netmask (ex: 255.255.255.0): "
  read new_netmask
  
  sed -i "s/admin_netmask $netmask/admin_netmask $new_netmask/" /home/opendiode/config
  echo "[3/4] Enter root password:"
  su root -c "sed -i 's/NETMASK=\"$netmask\"/NETMASK=\"$new_netmask\"/' /etc/sysconfig/network-scripts/ifcfg-$nic"
  
  echo "[4/4] Enter root password:"
  su root -c "ifdown $nic && ifup $nic && systemctl restart sshd"
  
  #echo "[4/5] Enter root password:"
  #su root -c "ifdown $nic"
  #echo "[5/5] Enter root password:"
  #su root -c "ifup $nic"
  #systemctl restart sshd
  
  host_config
}

ssh_port () {
  port=`grep 'admin_ssh_port' /home/opendiode/config | sed 's/^.* //'`
  echo "Current SSH port: $port"
  echo
  new_port=0
  while [ $new_port -lt 1 -o $new_port -gt 65535 ]
  do
    echo -ne "Enter new port value (1-65535): "
    read new_port
    if ! [[ $new_port =~ ^[0-9]+$ ]];
      then
      new_port=0
    fi
  done
  
  sed -i "s/admin_ssh_port $port/admin_ssh_port $new_port/" /home/opendiode/config
  echo "Enter root password to confirm new SSH port ($new_port)"
  su root -c "sed -i 's/Port $port/Port $new_port/' /etc/ssh/sshd_config"
  systemctl restart sshd
  host_config
}

opendiode_passwd () {
  echo "Enter root password then new password for opendiode:"
  su root -c "passwd opendiode"
  sleep 2
  host_config
}

root_passwd () {
  echo "Enter current root password then new root password:"
  su root -c "passwd root"
  sleep 2
  host_config
}

clear_logs () {
  echo > /var/log/opendiode/install.log
  echo > /var/log/opendiode/run.log
  echo > /var/log/opendiode/stop.log
  host_config
}

host_options () {
  echo " [HOST CONFIGURATION]"
  echo
  echo " 1) Change host admin IP                    5) Clear logs"
  echo " 2) Change host SSH port                    6) Main menu"
  echo " 3) Change opendiode password"
  echo " 4) Change root password                  "
  echo
  echo -ne "Enter an option (1-6): "
}

host_config () {
  option=0
  while [ $option -lt 1 -o $option -gt 6 ]
  do
    header
	host_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      admin_ip
    ;;
    2)
      ssh_port
    ;;
    3)
      opendiode_passwd
    ;;
    4)
      root_passwd
    ;;
    5)
      clear_logs
    ;;
    6)
      main_menu
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  host_config
}

vm_options () {
  echo " [VM CONFIGURATION]"
  echo
  echo " 1) Change user password"
  echo " 2) Change root password"
  echo " 3) Main menu"
  echo
  echo -ne "Enter an option (1-3): "
}

vm3_options () {
  ip=`grep 'admin_ip' /home/opendiode/config | sed 's/^.* //'`
  nic=`grep 'admin_nic' /home/opendiode/config | sed 's/^.* //'`
  echo " [VM CONFIGURATION]"
  echo
  echo " This VM is only configurable via its WEB interface."
  echo " It is available at $ip:443 from the NIC $nic."
  echo
  echo " 1) Main menu"
  echo
  echo -ne "Enter an option (1-3): "
}

vm1_config () {
  option=0
  while [ $option -lt 1 -o $option -gt 3 ]
  do
    header
	echo " [VM1 = INPUT]"
    vm_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      ./change_vm_passwd.sh onlyuser 10.101.0.1 share
    ;;
    2)
      ./change_vm_passwd.sh onlyroot 10.101.0.1 share
    ;;
    3)
      main_menu
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  vm1_config
}

vm2_config () {
  option=0
  while [ $option -lt 1 -o $option -gt 3 ]
  do
    header
	echo " [VM2 = Firewall 1 (NetFilter)]"
    vm_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      ./change_vm_passwd.sh onlyuser 10.102.0.1 user
    ;;
    2)
      ./change_vm_passwd.sh onlyroot 10.102.0.1 user
    ;;
    3)
      main_menu
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  vm2_config
}

vm3_config () {
  option=0
  while [ $option -lt 1 -o $option -gt 1 ]
  do
    header
	echo " [VM3 = Firewall 2 (PfSense)]"
    vm3_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      main_menu
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  vm3_config
}

vm4_config () {
  option=0
  while [ $option -lt 1 -o $option -gt 3 ]
  do
    header
	echo " [VM4 = OUTPUT]"
    vm_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      ./change_vm_passwd.sh onlyuser 10.104.0.1 share
    ;;
    2)
      ./change_vm_passwd.sh onlyroot 10.104.0.1 share
    ;;
    3)
      main_menu
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  vm4_config
}

main_menu () {
  option=0
  while [ $option -lt 1 -o $option -gt 7 ]
  do
    header
    main_options
    read option
	if ! [[ $option =~ ^[0-9]+$ ]];
	then
	  option=0
	fi
  done
  
  case $option in

    1)
      vm1_config
    ;;
    2)
      vm2_config
    ;;
    3)
      vm3_config
    ;;
    4)
      vm4_config
    ;;
    5)
      host_config
    ;;
    6)
      echo "Shutting down system."
	  /home/opendiode/stop.sh
	  echo "Enter root password to poweroff the machine:"
      su root -c "poweroff"
    ;;
    7)
      /bin/bash
    ;;
    *)
      # We should not enter here anyway
      main_menu
    ;;
  esac
  main_menu
}

main_menu

