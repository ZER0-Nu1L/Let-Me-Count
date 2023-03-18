#!/usr/bin/python
import os
import sys
import random
import argparse
from lmc_header import LMC
from scapy.all import IP, TCP, Ether, sendp, get_if_hwaddr, get_if_list

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
    if (os.getuid() !=0) :
        print ("ERROR: This script requires root privileges.\n Use 'sudo' to run it.")
        quit()
    
    parser = argparse.ArgumentParser()
    parser.add_argument('--control_bit', type=int, default=None, help='0 to initialize, 1 to terminate')
    args = parser.parse_args()

    control_bit = args.control_bit

    ip_1 = random.randint(0, 255)
    ip_2 = random.randint(0, 255)
    ip_3 = random.randint(0, 255)
    ip_4 = random.randint(0, 255)
    
    iface = get_if()
    if (control_bit is not None):
        print("sending control packet to ", iface)
        pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IP(src="{}.{}.{}.{}".format(ip_1, ip_2, ip_3, ip_4)) / LMC(control_bit=control_bit)
    else:
        print("sending TCP packet to ", iface)
        pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
        pkt = pkt / IP(src="{}.{}.{}.{}".format(ip_1, ip_2, ip_3, ip_4))

    # hexdump(pkt)
    # print "len(pkt) = ", len(pkt)
    pkt.show()
    sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()