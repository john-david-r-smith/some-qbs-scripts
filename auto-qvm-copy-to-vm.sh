#!/bin/bash

#functions
vecho()
{
    if [ $verbose -eq 1 ]; then echo "$1"; fi;
}
do_file()
{
if [ -f "$1" ]; then
    [[ "$1" =~ \./(.*) ]];
    loc_file=${BASH_REMATCH[1]};
    if [[ "$loc_file" =~ ([^/]*)/?(.*)/([^/]*) ]]; then
        loc_vm=${BASH_REMATCH[1]};
        loc_p=${BASH_REMATCH[2]};
        loc_f=${BASH_REMATCH[3]};

        if [ $loc_vm == $path_tmp_files ]; then continue; fi;
        if [ $loc_vm == $path_copies    ]; then continue; fi;

        vecho ">>>>>>do_file<<<<<<";
        vecho "file  : $loc_file";
        vecho "vm    : $loc_vm";
        vecho "path  : $loc_p";
        vecho "f name: $loc_f";
        
        path_qbs="$path_tmp_files/$loc_vm"
        path_tf="$path_qbs/$loc_p";
        sudo -u user mkdir -p "$path_tf";
        vecho "> cp -la '$loc_file' '$path_tf'";
        sudo -u user cp -la "$loc_file" "$path_tf";
        cd "$path_qbs";
        qvm-copy-to-vm --without-progress "$loc_vm" .;
        if [ $? -eq 0 ]; 
        then 
            vecho "> cd '$path'";
            cd "$path";
            #OK
            vecho "SUCCESS: qvm-copy";
            if [ $copy -eq 1 ]; 
            then 
                vecho "creating a copy";
                path_cp="$path_copies/$loc_vm/$loc_p";
                sudo -u user mkdir -p "$path_cp";
                #search for a free filename
                target_file_base="$path_cp/$loc_f";
                target_file="$path_cp/$loc_f";
                line="_";
                cnt=1;
                while [ -e "$target_file" ]; do
                    cnt=$((cnt+1));
                    target_file="$target_file_base$line$cnt"; 
                done;
                #move
                sudo -u user mv "$loc_file" "$target_file";
                vecho "copied file from:";
                vecho $loc_file;
                vecho "to:";
                vecho "$path_cp/$loc_f";
            else
                #rm file
                vecho "> rm '$loc_file'";
                rm $loc_file;
            fi;
        else
            vecho "> cd '$path'";
            cd "$path";
            #failed! => rm tmp file
            vecho "FAIL: qvm-copy";
            vecho "> rm '$path_tf/$loc_f'"
            rm "$path_tf/$loc_f";
        fi;
        vecho "> rm '$path_tf/$loc_f'"
        rm "$path_tf/$loc_f";
        vecho "cleaning empty subdirs in '$path_tmp_files'";
        find "$path_tmp_files" -type d -empty -delete;
    fi;
fi;
}

print_help=0;
retry=0;
copy=0;
path="/home/user/QubesOutgoing";
verbose=0;
do_file_deactivated=0;

path_tmp_files="_tmp";
path_copies="_copy";

for a
do
    if [  "$a" == "--help"      ]; then print_help=1           ; fi;
    if [  "$a" == "--retry"     ]; then retry=1                ; fi;
    if [  "$a" == "--verbose"   ]; then verbose=1              ; fi;
    if [  "$a" == "--keep-copy" ]; then copy=1                 ; fi;
    if [[ "$a" =~ --path=(.*)  ]]; then path=${BASH_REMATCH[1]}; fi;
done;

#help?
if [ $print_help -eq 1 ]; then
    echo "auto-qvm-copy-to-vm [OPTIONS]...";
    echo "";
    echo "watches a directory and moves all files from subfolders,";
    echo "to the vm defined by the subfolder's name.";
    echo "";
    echo "EXAMPLE:";
    echo "    a file:";
    echo "    'watched_dir/source_vmname/path/file'";
    echo "    will be send to the vm 'vmname' and stored in:";
    echo "    '~/QubesIncomming/vmname/path/file'";
    echo "";
    echo "OPTIONS:";
    echo "    --help       print this help";
    echo "    --retry      retry failed copies";
    echo "    --verbose    be verbose";
    echo "    --path=...   watch the given path";
    echo "    --keep-copy  keeps a copy in the subfolder _copy";
    exit 0;
fi;

#make path
sudo -u user mkdir -p "$path";
cd "$path";
if ! [ $? -eq 0 ]; then exit 1; fi; 

vecho "path: $path"
vecho "path for copies: $path_copies";
vecho "path for temp files: $path_tmp_files";
vecho "keep a copy: $copy";
vecho "retry: $retry";

inotifywait -r -e moved_to -e create --format "%w%f" -m -q . \
    | while read file; do
        if ! [ -f "$file"                      ]; then continue; fi; #trigger on files
        if [[ "$file" =~ \./$path_tmp_files/.* ]]; then continue; fi; #not on tmp files
        if [[ "$file" =~ \./$path_copies/.*    ]]; then continue; fi; #not on copies
        if [[ "$file" =~ \./[^/]*$             ]]; then continue; fi; #not on files in no subdir
        if [ $retry -eq 1 ]; 
        then
            find . -type f| while read fle; do do_file "$fle"; done;
        else
            do_file $file;
        fi;
    done;

