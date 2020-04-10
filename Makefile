build: argbash doc completion ; echo 'build done'
argbash: ; argbash src/main.sh -o src/jupyterlab-connect ; chmod +x src/jupyterlab-connect
docdirs: ; mkdir -p share/man
#doc: argbash docdirs ; help2man -n "some text here" -N ./bin/jupyterlab-connect -o share/man/jupyterlab-connect.1
doc: argbash docdirs ; help2man -N ./bin/jupyterlab-connect -o share/man/jupyterlab-connect.1
completiondirs: ; mkdir -p share
completion: argbash completiondirs ; argbash src/jupyterlab-connect -o share/completion.bash -t completion ; chmod +x share/completion.bash ; pwd ; ls -la ./*
#doc: argbash docdirs ; argbash src/jupyterlab-connect -o share/man/jupyterlab-connect.1 -t manpage --strip all

#.PHONY: clean
#clean: ; rm -rf ./build
