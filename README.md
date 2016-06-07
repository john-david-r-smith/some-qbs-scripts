# some-qbs-scripts

the name says everything.  
**use at your own risk** (it may go wrong, set your pc on fire and kill your cat (even if you don't own one))

## How to install
Clone the repo in your domU and run `sudo ./setup.sh`.

## Stuff for Dom0
Set all cpu-counts to 1:  
    `qvm-ls --raw-list|xargs -I % qvm-prevs -s % vcpus 1`
