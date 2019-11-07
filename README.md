robonomics_dev
==============

Requirements
------------

1. Ubuntu 18.04 (Bionic Beaver) or later

Setting up the environment
--------------------------

1. Clone this repo:

```
git clone --recursive https://github.com/airalab/robonomics_dev
```

2. Run initialization script:

```
cd robonomics_dev
./robonomics.sh init
```

> At the first time this script installs [Nix package manager](https://nixos.org/nix/) and `robonomics_comm`, creates `keyfile` and `keyfile_password_file` files


3. There are two available networks: Mainnet and Sidechain. It's recommended to use Sidechain for the development:

```
./robonomics.sh sidechain
```

Now robonomics_comm should be up and running

In addition the script generates two files `env.bash`, `env.zsh`. You should source one of them during development to make ROS environment working

