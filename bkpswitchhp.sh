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
ListaHP="./listaHP"

##################################
# Diretorios
##################################
RepositorioName="./NAME"
RepositorioTmp="./TMP"

##################################
# Se diretorio não existir cria
##################################
[ ! -d "${RepositorioName}" ] && mkdir "${RepositorioName}"
[ ! -d "${RepositorioTmp}" ] && mkdir "${RepositorioTmp}"

##################################
# Funções
##################################
AcessoHP(){
        PortaSSH=`nmap -v -p${PortasSSH} ${IPdm} | egrep "(tcp.*open)" | cut -f1 -d"/"`
        sshpass -p"${PwdSSH}" ssh ${OpcaoSSH} -p${PortaSSH} ${UserSSH}@${IPdm} display current-configuration > "${RepositorioTmp}/${IPhp}.tmp"
        LimpaDados=`cat -v "${RepositorioTmp}/${IPdm}.tmp" | sed 's/\^M//g'`
        
        ##################################
        # Identifica o Switch
        ##################################
        V_sw_name=`grep "sysname" switch_top_of_rack.conf | cut -f3 -d" "`
	      V_data=`date +%Y%m%d`
        V_loop_name=`echo "${IPdm}" | tr "." "_"`
        
        echo "${LimpaDados}" | awk '(NR > 10) {print $0}' > "${RepositorioName}/${V_sw_name}_${V_loop_name}_${V_data}.conf"
        rm -f "${RepositorioTmp}/${IPdm}.tmp"
 }
 
##################################
# Loops
##################################
for IPhp in `grep -v "^#" ${ListaHP}`
do
        ping -c1 "${IPhp}" >> /dev/null
        if [ "$?" -eq "0" ]
        then
                AcessoHP &
                sleep 5
        fi
done
