﻿#Requires -Version 5.0
# Requires -Modules VMware.VimAutomation.Core

<#
    .SYNOPSIS
        Modifies the specified SCSI controller

    .DESCRIPTION

    .NOTES
        This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
        The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
        The terms of use for ScriptRunner do not apply to this script. In particular, ScriptRunner Software GmbH assumes no liability for the function, 
        the use and the consequences of the use of this freely available script.
        PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of ScriptRunner Software GmbH.
        © ScriptRunner Software GmbH

    .COMPONENT
        Requires Module VMware.VimAutomation.Core

    .LINK
        https://github.com/scriptrunner/ActionPacks/tree/master/VMware/Disks

    .Parameter VIServer
        [sr-en] IP address or the DNS name of the vSphere server to which you want to connect
        [sr-de] IP Adresse oder DNS des vSphere Servers

    .Parameter VICredential
        [sr-en] PSCredential object that contains credentials for authenticating with the server
        [sr-de] Benutzerkonto für die Ausführung

    .Parameter VMName
        [sr-en] Virtual machine from which you want to retrieve the SCSI controllers 
        [sr-de] Virtuelle Maschine

    .Parameter TemplateName
        [sr-en] Virtual machine template from which you want to modify the SCSI controller
        [sr-de] Vorlage

    .Parameter SnapshotName
        [sr-en] Snapshot from which you want to modify the SCSI controller
        [sr-de] Snapshotname

    .Parameter DiskName
        [sr-en] Name of the SCSI hard disk you want to modify the SCSI controller 
        [sr-de] SCSI Festplatte

    .Parameter ControllerName
        [sr-en] Names of the SCSI controllers you want to modify
        [sr-de] Name des SCSI Kontroller

    .Parameter BusSharingMode
        [sr-en] Bus sharing mode of the SCSI controller
        [sr-de] Bus-Modus des SCSI-Kontroller
#>

[CmdLetBinding()]
Param(
    [Parameter(Mandatory = $true,ParameterSetName = "VM")]
    [Parameter(Mandatory = $true,ParameterSetName = "Template")]
    [Parameter(Mandatory = $true,ParameterSetName = "Snapshot")]
    [string]$VIServer,
    [Parameter(Mandatory = $true,ParameterSetName = "VM")]
    [Parameter(Mandatory = $true,ParameterSetName = "Template")]
    [Parameter(Mandatory = $true,ParameterSetName = "Snapshot")]
    [pscredential]$VICredential,
    [Parameter(Mandatory = $true,ParameterSetName = "VM")]
    [Parameter(Mandatory = $true,ParameterSetName = "Snapshot")]
    [string]$VMName,
    [Parameter(Mandatory = $true,ParameterSetName = "Template")]    
    [string]$TemplateName,
    [Parameter(Mandatory = $true,ParameterSetName = "Snapshot")]
    [string]$SnapshotName,
    [Parameter(Mandatory = $true,ParameterSetName = "VM")]
    [Parameter(Mandatory = $true,ParameterSetName = "Template")]
    [Parameter(Mandatory = $true,ParameterSetName = "Snapshot")]
    [ValidateSet("NoSharing", "Physical", "Virtual")]
    [string]$BusSharingMode,
    [Parameter(ParameterSetName = "VM")]
    [Parameter(ParameterSetName = "Template")]
    [Parameter(ParameterSetName = "Snapshot")]
    [string]$DiskName,
    [Parameter(ParameterSetName = "VM")]
    [Parameter(ParameterSetName = "Template")]
    [Parameter(ParameterSetName = "Snapshot")]
    [string]$ControllerName
)

Import-Module VMware.VimAutomation.Core

try{
    if([System.String]::IsNullOrWhiteSpace($DiskName) -eq $true){
        $DiskName = "*"
    }
    if([System.String]::IsNullOrWhiteSpace($ControllerName) -eq $true){
        $ControllerName = "*"
    }
    $Script:vmServer = Connect-VIServer -Server $VIServer -Credential $VICredential -ErrorAction Stop
    [hashtable]$cmdArgs = @{'ErrorAction' = 'Stop'
                            'Server' = $Script:vmServer
                            }                            
    if($PSCmdlet.ParameterSetName  -eq "Snapshot"){
        $vm = Get-VM @cmdArgs -Name $VMName
        $snap = Get-Snapshot @cmdArgs -Name $SnapshotName -VM $vm
        $cmdArgs.Add('Snapshot', $snap)
    }
    elseif($PSCmdlet.ParameterSetName  -eq "Template"){
        $temp = Get-Template @cmdArgs -Name $TemplateName
        $cmdArgs.Add('Template', $temp)
    }
    else {
        $vm = Get-VM @cmdArgs -Name $VMName
        $cmdArgs.Add('VM', $vm)
    }
    $Script:harddisks = Get-HardDisk @cmdArgs -Name $DiskName
    $script:output = Get-ScsiController -Server $Script:vmServer -HardDisk $Script:harddisks -Name $ControllerName -ErrorAction Stop `
                        | Set-ScsiController -BusSharingMode $BusSharingMode -ErrorAction Stop | Select-Object *

    if($SRXEnv) {
        $SRXEnv.ResultMessage = $script:output
    }
    else{
        Write-Output $script:output
    }
}
catch{
    throw
}
finally{    
    if($null -ne $Script:vmServer){
        Disconnect-VIServer -Server $Script:vmServer -Force -Confirm:$false
    }
}