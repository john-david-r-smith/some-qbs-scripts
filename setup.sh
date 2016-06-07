#!/bin/bash
#settings
config="/rw/config/";
scripts="/rw/config/scripts/";
rc="/rw/config/rc.local";
#global setup
sudo mkdir -p "$scripts";
sudo chmod +x "$rc";
sudo cp *.timer /usr/lib/systemd/system/
sudo cp *.service /usr/lib/systemd/system/

add_to_rc()
{
    if [[ "" == $(grep "$1" "$rc") ]]; then
        echo "$1" >> "$rc";
        echo "added '$1' to your rc";
    fi;
}

#autoshutdown
add_to_rc "systemctl start autoshutdown.timer";
#autocp
sudo dnf install -y inotify-tools;
sudo cp auto-qvm-copy-to-vm.sh "$scripts";
add_to_rc "systemctl start auto-qvm-copy-to-vm.service";
