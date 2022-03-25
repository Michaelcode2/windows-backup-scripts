rem chcp 1251
rem @echo off

rem ��������� �������
set m=%date:~3,2%
set d=%date:~0,2%
set y=%date:~6,4%
set tm=%TIME: =0%
set h=%tm:~0,2%
set min=%time:~3,2%
set sec=%time:~6,2%

rem ������� ������, ���������� ������, �-�� ���������� ������
set TempBackupDir="C:\Backup\temp"
set BackupDir="C:\BackUp\dump"
set Cloud="Z:\Era"
set Ext_backup=*.zip
set BakFiles=*.bak
set Max_backup=5
set CUser=PMK--ERA
set CPass=12345678

rem ����� �� ��
set arh="C:\Program Files\7-Zip\7z.exe"
set sql="C:\Program Files\Microsoft SQL Server\110\Tools\Binn\osql.exe"
set net="c:\Program Files\NetDrive2\nd2cmd.exe"

rem ����� �� SQL �� ����������
set DB=Retail

rem �������� ����� �� SQL �� ������ ����
%sql% -S localhost -U sa -P "PASSWORD" -Q "BACKUP DATABASE %DB% TO DISK='%TempBackupDir%\%y%-%m%-%d%_%h%-%min%-%DB%.bak'"

rem �������� �����
for %%a in ("%TempBackupDir%\*.bak") do (start "Create zip arh" /wait %arh% a "%TempBackupDir%\%%~na.zip" -TZIP -mx5 "%%a")
if %errorlevel%==0 erase %TempBackupDir%\%BakFiles%

rem ����������� ����� � �������
%net% -c m -t dav -u https://intellect.dyndns-office.com/remote.php/dav/files/%CUser% -a %CUser% -p %CPass% -d z -l own
copy %TempBackupDir%\%Ext_backup% %Cloud%
rem �������� ������ � ���� ����� ��������� �����
for /f "skip=%Max_backup% tokens=*" %%i in ('dir %Cloud%\%Ext_backup% /b /tw /a-d /o-d') Do ERASE %Cloud%\%%i

rem ������ ����� � ���� ����������� �� ������� ��������� ������� ������ ������� � �������� Max_backup
copy %TempBackupDir%\%Ext_backup% %BackupDir%
if %errorlevel%==0 erase %TempBackupDir%\%Ext_backup%

rem ������� ������ �������� ����� ��������� �����
for /f "skip=%Max_backup% tokens=*" %%i in ('dir %BackupDir%\%Ext_backup% /b /tw /a-d /o-d') Do ERASE %BackupDir%\%%i

rem ������� ��������� �����
DEL /Q %TempBackupDir%\*.*

rem robocopy %BackupDir% %Cloud% /PURGE /R:1 /LOG+:copy.log
TIMEOUT /T 1800
rem ³�������� ��������� ����
%net% -c u -d z
