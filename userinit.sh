#!/bin/bash

directory=/work/$1

if [ ! -d "$directory" ]; then
    mkdir $directory
fi
