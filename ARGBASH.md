# Using argbash

Add CLI arg handling to an existing script named `src/start.sh`.

## First Time

Create an argument parser and convert it to a script. Use options as per `argbash-init -h`.

```
argbash-init -ss --pos project --opt volume src/start.m4
argbash src/start-parsing.m4 -o src/start.argbash.sh --strip user-content
chmod -x src/start.argbash.sh
rm src/start.m4 src/start-parsing.m4
```

Add the following to `src/start.sh`:

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
./bin/start mypkg --volume myvolume1 --volume myvolume1
```

## Edit Args

Edit template section of `src/start.argbash.sh` as per the [`argbash` API](https://argbash.readthedocs.io/en/stable/guide.html#argbash-api). Then re-run `argbash`:

```
argbash src/start.argbash.sh -o src/start.argbash.sh
# this isn't looking correct:
#argbash src/start.argbash.sh -t manpage -o share/man/start.1
argbash src/start.argbash.sh -t completion -o share/completions.bash
```

You should now see that the argument handling is updated.
