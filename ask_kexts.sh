#!/bin/sh

all_path=( "$@" )
path_count=${#all_path[@]}
if [[ ! $path_count = 0 ]]; then
 for ((i=0;i<$path_count;i++)) do 
 new_path="$(echo "${all_path[i]}" | xargs)"
 echo "${new_path}" >> ~/.patches.txt
 done
fi