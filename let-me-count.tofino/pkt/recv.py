#!/usr/bin/python

import os
import sys
from scapy.all import IP, TCP, UDP, Raw, sniff
from lmc_header import LMC

def handle_pkt(pkt):
    if LMC in pkt:
        print("got a packet:")
        pkt.show()
    #    hexdump(pkt)
        if LMC in pkt:
            print(pkt[LMC].num)
            print(type(pkt[LMC].num))
            print(bin(pkt[LMC].num))
        print("The number of distinct ip addresses is {}".format(2**0.5 * 2**pkt[LMC].num))
        sys.stdout.flush()

def main():
    if (os.getuid() !=0) :
        print ("ERROR: This script requires root privileges.\n Use 'sudo' to run it.")
        quit()
    try:
        iface=sys.argv[1]
    except:
        iface="veth0"

    print("Sniffing on ", iface)
    print("Press Ctrl-C to stop...")
    sniff(iface=iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()