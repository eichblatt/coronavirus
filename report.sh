#!/bin/bash

cd $HOME/projects/coronavirus
echo "$Q daily_corona_report.q -debug 0"
$Q daily_corona_report.q -debug 0
sleep 1
git commit -am "latest"
git push

