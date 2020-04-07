# Using argbash

Add CLI arg handling to a script `start.sh` that already exists.

## First Time

Create an argument parser and convert it to a script. Use options as per `argbash-init -h`.

```
argbash-init -ss --pos project --opt volume start.m4
argbash start-parsing.m4 -o start.argbash.sh --strip user-content
rm start.m4 start-parsing.m4
```

Add the following to `start.sh`:

```
############################################
# Handle CLI args with argbash
# To edit CLI args, edit template section of <myscript>.argbash.sh and run argbash:
#   argbash <myscript>.argbash.sh -o <myscript>.argbash.sh
# where <myscript> should be the name of this script, ie., $(basename $0)
source "$0.argbash.sh"
mypositionalarg="$_arg_mypositionalarg"
############################################
```

Use it:

```
./start.sh mypkg --volume myvolume1 --volume myvolume1
```

## Edit Args

Edit template section of `start.argbash.sh` as per the (`argbash` API)[https://argbash.readthedocs.io/en/stable/guide.html#argbash-api]. Then re-run `argbash`:

```
argbash start.argbash.sh -o start.argbash.sh
```

The argument handling is now updated.
