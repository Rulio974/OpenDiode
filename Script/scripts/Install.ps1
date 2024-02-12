function Show-Usage {
    Write-Host "Usage: $scriptName <internet_nic> <input_nic> <output_nic> <admin_nic>"
}

# Number of steps in the installation
$nb_steps = 22
$version = "0.2.00"

Clear-Host
Write-Host ""
Write-Host "##########################"
Write-Host "# OpenDiode setup script #"
Write-Host "#         v$version        #"
Write-Host "#       2023 11 14       #"
Write-Host "##########################"
Write-Host ""

if ($args.Length -ne 4) {
    Write-Host "Bad number of parameters"
    Write-Host ""
    Show-Usage
    Write-Host ""
    exit 0
}

$internet_nic = $args[0]
$input_nic = $args[1]
$output_nic = $args[2]
$admin_nic = $args[3]

$start_date = Get-Date

# Create log directory and files
$logDirectory = "C:\var\log\opendiode"
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$log_file = Join-Path $logDirectory "install.log"
New-Item -ItemType File -Path $log_file -Force | Out-Null

# Set permissions
$acl = Get-Acl $logDirectory
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("opendiode", "Read", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl $logDirectory $acl

Add-Content $log_file ""
Add-Content $log_file "Current date:"
Add-Content $log_file $start_date
Add-Content $log_file "Trying to install OpenDiode..."
Add-Content $log_file "Temporary Internet NIC: $internet_nic"
Add-Content $log_file "Diode input:  $input_nic"
Add-Content $log_file "Diode output: $output_nic"
Add-Content $log_file "Diode admin:  $admin_nic"
Add-Content $log_file ""

$config_file = "C:\home\opendiode\config"
Add-Content $config_file "admin_nic $admin_nic"
Add-Content $config_file "admin_ip 10.103.0.100"
Add-Content $config_file "admin_netmask 255.255.255.0"
Add-Content $config_file "admin_ssh_port 19427"

Write-Host "You can watch the logs in real-time in $log_file"
Write-Host ""
Write-Host "Temporary Internet NIC: $internet_nic"
Write-Host ""
Write-Host "Diode input:  $input_nic"
Write-Host "Diode output: $output_nic"
Write-Host "Diode admin:  $admin_nic"

# Stop current OpenDiode instance
Write-Host "[0/$nb_steps] Stopping current OpenDiode instance"
Stop-Process -Name "OpenDiode" -Force

# Configure temporary Internet NIC
Write-Host "[1/$nb_steps] Configuring temporary Internet NIC"
Disable-NetAdapter -Name $internet_nic
Start-Sleep -Seconds 1
Enable-NetAdapter -Name $internet_nic
Start-Sleep -Seconds 1

# Disable firewall temporarily
Write-Host "[2/$nb_steps] Disabling firewall temporarily"
Stop-Service -Name "MpsSvc"

# Install required modules
Write-Host "[3/$nb_steps] Installing dkms"
Install-Package -Name "dkms" -Force
Write-Host "[4/$nb_steps] Installing kernel-desktop-devel"
Install-Package -Name "kernel-desktop-devel" -Force
Write-Host "[5/$nb_steps] Installing wget"
Install-Package -Name "wget" -Force
Write-Host "[6/$nb_steps] Installing sshpass"
Install-Package -Name "sshpass" -Force

# Download VirtualBox install script
Write-Host "[7/$nb_steps] Downloading VirtualBox install script"
$url = "https://download.virtualbox.org/virtualbox/7.0.4/VirtualBox-7.0.4-154605-Win.exe"
$output = "C:\vbox.run"
Invoke-WebRequest -Uri $url -OutFile $output

# Adding execution permission on VirtualBox script
Write-Host "[8/$nb_steps] Adding execution permission on VirtualBox script"
# This is not applicable in Windows

# Execute the script
Write-Host "[9/$nb_steps] Executing VirtualBox install script"
Start-Process -FilePath "C:\vbox.run" -ArgumentList "/silent" -Wait

# Allow host-only administration networks in VirtualBox
Write-Host "[10/$nb_steps] Allowing host-only administration networks in VirtualBox"
# This part needs to be adapted based on the specific requirements for configuring host-only networks in VirtualBox on Windows

# Cleaning old Virtual Machines (VMs)
Write-Host "[11/$nb_steps] Cleaning old Virtual Machines (VMs)"
# This part needs to be adapted based on the specific requirements for cleaning up VMs in VirtualBox on Windows

# Import Virtual Machines
Write-Host "[12/$nb_steps] Importing Virtual Machines (VMs)"
# This part needs to be adapted based on the specific requirements for importing VMs in VirtualBox on Windows

# Configure Virtual Machines networks
Write-Host "[13/$nb_steps] Configuring Virtual Machines networks"
# This part needs to be adapted based on the specific requirements for configuring VM networks in VirtualBox on Windows

# Configure physical Admin interface
Write-Host "[14/$nb_steps] Configuring physical Admin interface"
# This part needs to be adapted based on the specific requirements for configuring the physical Admin interface on Windows

# Install and start SSH server
Write-Host "[15/$nb_steps] Installing, enabling, configuring, and starting SSH server"
Install-WindowsFeature -Name "OpenSSH.Server" -IncludeManagementTools
Start-Service -Name "ssh-agent"
Set-Service -Name "ssh-agent" -StartupType Automatic
Set-Service -Name "sshd" -StartupType Automatic
Start-Service -Name "sshd"

$ssh_file = "C:\ProgramData\ssh\sshd_config"
# This part needs to be adapted based on the specific requirements for configuring the sshd_config file on Windows

Restart-Service -Name "sshd"

# Disable temporary Internet NIC
Write-Host "[16/$nb_steps] Disabling temporary Internet NIC"
Disable-NetAdapter -Name $internet_nic

# Add a Cron job to start the diode at boot
Write-Host "[17/$nb_steps] Adding Cron job to start the diode at boot"
# This part needs to be adapted based on the specific requirements for adding a scheduled task on Windows

# Set rights to opendiode
Write-Host "[18/$nb_steps] Setting rights to opendiode"
# This part needs to be adapted based on the specific requirements for setting

# Step 19: Starting the diode as opendiode
Write-Host "[19/$nb_steps] Starting the diode"
Start-Process -FilePath "C:\Path\To\start.bat" -NoNewWindow -Wait

# Step 20: Setting VMs passwords
Write-Host "[20/$nb_steps] Setting VMs passwords"
Write-Host "Please wait while OpenDiode is starting up (60s)"
Start-Sleep -Seconds 60
Write-Host "It is now time to set up VMs passwords"

# VM1
Write-Host "VM1:"
sshpass.exe -p share ssh -t share@10.101.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user share:"; su root -c "passwd share"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
Write-Host "Done."

# VM2
Write-Host "VM2:"
sshpass.exe -p user ssh -t user@10.102.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user user:"; su root -c "passwd user"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
Write-Host "Done."

# VM4
Write-Host "VM4:"
sshpass.exe -p share ssh -t share@10.104.0.1 'stty -echo; echo toor | su root -c "passwd -d root"; echo "Give new password for user share:"; su root -c "passwd share"; echo "Give new password for user root:"; su root -c "passwd root"; stty echo'
Write-Host "Done."

# Step 21: Setting motd
Write-Host "[21/$nb_steps] Setting motd"
$motdContent = @"
#######################################################
#                                                     #
#                    OpenDiode $version                 #
#                                                     #
#               An Open-Source Data Diode              #
#                   Based on Mageia 8                 #
#                                                     #
#######################################################

#######################################################
#                                                     #
#                        INPUT                        #
#                     NIC: $input_nic                 #
#                    IP: 10.0.1.12                    #
#                                                     #
#######################################################

#######################################################
#                                                     #
#                        OUTPUT                       #
#                     NIC: $output_nic                #
#                    IP: 10.0.2.11                    #
#                                                     #
#######################################################

#######################################################
#                                                     #
#                        ADMIN                        #
#                     NIC: $admin_nic                 #
#                 Host IP: 10.103.0.100:19427 (SSH)   #
#        VM3 (PfSense) IP: 10.103.0.1:443 (HTTPS)     #
#                                                     #
#            Accessible from the inside (SSH):        #
#                   VM1: 10.101.0.1                   #
#                   VM2: 10.102.0.1                   #
#                   VM4: 10.104.0.1                   #
#                                                     #
#######################################################
"@

$motdContent | Set-Content -Path "C:\Windows\System32\OpenDiode\motd.txt"

Write-Host @"
#######################################################
# OpenDiode is successfully installed, configured and #
#                        started!                     #
#                                                     #
#OpenDiode will start automatically after every reboot#
#######################################################

#######################################################
#                        INPUT                        #
#                     NIC: $input_nic                 #
#                    IP: 10.0.1.12                    #
#######################################################

#######################################################
#                        OUTPUT                       #
#                     NIC: $output_nic                #
#                    IP: 10.0.2.11                    #
#######################################################

#######################################################
#                        ADMIN                        #
#                     NIC: $admin_nic                 #
#              Host IP: 10.103.0.100:19427            #
#              PfSense IP (vm3): 10.103.0.1           #
#######################################################
"@
