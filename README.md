# jupyterlab-connect

Connect to a local or remote jupyter lab server, starting it if necessary.

## Install

### Generic

1. Install dependencies: make, argbash and help2man
2. Clone and enter this repo
3. Run `make`
4. Add the absolute path to the `bin` directory (whatever is output from `echo $(pwd)/bin`) to your `$PATH` env var in your `~/.profile` or `~/.bashrc`:
   ```
   export PATH="absolute-path-on-your-machine/jupyterlab-connect/bin:$PATH"
   ```

### NixOS

Option #1

```
git clone https://github.com/ariutta/jupyterlab-connect.git
cd jupyterlab-connect
nix-shell -p pkgs.gnumake -p pkgs.argbash -p help2man --command "make"
```

Option #2

Use [this Nix package expression](https://github.com/ariutta/mynixpkgs/blob/master/jupyterlab-connect/default.nix).

## Usage / Help

```
jupyterlab-connect --help
```
