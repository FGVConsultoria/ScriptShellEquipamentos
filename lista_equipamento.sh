#!/bin/sh

if [ -z "$1" ]
then

	echo "$0 IP/Masc"
else
	V_Rede="$1"

	for MAC in `nmap -n -sP "${V_Rede}" | grep -Ewo '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | cut -f-3 -d: | sort | uniq | grep -v "00:00:00"`
	do
		echo -n "${MAC} : "
		links -dump "https://api.macvendors.com/${MAC}"
		sleep 5
	done
fi
