﻿#Requires -Version 5.0

<#
.SYNOPSIS
    Retrieves the disk capacities from the computer

.DESCRIPTION

.NOTES
    This PowerShell script was developed and optimized for ScriptRunner. The use of the scripts requires ScriptRunner. 
    The customer or user is authorized to copy the script from the repository and use them in ScriptRunner. 
    The terms of use for ScriptRunner do not apply to this script. In particular, ScriptRunner Software GmbH assumes no liability for the function, 
    the use and the consequences of the use of this freely available script.
    PowerShell is a product of Microsoft Corporation. ScriptRunner is a product of ScriptRunner Software GmbH.
    © ScriptRunner Software GmbH

.COMPONENT
    Requires WinRm and WMI on the computer

.LINK
    https://github.com/scriptrunner/ActionPacks/tree/master/WinFileManagement/Disks

.Parameter ComputerName
    [sr-en] Name of the computer from which to retrieve the disk informations. If Computername is not specified, the current computer is used.
    
.Parameter AccessAccount
    [sr-en] User account that has permission to perform this action. If Credential is not specified, the current user account is used.

.Parameter OnlyLocalDisks
    [sr-en] Local drives only 
#>

[CmdLetBinding()]
Param(
    [string]$ComputerName,
    [PSCredential]$AccessAccount,
    [switch]$OnlyLocalDisks 
)

$Script:Cim=$null
$Script:output = @()
try{ 
    if([System.String]::IsNullOrWhiteSpace($ComputerName)){
        $ComputerName=[System.Net.DNS]::GetHostByName('').HostName
    }          
    if($null -eq $AccessAccount){
        $Script:Cim = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
    }
    else {
        $Script:Cim = New-CimSession -ComputerName $ComputerName -Credential $AccessAccount -ErrorAction Stop
    }    
    Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $Script:Cim | Foreach-Object {
        if($OnlyLocalDisks -eq $false -or $_.DriveType -eq "3"){  
            $Script:output += "Drive $($_.DeviceID) free bytes $($_.FreeSpace) from $($_.Size)"
        }
    }
    
    if($SRXEnv) {
        $SRXEnv.ResultMessage = $Script:output
    }
    else{
        Write-Output $Script:output
    }
}
catch{
    throw
}
finally{
    if($null -ne $Script:Cim){
        Remove-CimSession $Script:Cim 
    }
}