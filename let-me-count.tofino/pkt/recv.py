#!/usr/bin/python

import os
import sys
from scapy.all import IP, TCP, UDP, Raw
from lmc_header import LMC

def handle_pkt(pkt):
    if LMC in pkt or (TCP in pkt and pkt[TCP].dport == 1234):
        print("got a packet")
        pkt.show()
    #    hexdump(pkt)
        if LMC in pkt:
            print(pkt[LMC].num)
            print(type(pkt[LMC].num))
            print(bin(pkt[LMC].num))
            
        sys.stdout.flush()

if os.getuid() !=0:
    print """
ERROR: This script requires root privileges. 
       Use 'sudo' to run it.
"""
    quit()

from scapy.all import *
try:
    iface=sys.argv[1]
except:
    iface="veth1"

print "Sniffing on ", iface
print "Press Ctrl-C to stop..."
sniff(iface=iface, prn = lambda x: handle_pkt(x))

