## TODO:

- [X] Decompile physics
- []  Rewrite physics to python
- []  Train PPO RL algo or other, experiment
- []  Decompile game assets and build python clone

## Decompilation guide:

1. Install JPEXS decompiler:


```bash
sudo apt update
sudo apt install default-jre

wget https://github.com/jindrapetrik/jpexs-decompiler/releases/download/version24.1.0/ffdec_24.1.0.deb

sudo dpkg -i ffdec_24.1.0.deb

ffdec
```

2. In decompiler open `decompiled/Flight of the Hamsters.swf` file.
