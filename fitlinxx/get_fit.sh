#!/bin/bash

OUT=/home/fifors/fit.table
LOG=/home/fifors/fit.log
PL=/home/fifors/fit-test.pl

perl ${PL} 2> /dev/null > ${OUT}
scp -q ${OUT} ragnarak.com:fit.table
echo run fit-test.pl at `date` >> ${LOG}
