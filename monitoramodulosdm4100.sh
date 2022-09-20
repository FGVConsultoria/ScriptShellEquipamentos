#!/bin/sh

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
PwdSSH="Password”

##################################
# Lista depossiveis portas de
# acesso utilizadas pelo SSH
# nos equipamentos.
# Separados por virgula
# Ex.: "22,55,4422"
##################################
PortasSSH="22"

##################################
# Arquivos das listas de IPs
##################################
Listadm4100="./listadm4100"

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
Acessodm4100(){

        PortaSSH=`nmap -v -p${PortasSSH} ${IPdm} | egrep "(tcp.*open)" | cut -f1 -d"/"`

        /usr/local/bin/expect <<FimExpect >> "${RepositorioIP}/${IPdm}"

        set timeout 60

        spawn ssh ${OpcaoSSH} -p${PortaSSH} ${UserSSH}@${IPdm}

        expect "yes/no" {
        send "yes\r"
        expect "*?assword" { send "${PwdSSH}\r" }
        } "*?assword" { send "${PwdSSH}\r" }

        expect "*?#" { send "terminal page-break disable\r" }
        expect "*?#" { send "show startup-config\r" }
        expect "*?#" { send "show interface port-list 1-52\r" }
        expect "*?#" { send "show transceiver information port-list 1-52\r" }
        expect "*?#" { send "exit\r" }

FimExpect

        LimpaDados=`cat -v "${RepositorioIP}/${IPdm}" | sed 's/\^M//g'`

        echo "${LimpaDados}" > "${RepositorioIP}/${IPdm}"

        HostName=`grep "hostname" "${RepositorioIP}/${IPdm}" | cut -f2 -d" "`

        if [ -e "${RepositorioName}/${HostName}" ]
        then

                grep "basic information" "${RepositorioIP}/${IPdm}" > "${RepositorioTmp}/${HostName}I$$"
                grep "basic information" "${RepositorioName}/${HostName}" > "${RepositorioTmp}/${HostName}N$$"

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
                                Serial=`sed -n "/Port ${DadosPorta} basic information/,/CMU/p" "${RepositorioIP}/${IPdm}" | grep "Number"`

                                if [ ! "$Serial" ]
                                then
                                        Serial=`sed -n "/Port ${DadosPorta} basic information/,/CMU/p" "${RepositorioName}/${HostName}" | grep "Number"`
                                        Status="REMOVIDO"
                                else
                                        Status="INSTALADO"
                                fi

                                if [ "${Serial}" ]
                                then
                                        V_msg="
${HostName} : ${IPdm}
=================
Modulo ${Status}
=================
${DadosPorta}
${Serial}
"
                                        links -dump 'https://api.telegram.org/bot${BOT}/sendMessage?chat_id=${CHATID}&text="'"${V_msg}"'"'
                                fi
                                sleep 1
                        done

                        IFS="${OldIfs}"
                fi
                mv "${RepositorioIP}/${IPdm}" "${RepositorioName}/${HostName}"
                rm -f "${RepositorioTmp}/${HostName}I$$" "${RepositorioTmp}/${HostName}N$$"

        else
                [ "${HostName}" ] && mv "${RepositorioIP}/${IPdm}" "${RepositorioName}/${HostName}" || mv "${RepositorioIP}/${IPdm}" "${RepositorioName}/${IPdm}"
        fi

}

##################################
# Loops
##################################
for IPdm in `grep -v "^#" ${ListaRasecom}`
do
        ping -c1 "${IPdm}" >> /dev/null
        if [ "$?" -eq "0" ]
        then
                Acessodm4100 &
                sleep 5
        fi
done
