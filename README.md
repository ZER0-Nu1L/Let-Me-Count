# Let-Me-Count

## p4app
```Bash
git submodule update --init
cd p4app
git checkout rc-2.0.0
cd ..
cd ./let-me-count.p4app
```

split your terminal to several terminals.
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