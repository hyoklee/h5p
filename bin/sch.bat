schtasks /create /sc daily /st 23:00 /tn h5 /tr d:\h5p\bin\f.r.bat
schtasks /query /tn h5 /v
REM schtasks /delete /tn h5 /f
REM schtasks /create /sc daily /st 11:00 /tn clio /tr d:\h5p\bin\clio.r.bat
REM schtasks /query /tn clio /v
REM schtasks /delete /tn clio /f
schtasks /create /sc daily /st 17:00 /tn clio_dev /tr d:\h5p\bin\clio_dev_r_c.bat
REM schtasks /query /fo list

