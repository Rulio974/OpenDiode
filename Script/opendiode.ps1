Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$playImagePath = Join-Path -Path $scriptPath -ChildPath ".\images\play.png"
$stopImagePath = Join-Path -Path $scriptPath -ChildPath ".\images\stop.png"
$externalImagePath = Join-Path -Path $scriptPath -ChildPath ".\images\external_link.png"
$passwordImagePath = Join-Path -Path $scriptPath -ChildPath ".\images\password.png"

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$formWidth = $screen.Width * 0.8
$formHeight = $screen.Height * 0.8

# Créez un objet ToolTip
$tooltip = New-Object Windows.Forms.ToolTip

function Resize-Image($imagePath, $width, $height) {
    $originalImage = [System.Drawing.Image]::FromFile($imagePath)
    $resizedImage = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
    $graphics.DrawImage($originalImage, 0, 0, $width, $height)
    $graphics.Dispose()
    return $resizedImage
}

$form = New-Object Windows.Forms.Form
$form.Text = "OpenDiode Control Panel"
$form.AutoScale = $true
$form.Size = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.StartPosition = "CenterScreen"
$form.BackColor = "white"

#$buttonContainer = New-Object Windows.Forms.Panel
#$buttonContainer.Location = [System.Drawing.Point]::new(0, 0)
#$buttonContainer.Size = [System.Drawing.Size]::new(200, $form.Height)
#$form.Controls.Add($buttonContainer)

$buttonWidth = 150
$buttonHeight = 50
$buttonMargin = 20
$buttonActions = @{
    "Install" = { $textbox.AppendText("Action: Installation`r`n") }
    "Uninstall" = { $textbox.AppendText("Action: Uninstall`r`n") }
}

$i = 0
foreach ($buttonName in $buttonActions.Keys) {
    $button = New-Object Windows.Forms.Button
    $button.Location = [System.Drawing.Point]::new(($buttonWidth + $buttonMargin) * $i + $buttonMargin, 10)
    $button.Size = [System.Drawing.Size]::new($buttonWidth, $buttonHeight)
    $button.Text = $buttonName
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $button.BackColor = [System.Drawing.Color]::DodgerBlue
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.Add_Click($buttonActions[$buttonName])
    $form.Controls.Add($button)
    $i++
}

$textbox = New-Object Windows.Forms.TextBox
$textbox.Multiline = $true
$textbox.ScrollBars = "Vertical"
$textbox.ReadOnly = $true
$textbox.Location = [System.Drawing.Point]::new(10, $buttonHeight + $buttonMargin)
$textbox.Size = [System.Drawing.Size]::new($form.Width - 30, $form.Height - ($buttonHeight + $buttonMargin) - 230)
$form.Controls.Add($textbox)


$vmStatusPanel = New-Object Windows.Forms.FlowLayoutPanel
$vmStatusPanel.Location = [System.Drawing.Point]::new(20, $form.Height - 200)
$vmStatusPanel.Size = [System.Drawing.Size]::new($form.Width - 230, 150)
$vmStatusPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$form.Controls.Add($vmStatusPanel)

function CreateVmStatusPanel($vmName, $vmIP, $vmUser, $vmProtocol) {
    $panel = New-Object Windows.Forms.Panel
    $panel.Size = [System.Drawing.Size]::new($vmStatusPanel.Width, 30)
    $vmStatusPanel.Controls.Add($panel)

    $vmStatusLabel = New-Object Windows.Forms.Label
    $vmStatusLabel.AutoSize = $true
    $vmStatusLabel.Text = "${vmName}: Checking..."
    $vmStatusLabel.Location = [System.Drawing.Point]::new(5, 3)
    $panel.Controls.Add($vmStatusLabel)

    # Bouton Connect
    $connectionButton = New-Object Windows.Forms.Button
    $connectionButton.Size = [System.Drawing.Size]::new(15, 15)
    $externalresizedImage = Resize-Image -imagePath $externalImagePath -width 15 -height 15
    $connectionButton.Image = $externalresizedImage
    $connectionButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $connectionButton.FlatAppearance.BorderSize = 0
    $connectionButton.Location = [System.Drawing.Point]::new(95, 0)
    $connectionButton.Tag = New-Object PSObject -Property @{
        Name = $vmName
        IP = $vmIP
        User = $vmUser
        Protocol = $vmProtocol
    }
    # Ajoutez un tooltip au bouton de connexion
    $tooltip.SetToolTip($connectionButton, "Connect")

    $connectionButton.Add_Click({
        param($sender, $e)
        $currentVM = $sender.Tag
        $textbox.AppendText("`nConnecting to $($currentVM.Name)...`r`n")
        if ($currentVM.Protocol -eq "https") {
            $textbox.AppendText("Opening HTTPS connection to $($currentVM.IP)`r`n")
            Start-Process "https://$($currentVM.IP)"
        } else {
            $sshCommand = "ssh $($currentVM.User)@$($currentVM.IP)"
            $textbox.AppendText("SSH Command: $sshCommand`r`n")
            Start-Process "powershell" -ArgumentList "/c", $sshCommand
        }
    })
    $panel.Controls.Add($connectionButton)

    # Bouton d'action VM (start/stop)
    $actionVmButton = New-Object Windows.Forms.Button
    $actionVmButton.Size = [System.Drawing.Size]::new(18, 18)
    $actionVmButton.Location = [System.Drawing.Point]::new(115, 0)
    $actionVmButton.Image = [System.Drawing.Image]::FromFile($stopImagePath) # Image par défaut
    $actionVmButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $actionVmButton.FlatAppearance.BorderSize = 0
    $actionVmButton.Tag = @{
        Name = $vmName
        State = "stopped" # État initial simulé
    }
    
    $actionVmButton.Add_Click({
        param($sender, $e)
        $vmDetails = $sender.Tag
        $vmState = $vmDetails['State']
        $vmName = $vmDetails['Name']  # Assurez-vous d'utiliser la bonne clé pour récupérer le nom de la VM

        if ($vmState -eq "running") {
            # Logique pour arrêter la VM
            $sender.Tag['State'] = "stopped"
            $sender.Image = $playImage  # Utiliser l'image play redimensionnée
            $textbox.AppendText("`nStopping VM $vmName...`r`n")
            & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" controlvm $vmName poweroff
            $tooltip.SetToolTip($sender, "Start VM")
        } else {
            # Logique pour démarrer la VM
            $sender.Tag['State'] = "running"
            $sender.Image = $stopImage # Utiliser l'image stop redimensionnée
            $textbox.AppendText("`nStarting VM $($vmDetails['Name'])...`r`n")
            & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm $vmName --type headless
            $tooltip.SetToolTip($sender, "Stop VM")
        }
    })  
    $panel.Controls.Add($actionVmButton)

    $changePwdButton = New-Object Windows.Forms.Button
    $changePwdButton.Size = [System.Drawing.Size]::new(17, 17)
    $passwordresizedImage = Resize-Image -imagePath $passwordImagePath -width 16 -height 16
    $changePwdButton.Image = $passwordresizedImage
    $changePwdButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $changePwdButton.FlatAppearance.BorderSize = 0
    $changePwdButton.Location = [System.Drawing.Point]::new(140, 0)
    $changePwdButton.Tag = New-Object PSObject -Property @{
        Name = $vmName
        IP = $vmIP
        User = $vmUser
        Protocol = $vmProtocol
    }
    # Ajoutez un tooltip au bouton de connexion
    $tooltip.SetToolTip($changePwdButton, "Change password")

    $changePwdButton.Add_Click({
        param($sender, $e)
        $vmDetails = $sender.Tag
        $vmName = $vmDetails.Name
        $vmIP = $vmDetails.IP
        $vmUser = $vmDetails.User
        $vmProtocol = $vmDetails.Protocol
    
        if ($vmProtocol -eq "ssh") {
            $sshPassword = "mot de passe pour $vmUser" | ConvertTo-SecureString -AsPlainText -Force
            $sshCredential = New-Object System.Management.Automation.PSCredential($vmUser, $sshPassword)

            $session = New-SSHSession -ComputerName $sshHost -Credential $sshCredential

            # Exécuter une commande pour changer le mot de passe
            # Note : Remplacer 'nom_utilisateur' et 'nouveau_mot_de_passe' par les valeurs appropriées
            $command = 'echo "nom_utilisateur:nouveau_mot_de_passe" | sudo chpasswd'
            Invoke-SSHCommand -SSHSession $session -Command $command

            # Fermer la session SSH
            Remove-SSHSession -SSHSession $session.SessionId
        }
        else {
            Write-Host "Unsupported protocol: $vmProtocol"
        }
    })

    $panel.Controls.Add($changePwdButton)
}

# Création des panneaux de statut pour chaque VM
CreateVmStatusPanel "vm1" "10.101.0.1" "share" "ssh"
CreateVmStatusPanel "vm2" "10.102.0.1" "user" "ssh"
CreateVmStatusPanel "vm3" "10.103.0.1" "http_user" "https"
CreateVmStatusPanel "vm4" "10.104.0.1" "share" "ssh"

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({
    foreach ($panel in $vmStatusPanel.Controls) {
        $vmName = $panel.Controls[0].Text.Split(':')[0]
        $status = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" showvminfo $vmName --machinereadable | Select-String '^VMState='
        $isRunning = $status -match 'running'
        $panel.Controls[0].Text = "${vmName}: " + $(if ($isRunning) { "Up" } else { "Down" })
        $panel.Controls[0].ForeColor = $(if ($isRunning) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red })
        # Mise à jour de l'icône du bouton d'action en fonction de l'état de la VM
        $actionButton = $panel.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] -and $_.Size -eq [System.Drawing.Size]::new(18, 18) }
        if ($isRunning) {
            $resizedImage = Resize-Image -imagePath $stopImagePath -width 16 -height 16
            $actionButton.Image = $resizedImage
            $actionButton.Tag['State'] = "running"
            $tooltip.SetToolTip($actionButton, "Stop VM")
        } else {
            $resizedImage = Resize-Image -imagePath $playImagePath -width 15 -height 15
            $actionButton.Image = $resizedImage
            $actionButton.Tag['State'] = "stopped"
            $tooltip.SetToolTip($actionButton, "Start VM")
        }
    }
})
$timer.Start()

$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog()
