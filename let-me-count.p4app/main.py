import sys
from p4app import P4Mininet, P4Program
from mininet.topo import Topo
from mininet.cli import CLI

if len(sys.argv) > 1:
    if sys.argv[1] == 'compile':
        try:
            P4Program('letmecount.p4').compile()
        except Exception as e:
            print(e)
            sys.exit(1)
        sys.exit(0)

N = 1

def getForwardingPort(s1, s2):
    clockwise = s2 - s1 if s2 > s1 else (N - s1) + s2
    counter_clockwise = (N - s2) + s1 if s2 > s1 else s2 - s1
    return 2 if clockwise < counter_clockwise else 3

def hostIP(i):
    return "10.0.%d.%d" % (i, i)

def hostMAC(i):
    return '00:00:00:00:00:%02x' % (i)

def switchMAC(i):
    return '00:00:00:00:ff:%02x' % (i)

class RingTopo(Topo):
    def __init__(self, n, **opts):
        Topo.__init__(self, **opts)

        switches = []

        for i in range(1, n+1):
            host = self.addHost('h%d' % i,
                                ip = hostIP(i),
                                mac = hostMAC(i))
            switch = self.addSwitch('s%d' % i)
            self.addLink(host, switch, port2=1)
            switches.append(switch)

        # Port 2 connects to the next switch in the ring, and port 3 to the previous
        for i in range(n):
            self.addLink(switches[i], switches[(i+1)%n], port1=2, port2=3)

topo = RingTopo(N)
try:
    net = P4Mininet(program='letmecount.p4', topo=topo)
except Exception as e:
    print(e)
    sys.exit(1)
net.start()

for i in range(1, N+1):
    sw = net.get('s%d'% i)

    # Forward to the host connected to this switch
    sw.insertTableEntry(table_name='MyIngress.ipv4_lpm',
                        match_fields={'hdr.ipv4.dstAddr': [hostIP(i), 32]},
                        action_name='MyIngress.ipv4_forward',
                        action_params={'dstAddr': hostMAC(i), 'port': 1})

    # Otherwise send the packet to another switch
    for j in range(1, N+1):
        if i == j: continue
        sw.insertTableEntry(table_name='MyIngress.ipv4_lpm',
                            match_fields={'hdr.ipv4.dstAddr': [hostIP(j), 32]},
                            action_name='MyIngress.ipv4_forward',
                            action_params={'dstAddr': switchMAC(j), 'port': getForwardingPort(i, j)})

# trailingZeroBits: 
MultiplyDeBruijn32BitPosition = [0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9]
for i in range(32):
    sw.insertTableEntry(table_name='MyIngress.DeBruijn_32_bit_position',
                        match_fields={'hdr.lmc.num': i},
                        action_name='MyIngress.set_lmc_num',
                        action_params={'zero_num': MultiplyDeBruijn32BitPosition[i]})


CLI(net)
