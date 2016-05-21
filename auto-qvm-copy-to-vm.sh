#!/bin/bash

#functions
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

        if [ $verbose -eq 1 ]; then
            echo ">>>>>>do_file<<<<<<";
            echo "file  : $loc_file";
            echo "vm    : $loc_vm";
            echo "path  : $loc_p";
            echo "f name: $loc_f";
        fi;

        path_qbs="$path_tmp_files/$loc_vm"
        path_tf="$path_qbs/$loc_p";
        mkdir -p "$path_tf";
        cp -la "$loc_file" "$path_tf";
        qvm-move-to-vm --without-progress "$loc_vm" "$path_qbs";

        if [ $? -eq 0 ]; 
        then 
            #OK => tmp file is gone
            if [ $copy -eq 1 ]; 
            then 
                path_cp="$path_copies/$loc_vm/$loc_p";
                mkdir -p "$path_cp";
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
                mv $loc_file "$target_file";
                if [ $verbose -eq 1 ]; then
                    echo "copied tmp file from:";
                    echo $loc_file;
                    echo "to:";
                    echo "$path_cp/$loc_f";
                fi;
            else
                #rm file
                rm $loc_file;
            fi;
        else
            #failed! => rm tmp file
            rm "$path_tf/$loc_f";
        fi;
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
mkdir -p "$path";
cd "$path";
if ! [ $? -eq 0 ]; then exit 1; fi; 


if [ $verbose -eq 1 ]; then
    echo "path: $path"
    echo "path for copies: $path_copies";
    echo "path for temp files: $path_tmp_files";
    echo "keep a copy: $copy";
    echo "retry: $retry";
fi;

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

