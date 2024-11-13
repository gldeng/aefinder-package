#! /bin/bash
ip=$(ifconfig | awk '/inet / && !/127.0.0.1/ {print $2; exit}')
kurtosis run . "{\"advertised_ip\":\"$ip\"}"