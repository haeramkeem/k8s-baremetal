#!/bin/bash

for imgName in $(ls ./images/*.tar); do
    docker load < $imgName
    rm -rf $imgName
done
