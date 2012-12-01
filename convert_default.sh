#!/bin/bash
convert $1 -resize 640x960  ../Default@2x.png
convert $1 -resize 320x480 ../Default.png
convert $1 -resize 768x1004 ../Default-Portrait.png
convert $1 -resize 1536x2008 ../Default-Portrait@2x.png


