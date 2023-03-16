# Let-Me-Count
Collaborate with [Yifan Lin](https://github.com/lin-yifan1).

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
sudo python ./pkt/send.py --control_bit 0
sudo python ./pkt/send.py --control_bit 1
sudo python ./pkt/send.py
```