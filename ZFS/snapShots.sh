#!/bin/bash

TODAY=$(date +%d%m%y-%H%M)

zfs snapshot pool01/NSCC@$TODAY
