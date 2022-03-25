rem chcp 1251
rem @echo off

rem Створюємо перемінні
set m=%date:~3,2%
set d=%date:~0,2%
set y=%date:~6,4%
set tm=%TIME: =0%
set h=%tm:~0,2%
set min=%time:~3,2%
set sec=%time:~6,2%

rem Перемінні шляхів, розширення архіву, к-сті збереження архіву
set TempBackupDir="C:\Backup\temp"
set BackupDir="C:\BackUp\dump"
set Cloud="Z:\Era"
set Ext_backup=*.zip
set BakFiles=*.bak
set Max_backup=5
set CUser=PMK--ERA
set CPass=12345678

rem Шляхи до ПЗ
set arh="C:\Program Files\7-Zip\7z.exe"
set sql="C:\Program Files\Microsoft SQL Server\110\Tools\Binn\osql.exe"
set net="c:\Program Files\NetDrive2\nd2cmd.exe"

rem Назва БД SQL шо архівується
set DB=Retail

rem Створюєм бекап БД SQL за іменем бази
%sql% -S localhost -U sa -P "PASSWORD" -Q "BACKUP DATABASE %DB% TO DISK='%TempBackupDir%\%y%-%m%-%d%_%h%-%min%-%DB%.bak'"

rem Створюєм архів
for %%a in ("%TempBackupDir%\*.bak") do (start "Create zip arh" /wait %arh% a "%TempBackupDir%\%%~na.zip" -TZIP -mx5 "%%a")
if %errorlevel%==0 erase %TempBackupDir%\%BakFiles%

rem Вивантажуємо файли в сховище
%net% -c m -t dav -u https://intellect.dyndns-office.com/remote.php/dav/files/%CUser% -a %CUser% -p %CPass% -d z -l own
copy %TempBackupDir%\%Ext_backup% %Cloud%
rem Очищуэмо архіви у хмарі більше вказаного числа
for /f "skip=%Max_backup% tokens=*" %%i in ('dir %Cloud%\%Ext_backup% /b /tw /a-d /o-d') Do ERASE %Cloud%\%%i

rem Копіюєм архів в місце призначення та залишаєм необхідну кількість архівів вказану в перемінній Max_backup
copy %TempBackupDir%\%Ext_backup% %BackupDir%
if %errorlevel%==0 erase %TempBackupDir%\%Ext_backup%

rem Очищуємо архіви локально більше вказаного числа
for /f "skip=%Max_backup% tokens=*" %%i in ('dir %BackupDir%\%Ext_backup% /b /tw /a-d /o-d') Do ERASE %BackupDir%\%%i

rem Очищуємо тимчасову папку
DEL /Q %TempBackupDir%\*.*

rem robocopy %BackupDir% %Cloud% /PURGE /R:1 /LOG+:copy.log
TIMEOUT /T 1800
rem Відключаємо мережевий диск
%net% -c u -d z
