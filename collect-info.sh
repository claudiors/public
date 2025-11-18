#!/bin/bash

# ============================================
# SCRIPT DE COLETA DE INFORMAÇÕES - PROXMOX
# Autor: Claude
# Data: 2025-11-18
# ============================================

echo "============================================"
echo "COLETA DE INFORMAÇÕES DO AMBIENTE PROXMOX"
echo "============================================"
echo ""
echo "Iniciando coleta em: $(date)"
echo ""

# ============================================
# 1. INFORMAÇÕES DO HOST PROXMOX
# ============================================
echo "============================================"
echo "1. INFORMAÇÕES DO HOST PROXMOX"
echo "============================================"
echo ""

echo "--- Versão do Proxmox ---"
pveversion -v
echo ""

echo "--- Hostname ---"
hostname
echo ""

echo "--- Informações de Hardware ---"
echo "CPU:"
lscpu | grep -E "^Model name|^CPU\(s\)|^Thread|^Core"
echo ""
echo "Memória:"
free -h
echo ""
echo "Disco:"
df -h | grep -E "Filesystem|/dev/|zfs"
echo ""

echo "--- Interfaces de Rede ---"
ip -br addr show
echo ""

# ============================================
# 2. BRIDGES E REDES VIRTUAIS
# ============================================
echo "============================================"
echo "2. CONFIGURAÇÃO DE BRIDGES E REDES"
echo "============================================"
echo ""

echo "--- Bridges Disponíveis ---"
brctl show 2>/dev/null || ip link show type bridge
echo ""

echo "--- Configuração de Rede do Proxmox ---"
cat /etc/network/interfaces
echo ""

# ============================================
# 3. STORAGE POOLS
# ============================================
echo "============================================"
echo "3. STORAGE POOLS (ZFS)"
echo "============================================"
echo ""

echo "--- ZFS Pools ---"
zpool list
echo ""

echo "--- ZFS Datasets ---"
zfs list
echo ""

echo "--- Storage do Proxmox ---"
pvesm status
echo ""

# ============================================
# 4. VMs EXISTENTES
# ============================================
echo "============================================"
echo "4. LISTA DE VMs"
echo "============================================"
echo ""

qm list
echo ""

# ============================================
# 5. CONFIGURAÇÃO DETALHADA DE CADA VM
# ============================================
echo "============================================"
echo "5. CONFIGURAÇÃO DETALHADA DAS VMs"
echo "============================================"
echo ""

# Obter lista de VMIDs
VMIDS=$(qm list | awk 'NR>1 {print $1}')

for VMID in $VMIDS; do
    echo "=========================================="
    echo "VM $VMID - Configuração Completa"
    echo "=========================================="
    
    # Nome e status
    echo "--- Informações Básicas ---"
    qm status $VMID
    echo ""
    
    # Configuração completa
    echo "--- Configuração (qm config) ---"
    qm config $VMID
    echo ""
    
    # Rede específica
    echo "--- Configuração de Rede ---"
    qm config $VMID | grep -E "^net|^ipconfig"
    echo ""
    
    # Hardware
    echo "--- Hardware ---"
    qm config $VMID | grep -E "^cores|^memory|^cpu"
    echo ""
    
    # Discos
    echo "--- Discos ---"
    qm config $VMID | grep -E "^scsi|^ide|^sata|^virtio"
    echo ""
    
    echo ""
done

# ============================================
# 6. CONTAINERS LXC (se houver)
# ============================================
echo "============================================"
echo "6. CONTAINERS LXC"
echo "============================================"
echo ""

if command -v pct &> /dev/null; then
    echo "--- Lista de Containers ---"
    pct list
    echo ""
    
    # Configuração de cada container
    CTIDS=$(pct list | awk 'NR>1 {print $1}')
    
    for CTID in $CTIDS; do
        echo "=========================================="
        echo "Container $CTID - Configuração"
        echo "=========================================="
        pct config $CTID
        echo ""
    done
else
    echo "Nenhum container LXC encontrado"
    echo ""
fi

# ============================================
# 7. FIREWALL PROXMOX
# ============================================
echo "============================================"
echo "7. CONFIGURAÇÃO DE FIREWALL"
echo "============================================"
echo ""

echo "--- Status do Firewall ---"
cat /etc/pve/firewall/cluster.fw 2>/dev/null || echo "Firewall do cluster não configurado"
echo ""

# Firewall por VM
for VMID in $VMIDS; do
    if [ -f "/etc/pve/firewall/${VMID}.fw" ]; then
        echo "--- Firewall da VM $VMID ---"
        cat /etc/pve/firewall/${VMID}.fw
        echo ""
    fi
done

# ============================================
# 8. TESTE DE CONECTIVIDADE ENTRE VMs
# ============================================
echo "============================================"
echo "8. TESTE DE CONECTIVIDADE"
echo "============================================"
echo ""

# IPs conhecidos para testar
declare -A VM_IPS=(
    [240]="192.168.0.240"
    [241]="192.168.0.241"
    [242]="192.168.0.242"
    [243]="192.168.0.243"
)

echo "--- Ping entre VMs (do Host Proxmox) ---"
for VMID in "${!VM_IPS[@]}"; do
    IP="${VM_IPS[$VMID]}"
    echo -n "VM $VMID ($IP): "
    ping -c 1 -W 2 "$IP" > /dev/null 2>&1 && echo "✅ ONLINE" || echo "❌ OFFLINE"
done
echo ""

echo "--- Portas Abertas (do Host Proxmox) ---"
for VMID in "${!VM_IPS[@]}"; do
    IP="${VM_IPS[$VMID]}"
    echo "VM $VMID ($IP):"
    
    # Testar portas comuns
    for PORT in 22 80 443 5432 6379 9000; do
        timeout 2 bash -c "echo >/dev/tcp/$IP/$PORT" 2>/dev/null && \
            echo "  ✅ Porta $PORT: ABERTA" || \
            echo "  ❌ Porta $PORT: FECHADA"
    done
    echo ""
done

# ============================================
# 9. ROTEAMENTO E DNS
# ============================================
echo "============================================"
echo "9. ROTEAMENTO E DNS"
echo "============================================"
echo ""

echo "--- Tabela de Roteamento ---"
ip route show
echo ""

echo "--- DNS Configurado ---"
cat /etc/resolv.conf
echo ""

# ============================================
# 10. LOGS RECENTES
# ============================================
echo "============================================"
echo "10. LOGS RECENTES (últimas 20 linhas)"
echo "============================================"
echo ""

echo "--- Syslog ---"
tail -20 /var/log/syslog
echo ""

echo "--- Daemon Log ---"
tail -20 /var/log/daemon.log
echo ""

# ============================================
# FINALIZAÇÃO
# ============================================
echo "============================================"
echo "COLETA FINALIZADA"
echo "============================================"
echo ""
echo "Data de conclusão: $(date)"
echo ""
echo "============================================"
echo "INSTRUÇÕES:"
echo "1. Copie TODA a saída deste script"
echo "2. Cole na conversa com o Claude"
echo "3. Aguarde análise completa"
echo "============================================"
