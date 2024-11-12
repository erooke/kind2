#!/usr/bin/env bash
html_path=../../_doc/_html
# get name of internal library
lib_name=$(ls $html_path | grep kind2dev)
# copy ./include dir into library documentation dir
cp -r ./include "$html_path/$lib_name"
# compile index.mld into page-index.odoc file
odoc compile --pkg="$lib_name" index.mld
# convert page-index.odoc to index.html and resolve links to other webpages
odoc html ./page-index.odoc -I ../.kind2dev.objs/byte --output $html_path
# replace all instances of kind2 with lib_name
sed "s/kind2/$lib_name/g" $html_path/index.html > $html_path/index.html_tmp
mv $html_path/index.html_tmp $html_path/index.html
