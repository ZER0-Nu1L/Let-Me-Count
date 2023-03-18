# Let-Me-Count
Collaborate with [Yifan Lin](https://github.com/lin-yifan1).

> Median trick is implemented on the 'median-trick' branch. (Only Tofino version).

```Bash
git clone https://github.com/ZER0-Nu1L/Let-Me-Count.git
cd Let-Me-Count
git submodule update --init
```

## p4app version
```Bash
cd ./let-me-count.p4app
```

split your terminal to several panes.
(terminal0)
```Bash
sudo make run
```

(terminal1)
```Bash
sudo make h1
./receive.py
```

(terminal2)
```Bash
sudo make h1
./send.py 10.0.1.1 "123"
```

## Tofino version
This release assumes that you have access to Barefoot SDE and that you have configured the basic environment.

```Bash
cd ./let-me-count.tofino
```

Pplit your terminal to several panes and execute `. ~/tools/set_sde.bash` for all of them.

(terminal1)
```Bash
~/tools/p4_build.sh ./p4src/letmecount.p4
```

(terminal2)(if on Tofino model)

```Bash
sudo ~/tools/veth_setup.sh
$SDE/run_tofino_model.sh -p letmecount --log-dir ./logs

# ...
# In the end 
sudo ~/tools/veth_teardown.sh
```

(terminal3)
```Bash
$SDE/run_switchd.sh -p letmecount
```

(terminal4)
```Bash
$SDE/run_bfshell.sh -b ./bfrt_python/setup.py [-i]
```
> Use -i to stay in the interactive mode after the script has been executed.

(terminal5)
```Bash
sudo python ./pkt/recv.py veth2
```

(terminal6)
```Bash
# Reset
sudo python ./pkt/send.py --control_bit 0
# pktgen & replay
sudo python ./pkt/pktgen.py pkt/mypcap -n 1500
sudo tcpreplay -i veth1 -M 0.1 ./pkt/mypcap/test.pcap
# check
sudo python ./pkt/send.py --control_bit 1
```

You can see demo video below:

- [Let-me-count[dark-version].mp4](https://drive.google.com/file/d/1EfQDGpLYPSOLNCY63UuZH3dMBAla6fAw/view?usp=share_link) 

- [Let-me-count[light-version].mp4](https://drive.google.com/file/d/12jTdf0rTrlbDcpo8arQAVnUOX4ZCpAvS/view?usp=sharing)