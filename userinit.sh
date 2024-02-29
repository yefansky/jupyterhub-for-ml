#!/bin/bash

directory=/work/$1

if [ ! -d "$directory" ]; then
    mkdir $directory
fi

usermod -a -G conda $1
cp /app/ReadMe.md $directory

#conda create --name tf ipykernel python=3.11 -y
#python -m ipykernel install --user --name tf --display-name "tensorflow"
#conda create --name tc ipykernel -y
#python -m ipykernel install --user --name tc --display-name "pytorch"