rem @echo off

git checkout master
git fetch upstream
git rebase upstream/master
call bin\clean.cmd
call BUILD.cmd
