# jupyterlab-connect

Connect to a local or remote Jupyter server. If server isn't already running, start it. If server is remote, create an SSH tunnel to make the remote Jupyter server accessible to your browser on your local machine. Optionally, create one or more additional SSH tunnels to connect your Jupyter server to other remote servers, such as database servers.

## Install

If you have the [Nix package manager](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html) installed, you can install `jupyterlab-connect` with [this Nix package expression](https://github.com/ariutta/mynixpkgs/blob/master/jupyterlab-connect/default.nix).

If you don't have Nix installed, you currently need to build from source (see "How to Build" below).

## Usage / Help

```
jupyterlab-connect --help
```

# How to Build

```
git clone https://github.com/ariutta/jupyterlab-connect.git
cd jupyterlab-connect
```

If you're using the [Nix package manager](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html) and [direnv](https://direnv.net/), just enter this directory and run `make`.

If you have the [Nix package manager](https://nixos.org/guides/nix-pills/why-you-should-give-it-a-try.html) installed but not direnv, run this:

```
nix-shell -p pkgs.gnumake -p pkgs.argbash -p help2man --command "make"
```

Otherwise, you'll need to install the dependencies [make](https://www.gnu.org/software/make/), [argbash](https://argbash.io/), [help2man](https://www.gnu.org/software/help2man/) and [jq](https://stedolan.github.io/jq/) before running `make`. You'll also need to add the absolute path to the `bin` directory (whatever is output from `echo "$(pwd)/bin"`) to your `$PATH` environment variable in your `~/.profile`, `~/.bash_profile` or `~/.bashrc`:

```
export PATH="escaped-absolute-path-on-your-machine/jupyterlab-connect/bin:$PATH"
```

Notes:

- `argbash` generates `./lib/jupyterlab-connect` from `./lib/main.sh`. To make changes to `./lib/jupyterlab-connect`, edit `./lib/main.sh` and rebuild. (For reference, [here](https://github.com/ariutta/jupyterlab-connect/blob/b8c711c005f9e2ae2752312350a39c699f9679ae/ARGBASH.md) is the old ARGBASH.md file.)
- The file `./bin/jupyterlab-connect` is a simple wrapper that sends any calls on to `./lib/jupyterlab-connect`.

This command can be used to sync a remote and local repo during development and then run it:

```
clear; scp -r nixos:Documents/jupyterlab-connect/* ~/jupyterlab-connect/ && jupyterlab-connect --no-browser nixos:Documents/pathway-figure-ocr/notebooks
```

## TODO

- Maybe this library would be useful: https://github.com/TimidRobot/cmc
- Figure out an easy option to reconnect when SSH session dies.
- For macOS, look at using `caffeinate -i -s /usr/bin/ssh` to control sleep & disconnects.
