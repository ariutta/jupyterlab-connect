# jupyterlab-connect

Connect to a local or remote jupyter lab server, starting it if necessary.

## Install

### Generic

1. Install dependencies: make, argbash and help2man.
2. Clone and enter this repo.
3. Run `make`.

### NixOS

Option #1

```
git clone https://github.com/ariutta/jupyterlab-connect.git
cd jupyterlab-connect
nix-shell -p pkgs.gnumake -p pkgs.argbash -p help2man
make
# Ctrl-d to exit
```

Option #2

Use this Nix package expression:
https://github.com/ariutta/mynixpkgs/blob/master/jupyterlab-connect/default.nix

## Help

```
jupyterlab-connect --help
```
