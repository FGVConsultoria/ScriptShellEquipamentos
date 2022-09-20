#!/bin/sh

######################################
# Dados do ssh
######################################
OpcoesSSH="-o UserKnownHostsFile=/dev/null -o HostKeyAlgorithms=+ssh-dss -o StrictHostKeyChecking=no -o KexAlgorithms=+diffie-hellman-group1-sha1"
PortaSSH="22"
UserSSH="user"
SenhaSSH="SenhaDoUser"

######################################
# Dados do Telegram
######################################
Canal="CanalTelegram"
BotId="ChaveBotTelegram"

######################################
# Busca os IPs de LoopBack dos MKs
######################################
IPsMks="./ListaDeIps"

######################################
# Temperatura de alarme
######################################
TmpMax="650"

######################################
# Loop para busca
######################################
for V_ip in `cat ${IPsMks}`
do

        ping -c1 ${V_ip} >/dev/null 2>&1

        [ "${?}" != "0" ] && continue

        V_tmp=`snmpwalk -v1 -c "*routerinfo*" ${V_ip} .1.3.6.1.4.1.14988.1.1.3.10.0 | awk '{print $NF}'`

        [ ! "${V_tmp}" ] && continue

        if [ "${V_tmp}" -ge "${TmpMax}" ]
        then
                V_identity=`sshpass -p "${SenhaSSH}" ssh ${OpcoesSSH} -p${PortaSSH} "${UserSSH}@${V_ip}" /system identity print | awk '{print $2}'`
                V_tmpc=`echo "scale=1; ${V_tmp}/10" | bc`

                V_msg="${V_msg}
${V_tmpc} ${V_ip} ${V_identity}"
        fi
done

######################################
# Envia mensagem para o Telegram
######################################
if [ ! -z "${V_msg}" ]
then
        V_msgFinal=`echo "${V_msg}" | sort -t1 -r -h | uniq | awk 'BEGIN{print "ALERTA DE TEMPERATURA\n=======================\n"} ($0 != "") {print $3"\n"$2"\n"$1"\n"}'`
        links -dump 'https://api.telegram.org/bot'${BotId}'/SendMessage?chat_id='${Canal}'&text="'"${V_msgFinal}"'"'
fi

