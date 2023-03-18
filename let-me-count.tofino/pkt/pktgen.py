#!/usr/bin/env python
import argparse
import random
import os
from lmc_header import LMC
from scapy.all import IP, TCP, Ether, sendp, get_if_hwaddr, get_if_list, wrpcap

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('replay_pcap_dir', default=None)
    parser.add_argument('-n', '--pkt_num', type=int, default=2500)
    
    args = parser.parse_args()
    workdir = os.getcwd()
    pcap_dir = os.path.join(workdir, args.replay_pcap_dir)
    if not os.path.exists(pcap_dir) or not os.path.isdir(pcap_dir):
        print("replay_pcap_dir not exists, now create it for you.")
        os.makedirs(pcap_dir)
    
    pkt_list = []
    iface = get_if()
    for i in range(args.pkt_num): 
        ip_1 = random.randint(0, 255)
        ip_2 = random.randint(0, 255)
        ip_3 = random.randint(0, 255)
        ip_4 = random.randint(0, 255)
        pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff') / IP(src="{}.{}.{}.{}".format(ip_1, ip_2, ip_3, ip_4))
        pkt_list.append(pkt)


    workdir = os.getcwd()
    pcap_dir = os.path.join(workdir, args.replay_pcap_dir)
    pcap_name = 'test.pcap'

    wrpcap(pcap_dir + '/' + pcap_name, pkt_list)
    print('Finish pktgen with ' + str(args.pkt_num) + ' pkts.')
    
if __name__ == '__main__':
    main()