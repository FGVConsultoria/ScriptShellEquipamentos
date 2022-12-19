Informações de cada script :

1. monitoratemperatura.sh - Script que captura a temperatura dos mikrotik`s e alarma em um canal do Telegram quando chega na temperatura limite aceitável.

2. monitoramodulosdm.sh - Script que monitora a instalação e remoção dos módulos ópticos nos DMs modelo 4170 e 4270, ao identificar alteração de status envia uma mensagem para um canal do Telegram.

3. monitoramodulosdm4100.sh - Scripit voltado para monitorar a instalação e remoção dos módulos nos DM4100 que tem plataforma diferente dos DMs 4170, 4270, ele também envia mensagem para o grupo de Telegram.

4. liberaaccesslistdm.sh - Script que libera um IP específico na access list dos DMs 4170, 4270 e 4770

5. Script que faz backup dos switchs HP da rede.

6. atualiza_mk.sh - Apesar de existir o protocolo RoMON (Protocolo proprietário) nos mikrotiks, que foi Introduzido a partir da versão 6.28 do RouterOS de fácil configuração, muitos gestores ainda não se sentem seguros no uso do protocolo para automação de rotinas de configuração e atualização dos routers, por isso fiz o script para atualização programada via SSH dos mesmos, que pode ser usado para a programação de todos e/ou por modelo e por área de atendimento da rede, apenas sendo feito a lista de IPs seguindo estes critérios.

7. Backup Mikrotik - Script para rodar nos mikrotik`s para agendar o backup por email, este script não foi criado por mim, mas apenas alterei para o usuário informar as variáveis sem ter que alterar no meio do código, sinceramente a tanto tempo que o tenho que não me lembro de onde baixei para referenciar aqui e dar o mérito ao criador.

8. lista_equipamento.sh - Script gera uma lista de equipamentos a partir de uma rede declarada, ele busca pelos MAC`s os equipamentos da rede e identifica o fabricante.
