#! /bin/bash

set -e

setserial /dev/ttyS0 spd_cust
setserial /dev/ttyS0 divisor 8
./bot
