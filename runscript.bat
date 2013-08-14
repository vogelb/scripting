@echo off
cd /D %~dp1
set CHERE_INVOKING=1
C:\cygwin\bin\bash.exe -li %*
