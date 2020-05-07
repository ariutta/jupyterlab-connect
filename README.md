# jupyterlab-connect

Connect to a local or remote Jupyter server. If server isn't already running, start it. If server is remote, create an SSH tunnel to make the remote Jupyter server accessible to your browser on your local machine. Optionally, create one or more additional SSH tunnels to connect your Jupyter server to other remote servers, such as database servers.

## Install

### Generic

1. Install dependencies: make, argbash and help2man
2. Clone and enter this repo
3. Run `make`
4. Add the absolute path to the `bin` directory (whatever is output from `echo "$(pwd)/bin"`) to your `$PATH` environment variable in your `~/.profile`, `~/.bash_profile` or `~/.bashrc`:
   ```
   export PATH="escaped-absolute-path-on-your-machine/jupyterlab-connect/bin:$PATH"
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

## TODO

Maybe this library would be useful: https://github.com/TimidRobot/cmc
