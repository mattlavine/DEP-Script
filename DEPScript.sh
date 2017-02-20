#!/bin/bash

CompType=`/usr/sbin/system_profiler SPHardwareDataType | grep 'Model Name:' | awk -F': ' '{print substr($2,1)}'`

LoggedInUser=`/usr/libexec/PlistBuddy -c "print :dsAttrTypeStandard\:RealName:0" /dev/stdin <<< "$(dscl -plist . -read /Users/$(stat -f%Su /dev/console) RealName)"`

#SetupDir="/Users/$LoggedInUser"

#while [ 1 ]; do
#	if [  -d "$SetupDir" ]; then
#		break
#	fi
#	sleep 1
#done

function Recon()
{
	sudo /usr/local/bin/jamf recon
}

function Policy()
{
	sudo /usr/local/bin/jamf policy
}

function CompName()
{
    cType=$(/usr/sbin/system_profiler SPHardwareDataType | grep 'Model Name:' | awk -F': ' '{print substr($2,1,7)}')
    sNumber=$(/usr/sbin/system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
	if [ "${cType}" == "MacBook" ]; then
		/usr/sbin/scutil --set ComputerName "L${sNumber}"
		/usr/sbin/scutil --set LocalHostName "L${sNumber}"
		/usr/sbin/scutil --set HostName "L${sNumber}"
		/usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName "L${sNumber}"
	else
		/usr/sbin/scutil --set ComputerName  "D${sNumber}"
		/usr/sbin/scutil --set LocalHostName "D${sNumber}"
		/usr/sbin/scutil --set HostName "D${sNumber}"
		/usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName "D${sNumber}"
	fi

	echo "Computer Name Information"
	echo "************************************************************"
		echo "Computer Name: $(/usr/sbin/scutil --get ComputerName)"
		echo "LocalHost Name: $(/usr/sbin/scutil --get LocalHostName)"
		echo "Host Name: $(/usr/sbin/scutil --get HostName)"
	echo " "
}

function DHCPinfo()
{
    MACaddress=$(/sbin/ifconfig en0 | awk '/ether/{print $2}')
	ClientID="CaliFruitCo-"$MACaddress
	echo "Client DHCP IP Information"
	echo "************************************************************"
	/usr/sbin/networksetup -detectnewhardware
	IFS=$'\n'
	    for i in $(/usr/sbin/networksetup -listallnetworkservices | tail +2 );
	    do
	        echo "$i is set to Client ID: $ClientID"
	        /usr/sbin/networksetup -setdhcp $i $ClientID
	        echo "Set Client ID for $i to $ClientID"
	    done
	unset IFS
	echo " "
}

function Wireless()
{
	productionSSID="halekoa75"
	provisioningSSID="cpn84"
	wifiOrAirport=$(/usr/sbin/networksetup -listallnetworkservices | grep -Ei '(Wi-Fi|AirPort)')
	wirelessDevice=$(/usr/sbin/networksetup -listallhardwareports | awk "/$wifiOrAirport/,/Device/" | awk 'NR==2' | cut -d " " -f 2)
	prefferedNetworks=$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$wirelessDevice")
	echo "Updating Wireless SSID remove $provisioningSSID"
	echo "************************************************************"
	echo "Available Wireless Device:" $wifiOrAirport
	echo $prefferedNetworks

	until echo "$prefferedNetworks" | grep !q "$provisioningSSID"; do
		/usr/sbin/networksetup -removepreferredwirelessnetwork "$wirelessDevice" "$provisioningSSID"
	done

	sudo /usr/local/bin/jamf recon
}

# get Screen Size
#######################################################################################################################
resolution=`system_profiler SPDisplaysDataType |grep Resolution | awk '{print$2,$3,$4}'	`

if [ "${resolution}" == "1366 x 768" ]; then
	screen="11\""
	elif [ "${resolution}" == "2560 x 1600" ] || [ "${resolution}" == "1440 by 900" ]; then
	screen="13\""
	elif [ "${resolution}" == "2880 x 1800" ]; then
	screen="15\""
	elif [ "${resolution}" == "1920 x 1080" ] || [ "${resolution}" == "4096 by 2304" ]; then
	screen="21\""
	elif [ "${resolution}" == "5120 x 2880" ]; then
	screen="27\""
fi

model="${screen} ${CompType} ${isRetina}"

# get ICNS File
########################################################################################################################################
if [ "${resolution}" == "1366 x 768" ] || [ "${CompType}" == "MacBook Air" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookair.icns"

	elif [ "${resolution}" == "1440 x 900" ] || [ "${CompType}" == "MacBook Air" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-13-retina-display.icns"

	elif [ "${resolution}" == "2560 x 1600" ] || [ "${CompType}" == "MacBook Pro" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-13-retina-display.icns"

	elif [ "${resolution}" == "2880 x 1800" ]  || [ "${CompType}" == "MacBook Pro" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-15-retina-display.icns"

	elif [ "${resolution}" == "1920 x 1080 " ] || [ "${CompType}" == "iMac" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.imac-unibody-27-no-optical.icns"

	elif [ "${resolution}" == "4096 x 2304" ] || [ "${CompType}" == "iMac" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.imac-unibody-27-no-optical.icns"

	elif [ "${resolution}" == "5120 x 2880" ] || [ "${CompType}" == "iMac" ]; then
	ModelIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.imac-unibody-27-no-optical.icns"
fi

# JAMF Helper Variables
#######################################################################################################################
	windowType="fs"				#	[hud | utility | fs]
	windowPostion="ul"			#	[ul | ll | ur | lr]
	iconSize="256"				#	pixels
	alignDescription="center"	#	[right | left | center | justified | natural]
	alignHeading="center" 		#	[right | left | center | justified | natural]

# Screen 001 - Welcome
#######################################################################################################################
# Variables
#######################################################################################################################
policyName="Welcome"
jhHeading="Congratulations ${LoggedInUser}"	#"string"
jhDescription="Your $model is being customized. This may take up to 30 minutes, depending on your network speed."
model="${screen} ${CompType} ${isRetina}"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$ModelIcon" \
-iconSize "768" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName
sudo /usr/local/bin/jamf recon

CompName && Recon && DHCPinfo && sleep 15 && Recon && sleep 60 && Policy && Recon

# Screen 002 - Preparing Setup
#######################################################################################################################
sleep 15
killall jamfhelper
policyName="SoftwarePrep"
jhHeading="Preparing Setup"	#"string"
jhDescription="Your $model is being customized. This may take up to 30 minutes, depending on your network speed."
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 100 - Install Symantec Anti Virus
#######################################################################################################################
policyName="SymantecAV"
jhHeading="Configuring Symantec Anti Virus"	#"string"

icon="/usr/local/ti/icons/100-sep_app_icon.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper


# Screen 101 - File Vault
#######################################################################################################################
policyName="Encryption"
jhHeading="Encrypting Hard Drive"	#"string"

icon="/System/Library/PreferencePanes/Security.prefPane/Contents/Resources/FileVault.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 102 - Install Pulse Client
#######################################################################################################################
policyName="VPN"
jhHeading="Configuring Pulse Client"	#"string"
#echo $jhDescription
icon="/usr/local/ti/icons/102-pulse.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName &&

sleep 6
killall jamfhelper

# Screen 103 - Install Apple Enterprise Connect
#######################################################################################################################
policyName="EC"
jhHeading="Configuring Global Protect"	#"string"

icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 104 - Install Global Protect
#######################################################################################################################
policyName="GP"
jhHeading="Configuring Global Protect"	#"string"

icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/BookmarkIcon.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper


# Screen 200 - Printer: Xerox Driver, non-admin print, CUPS enabled
#######################################################################################################################
policyName="Printing"
jhHeading="Installing Printer Drivers"	#"string"

icon="/usr/local/ti/icons/200-ySoft.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 201 - Print: Map Printers
#######################################################################################################################
policyName="MapPrinting"
jhHeading="Setting up Printing"	#"string"

icon="/usr/local/ti/icons/200-ySoft.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &#echo "Configuring: Follow Me Printing" &&
#$policyName &&

jamf policy -trigger $policyName

sleep 6
killall jamfhelper



# Screen 202 - Install Crash Plan
#######################################################################################################################
policyName="CrashPlan"
jhHeading="Installing Crash Plan"	#"string"

icon="/usr/local/ti/icons/201-CrashPlan.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &#echo "Configuring Crash Plan Backup" && #$policyName &&

jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 300 - User Experience: Non Admin Wifi, MenuBar Icons
#######################################################################################################################
policyName="UI"
jhHeading="Optimizing User Experience"	#"string"
icon="/usr/local/ti/icons/300-UsersIcon.icns"
#######################################################################################################################
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 498 - Cache Microsoft Office
#######################################################################################################################
policyName="CacheMSOffice2016"
jhHeading="Downloading Microsoft Office 2016"

icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 499 - Install Microsoft Office
#######################################################################################################################
policyName="InstallMSOffice2016"
jhHeading="Installing Microsoft Office 2016"

icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName

sleep 6
killall jamfhelper


# Screen 400 - Cache Microsoft Excel
#######################################################################################################################
#policyName="CacheMSExcel2016"
#jhHeading="Downloading Microsoft Excel 2016"
#
#icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"
#
#"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
#-windowType "$windowType" \
#-title "$jhTitle" \
#-heading "$jhHeading" \
#-description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
#
#
# # Screen 401 - Install Microsoft Excel
# #######################################################################################################################
# policyName="InstallMSExcel2016"
# jhHeading="Installing Microsoft Excel 2016"	#"string"
#
# icon="/usr/local/ti/icons/405-msExcel2016.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$icon" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
# # Screen 402 - Cache Microsoft Outlook
# #######################################################################################################################
# policyName="CacheMSOutlook2016"
# jhHeading="Downloading Microsoft Outlook 2016"	#"string"
#
# icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
#
#
# # Screen 403 - Install Microsoft Outlook
# #######################################################################################################################
# policyName="InstallMSOutlook2016"
# jhHeading="Installing Microsoft Outlook 2016"	#"string"
#
# icon="/usr/local/ti/icons/401-msOutlook2016.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
#
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
# # Screen 404 - Cache Microsoft PowerPoint
# #######################################################################################################################
# policyName="CacheMSPowerPoint2016"
# jhHeading="Downloading Microsoft PowerPoint 2016"	#"string"
#
# icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
#
# jamf policy -trigger $policyName
# sleep 6
# killall jamfhelper
#
#
#
# # Screen 405 - Install Microsoft PowerPoint
# #######################################################################################################################
# policyName="InstallMSPowerPoint2016"
# jhHeading="Installing Microsoft PowerPoint 2016"	#"string"
# echo $jhDescription
# icon="/usr/local/ti/icons/403-MSPowerPoint2016.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
#
#
# # Screen 406 - Cache Microsoft Word
# #######################################################################################################################
# policyName="CacheMSWord2016"
# jhHeading="Downloading Microsoft Word 2016"	#"string"
#
# icon="/usr/local/ti/icons/400-msOfficeInstaller.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
#
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper
#
#
#
# # Screen 407 - Install Microsoft Word
# #######################################################################################################################
# policyName="InstallMSWord2016"
# jhHeading="Installing Microsoft Word 2016"	#"string"
#
#
# icon="/usr/local/ti/icons/407-msWord2016.icns"
#
# "/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
# -windowType "$windowType" \
# -title "$jhTitle" \
# -heading "$jhHeading" \
# -description "$jhDescription" \
# -icon "$icon" \
# -iconSize "$iconSize" \
# -alignDescription "$alignDescription" \
# -alignHeading "$alignHeading" &
#
# jamf policy -trigger $policyName
#
# sleep 6
# killall jamfhelper

# Screen 407 - Install Microsoft Sharepoint Plugin
#######################################################################################################################
#policyName="InstallMSSharepointPlugin"
#jhHeading="Installing Microsoft Sharepoint Plugin"	#"string"


#icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericSharepoint.icns"

#"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
#-windowType "$windowType" \
#-title "$jhTitle" \
#-heading "$jhHeading" \
#-description "$jhDescription" \
#-icon "$icon" \
#-iconSize "$iconSize" \
#-alignDescription "$alignDescription" \
#-alignHeading "$alignHeading" &

#jamf policy -trigger $policyName

#sleep 6
#killall jamfhelper



# Screen 501 - Install WebEx
#######################################################################################################################
policyName="Webex"
jhHeading="Installing WebEX Plugin"	#"string"

icon="/usr/local/ti/icons/501-WebExManager.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &#echo "Configuring Webex" && #$policyName &&

jamf policy -trigger $policyName

sleep 6
killall jamfhelper


# Screen 502 - Install Jabber
#######################################################################################################################
policyName="Jabber"
jhHeading="Installing Jabber"	#"string"
echo $jhDescription
icon="/usr/local/ti/icons/502-CiscoJabber.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &#echo "Configuring Jabber" && #$policyName &&

jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 800 - Internet Plugins
#######################################################################################################################
policyName="Plugins"
jhHeading="Installing Internet Plugins"	#"string"
echo $jhDescription
icon="/Applications/Safari.app/Contents/Resources/compass.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon"  \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
#echo "Configuring Symantec Anti Virus" && #$policyName &&

jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Screen 850 - MacOS Updates
#######################################################################################################################
policyName="OSUpdates"
jhHeading="Updating MacOS"	#"string"
echo $jhDescription
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"

"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription"  \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &

jamf policy -trigger $policyName

sleep 6
killall jamfhelper

# Wireless
#######################################################################################################################
# Variables
#######################################################################################################################
jhHeading="Updating Wireless Connection"
icon="/System/Library/CoreServices/Applications/Wireless Diagnostics.app/Contents/Resources/WirelessDiagnostics.icns"
wifiOrAirport=$(/usr/sbin/networksetup -listallnetworkservices | grep -Ei '(Wi-Fi|AirPort)')
wirelessDevice=$(networksetup -listallhardwareports | awk "/$wifiOrAirport/,/Device/" | awk 'NR==2' | cut -d " " -f 2)
productionSSID="halekoa75"
provisioningSSID="cpn84"
prefferedNetworks=$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$wirelessDevice")
updatedSSID=$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$wirelessDevice")
#######################################################################################################################
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description "$jhDescription" \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
echo "Available Wireless Device:" $wifiOrAirport
echo $prefferedNetworks

#while echo "$prefferedNetworks" | grep -q "$productionSSID" && echo "$prefferedNetworks" | grep -q "$provisioningSSID"; do
	networksetup -removepreferredwirelessnetwork "$wirelessDevice" "$provisioningSSID"
#done
	echo "Removed SSID:" $provisioningSSID

#until echo "$prefferedNetworks" | grep !q "$provisioningSSID"; do
#	networksetup -removepreferredwirelessnetwork "$wirelessDevice" "$provisioningSSID"
#done

sleep 2

killall jamfhelper

# Screen 999 - Complete
#######################################################################################################################
policyName="Enjoy"
jhHeading="Enjoy!"	#"string"
icon="/usr/local/ti/icons/999-Success.icns"
#######################################################################################################################
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfhelper" \
-windowType "$windowType" \
-title "$jhTitle" \
-heading "$jhHeading" \
-description " "  \
-icon "$icon" \
-iconSize "$iconSize" \
-alignDescription "$alignDescription" \
-alignHeading "$alignHeading" &
jamf policy -trigger $policyName
sleep 2



killall jamfhelper

exit 0