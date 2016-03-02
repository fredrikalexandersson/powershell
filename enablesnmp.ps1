# script to automate the settings to SNMP services and install the services if they arent already installed.
# define your parameters below

$pollers = "192.168.1.20"
$communitystring = "public"
$location = "Customer"

# Import ServerManger Module
Import-Module ServerManager

# Check if the SNMP service is installed
$checksnmp = Get-WindowsFeature | Where-Object {$_.Name -eq "SNMP-Service"}
If ($checksnmp.Installed -ne "True") {
	#Missing? then enable it
	Add-WindowsFeature SNMP-Service | Out-Null
}

# Check if the SNMP WMI Provider service is installed
$checkwmi = Get-WindowsFeature | Where-Object {$_.Name -eq "SNMP-WMI-Provider"}
If ($checkwmi.Installed -ne "True") {
	#Missing? then enable it
	Add-WindowsFeature SNMP-WMI-Provider | Out-Null
}

# Check if the SNMP Tools are installed (adds security tab under the service)
$checktools = Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-SNMP"}
If ($checktools.Installed -ne "True") {
	#Missing? then enable it
	Add-WindowsFeature RSAT-SNMP | Out-Null
}

# Once again verify so that the basic SNMP service is enabled, if so add all the registry settings.
If ($checksnmp.Installed -eq "True"){

	# Overwrite the current value and add the defined location.
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" /v sysLocation /t REG_SZ /d $location /f | Out-Null
    
    # Overwrite the current value and add sett all the SNMP Agent linktypes to all.
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent" /v sysServices /t REG_DWORD /d 79 /f | Out-Null
    
    # Overwrite the current value and add localhost as the primary poller (for local lookups)
	reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v 1 /t REG_SZ /d localhost /f | Out-Null
    
    #add a identifier for every poller in the list.
	$identifier = 2
	Foreach ($ip in $pollers){
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v $identifier /t REG_SZ /d $ip /f | Out-Null
		$identifier++
		}
	
    # For good measure change all added community strings to READ
	Foreach ($string in $communitystring){
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v $string /t REG_DWORD /d 4 /f | Out-Null
		}
}

Else {Write-Host "Error: SNMP Services Not Installed, not adding any registry values, reboot and run me again"}

   # Restart the service so all registry values gets added.
   
   If ($checksnmp.Installed -ne "True") {
	Restart-Service SNMP
}

