build: argbash doc completions ; echo 'build done'
argbash: ; argbash lib/main.sh -o lib/jupyterlab-connect ; chmod +x lib/jupyterlab-connect

docdirs: ; mkdir -p share/man
#doc: argbash docdirs ; help2man -n "some text here" -N ./bin/jupyterlab-connect -o share/man/jupyterlab-connect.1
doc: argbash docdirs ; help2man -N ./bin/jupyterlab-connect -o share/man/jupyterlab-connect.1
#doc: argbash docdirs ; argbash lib/jupyterlab-connect -o share/man/jupyterlab-connect.1 -t manpage --strip all

completionsdirs: ; mkdir -p share/completions
completions: argbash completionsdirs ; argbash lib/jupyterlab-connect -o share/completions/jupyterlab-connect -t completion --strip all

#.PHONY: clean
#clean: ; rm -rf ./build
