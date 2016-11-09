#!/bin/bash

Repo='git@github.com:ChipwizBen/TheMachine.git'
Directory='/var/www/html/Storage/Git'

cd $Directory
echo "# The Machine" > README.md
echo "# Redirect Configuration" > Redirect/README.md
echo "# Reverse Proxy Configuration" > ReverseProxy/README.md
echo "# D-Shell Command Sets" > CommandSets/README.md
echo "# Distributed Sudoers Management System" > DSMS/README.md
git init
git add README.md
echo -e '*.cgi\n*.pl' > .gitignore
git add Redirect/
git add ReverseProxy/
git add CommandSets/
git add DSMS/
git commit -m "Structure"
git remote add origin $Repo
git push --set-upstream origin master

