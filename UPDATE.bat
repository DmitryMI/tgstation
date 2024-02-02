rem @echo off

git fetch upstream
call bin\clean.cmd
call BUILD.cmd
