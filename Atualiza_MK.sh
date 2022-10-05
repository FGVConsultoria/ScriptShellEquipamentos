#!/bin/sh

######################################
# Dados do ssh
######################################
OpcoesSSH="-o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-dss -o StrictHostKeyChecking=no -o KexAlgorithms=+diffie-hellman-group1-sha1"
PortaSSH="22"
UserSSH="user"
SenhaSSH="SenhaDoUser"

######################################
# Diretório de armazenamento dos NPKs
# Busca os IPs de LoopBack dos MKs
######################################
V_npks="./npks"
IPsMks="./listadeips"

######################################
# Data para execução no MK padrão
# Americano exemplo : Oct/05/2022
######################################
V_Data="Mes/Dia/ANO"

######################################
# Hora para execução no MK
# Exemplo 1 : 02:25:00
# Exemplo 2 : 02:35:00
# Exemplo 3 : 02:45:00
# Exemplo 4 : 02:55:00
######################################
V_Hora1="HH:MM:SS"
V_Hora2="HH:MM:SS"
V_Hora3="HH:MM:SS"
V_Hora4="HH:MM:SS"

######################################
# Comando a ser executado no MK
######################################
Comandos='/system scheduler add name=ZZ_Reboot1 on-event="/system reboot" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=${V_Data} start-time=${V_Hora1}
/system scheduler add name=ZZ_Upgrade on-event="/system routerboard upgrade" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=${V_Data} start-time=${V_Hora2}
/system scheduler add name=ZZ_Reboot2 on-event="/system reboot" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=${V_Data} start-time=${V_Hora3}
/system scheduler add name=ZZ_Remove on-event="/system scheduler remove numbers=ZZ_Reboot1 ;\r\\n/system scheduler remove numbers=ZZ_Upgrade ;\r\\n/system scheduler remove numbers=ZZ_Reboot2 ;\r\\n/system scheduler remove numbers=ZZ_Remove ;\r\\n" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=${V_Data} start-time=${V_Hora4}
/system resource print
/file remove [/file find type=package]'

######################################
# Ajuste do comando para envio SSH
######################################
Ajuste_Comando=`echo "${Comandos}" | sed 's/"/\\"/g;s/\;/\\\;/g;s/$/\ \;/g' | tr "\n" " " | sed 's/\;\ $//'`

######################################
# Loop
######################################
for Mks in ${IPsMks}
do
  ######################################
	# Se não responde passa para o próximo
	######################################
  ping -c 1 "${Mks}" 1>/dev/null 2>/dev/null
  [ "${?}" -ne "0" ] && continue

	######################################
	# Busca dados de versão atual
	######################################
  sshpass -p "${V_pass}" ssh ${V_op_ssh} "${V_user}"@"${Mks}" -p${V_pt_ssh} ${Ajuste_Comando} | cat -v | sed 's/\^M//g' | egrep "(version:|architecture-name:)" | awk '{print $1$2}'  | sed 's/\:/=\"/g;s/$/"/g;s/-//g' > "${$}"

  V_ver_arq=`cat ./"${$}"`
  rm -f ./"${$}" 1>/dev/null 2>/dev/null

  eval "${V_ver_arq}"

  if [ ! "${version}" ]
  then
    echo ""
    continue
  fi

	######################################
	# Envia NPK para atualização do MK
	######################################
  sshpass -p "${V_pass}" scp -P${V_pt_ssh} ${V_op_ssh} "${V_npks}/routeros-${architecturename}-${V_vers}.npk" "${V_user}"@"${V_mks}":/
done
