call H:\Apps\LocalSetup.bat

:: if there are no arguments we are done; else run the argument
if "%1"=="" goto:eof
Rscript %*
