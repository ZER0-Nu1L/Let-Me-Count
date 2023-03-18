from scapy.all import *
import sys, os

TYPE_LMC = 0x17

class LMC(Packet):
    name = "Let-me-count header"
    fields_desc = [
        ShortField("control_bit", 0),
        ShortField('num', 0)
    ]
    
bind_layers(IP, LMC, proto=TYPE_LMC)