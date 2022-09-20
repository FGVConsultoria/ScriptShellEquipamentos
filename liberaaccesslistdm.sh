#!/bin/sh

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

##################################
# Se diretorio não existir cria
##################################
[ ! -d "${RepositorioIP}" ] && mkdir "${RepositorioIP}"

##################################
# IP que será liberado
##################################
IPDestino=”0.0.0.0”

##################################
# Funções
##################################
AcessoSSH(){

	PortaSSH=`nmap -v -p${PortasSSH} ${IPRasecom} | egrep "(tcp.*open)" | cut -f1 -d"/"`

        /bin/expect <<FimExpect >> "${RepositorioIP}/${IPdm}"

        set timeout 60

        spawn ssh ${OpcaoSSH} -p${PortSSH} ${UserSSH}@${IPdm}

        expect "yes/no" {
        send "yes\r"
        expect "*?assword" { send "${PwdSSH}\r" }
        } "*?assword" { send "${PwdSSH}\r" }

        expect "*?#" { send "paginate false\r" }
        expect "*?#" { send "show running-config\r" }
        expect "*?#" { send "exit\r" }

FimExpect

        LimpaDados=`cat -v "${RepositorioIP}/${IPdm}" | sed 's/\^M//g'`

        echo "${LimpaDados}" > "${RepositorioIP}/${IPdm}"

        AccessCont=`grep "access-list-entry" "${RepositorioIP}/${IPdm}" | grep -v "2[0-9][0-9]" | tail -1 | awk '($2 != "") {print $2 + 1}'`

        if [ -n "${AccessCont}" ]
        then

                /bin/expect <<FimExpect

                set timeout 60

                spawn ssh ${OpcaoSSH} -p${PortSSH} ${UserSSH}@${IPdm}

                expect "yes/no" {
                send "yes\r"
                expect "*?assword" { send "${PwdSSH}\r" }
                } "*?assword" { send "${PwdSSH}\r" }


                expect "*?#" { send "config\r"}
                expect "*?#" { send "access-list acl-profile cpu l3 PROTECT-LOOPBACK\r"}
                expect "*?#" { send "access-list-entry ${AccessCont}\r"}
                expect "*?#" { send "match destination-ipv4-address ${IPdm}\r"}
                expect "*?#" { send "match source-ipv4-address ${IPDestino}\r"}
                expect "*?#" { send "action permit\r"}
                expect "*?#" { send "commit\r"}
                expect "*?#" { send "top\r"}
                expect "*?#" { send "exit\r"}
                expect "*?#" { send "exit\r"}
FimExpect
        else

                echo "Não contabilizou ${IPdm}"
        fi

        rm -f "${RepositorioIP}/${IPdm}"
}

##################################
# Loops
##################################
for IPdm in `grep -v "^#" ${Listadm4170}`
do
        AcessoSSH &
        sleep 5
done
