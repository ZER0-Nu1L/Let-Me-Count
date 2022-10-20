from scapy.all import *
import sys, os

TYPE_LMC = 0x17

class LMC(Packet):
    name = "LMC"
    fields_desc = [
        SignedIntField('num', 0),
    ]
    
bind_layers(IP, LMC, proto=TYPE_LMC)