#!/bin/sh

##################################
# Este script pode ser usado em
# DMs 4170 e DMs 4270
##################################

##################################
# Dados do Telegram
##################################
CHATID=”ID_DO_CANAL”
BOT=”ID_DO_BOT”

##################################
# Dados de acesso ssh
##################################
OpcaoSSH='-o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-dss -o StrictHostKeyChecking=no -o KexAlgorithms=+diffie-hellman-group1-sha1'
UserSSH="User"
PwdSSH="Password"

##################################
# Lista depossiveis portas de
# acesso utilizadas pelo SSH
# nos equipamentos.
# Separados por virgula
# Ex.: "22,55,4422"
##################################
PortasSSH="22"

##################################
# Arquivo da lista de IPs
##################################
Listadm="./listadm"

##################################
# Diretorios
##################################
RepositorioIP="./IP"
RepositorioName="./NAME"
RepositorioTmp="./TMP"

##################################
# Se diretorio não existir cria
##################################
[ ! -d "${RepositorioIP}" ] && mkdir "${RepositorioIP}"
[ ! -d "${RepositorioName}" ] && mkdir "${RepositorioName}"
[ ! -d "${RepositorioTmp}" ] && mkdir "${RepositorioTmp}"

##################################
# Funções
##################################
AcessoDmSSH(){
        PortaSSH=`nmap -v -p${PortasSSH} ${IPDM} | egrep "(tcp.*open)" | cut -f1 -d"/"`

        /usr/local/bin/expect <<FimExpect >> "${RepositorioIP}/${IPDM}"

        set timeout 60

        spawn ssh ${OpcaoSSH} -p${PortaSSH} ${UserSSH}@${IPDM}

        expect "yes/no" {
        send "yes\r"
        expect "*?assword" { send "${PwdSSH}\r" }
        } "*?assword" { send "${PwdSSH}\r" }

        expect "*?#" { send "paginate false\r" }
        expect "*?#" { send "show running-config\r" }
        expect "*?#" { send "show inventory chassis 1 transceivers brief\r" }
        expect "*?#" { send "exit\r" }

FimExpect

        LimpaDados=`cat -v "${RepositorioIP}/${IPDM}" | sed 's/\^M//g'`
        echo "${LimpaDados}" > "${RepositorioIP}/${IPDM}"

        HostName=`tail -1 "${RepositorioIP}/${IPDM}" | tr -d "# "`

        if [ -e "${RepositorioName}/${HostName}" ]
        then

                grep "^ten-gigabit-ethernet" "${RepositorioIP}/${IPDM}" > "${RepositorioTmp}/${HostName}I$$"
                grep "^ten-gigabit-ethernet" "${RepositorioName}/${HostName}" > "${RepositorioTmp}/${HostName}N$$"

                DifEnc=`comm -3 "${RepositorioTmp}/${HostName}I$$" "${RepositorioTmp}/${HostName}N$$"`

                if [ "${DifEnc}" ]
                then
                        Seriais=""

                        OldIfs="${IFS}"
                        IFS="
"
                        for Porta in ${DifEnc}
                        do
                                DadosPorta=`echo "${Porta}" | cut -f2 -d" "`
                                Serial=`grep "^ten-gigabit-ethernet  ${DadosPorta}" "${RepositorioIP}/${IPDM}"`

                                if [ ! "$Serial" ]
                                then
                                        Serial=`grep "^ten-gigabit-ethernet  ${DadosPorta}" "${RepositorioIP}/${IPDM}"`
                                        Status="REMOVIDO"
                                else
                                        Status="INSTALADO"
                                fi
                                if [ "${Serial}" ]
                                then
                                        Serial=`echo "${Serial}" | awk '{print "\nVendor :",$3,"\nSerial number :",$4,"\nPart number :",$5}'`

                                        V_msg="
${HostName} : ${IPDM}
=================
Modulo ${Status}
=================
ETH port : ${DadosPorta}
${Serial}
"
                                        links -dump 'https://api.telegram.org/bot${BOT}/sendMessage?chat_id=${CHATID}&text="'"${V_msg}"'"'
                                fi
                                sleep 1
                        done

                        IFS="${OldIfs}"
                fi
                mv "${RepositorioIP}/${IPDM}" "${RepositorioName}/${HostName}"
                rm -f "${RepositorioTmp}/${HostName}I$$" "${RepositorioTmp}/${HostName}N$$"

        else
                [ "${HostName}" ] && mv "${RepositorioIP}/${IPDM}" "${RepositorioName}/${HostName}" || mv "${RepositorioIP}/${IPDM}" "${RepositorioName}/${IPDM}"
        fi

}

##################################
# Loops
##################################
for IPDM in `grep -v "^#" ${Listadm}`
do
        ping -c1 "${IPDM}" >> /dev/null
        if [ "$?" -eq "0" ]
        then
                AcessoDmSSH &
                sleep 5
        fi
done

