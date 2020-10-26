rem rem перед запуском 
rem 1. Установка rclone 
rem rclone config 
rem далее все по пунктам, откроется браузер, авторизуемся в яндексе. 
rem по окончании просто ок. 

rem 2. создаем папки на С и Д дисках 
rem C:/back_up/daily
rem D:/back_up/daily
rem C:/log/

rem 3. правим путь в скрипте к 1с клиенту.
rem Правим tasklist если нужна локализация, работает через tasklist /FI "IMAGENAME eq %process%" /NH | findstr /i "%process%">nul 
rem иначе tasklist /FI "1cv8.exe eq %process%" /NH | findstr /i "%process%">nul

rem 4. устанавливаем 7z если нет
rem 5. устанавливаем время хранение в днях.

rem запускаем, проверяем, смотрим на ЯД созданные папки. 

@echo off
set DirName=back_up
set BackupDir=C:\%DirName%\daily\
set CopyBackupDir=D:\%DirName%\daily\
set NumFolders=6
set h=%time:~0,2%
set h=%h: =0%
set day=%date%_%h%%time:~3,2%%time:~6,2%
set FullBackupDir=%BackupDir%%day%
md %FullBackupDir%
set CopyBackupDir=%CopyBackupDir%%day%\
md %CopyBackupDir%
Set f_date=%day%
Set cmd_log=C:\log\%day%_cmd_log.txt 

CHCP 1251 >> %cmd_log%
@echo дата задана: %f_date% >> %cmd_log%

Set f_name_dt=%FullBackupDir%\backup.dt 

@echo бэкап пишем сюда: %FullBackupDir% >> %cmd_log%
Set f_name_log=%FullBackupDir%\backup_log.txt 

@echo логи пишем сюда : %f_name_log% >> %cmd_log%

taskkill /IM 1cv8.exe /f >> %cmd_log%
taskkill /IM 1cv8c.exe /f >> %cmd_log%
taskkill /IM 1cv8s.exe /f >> %cmd_log%
@echo закрыли всех пользователей из 1с. >> %cmd_log% 

set process=1cv8.exe

"C:\Program Files (x86)\1cv8\common\1cestart.exe" CONFIG /IBName "base_name" /N Андрей /P password /DumpIB %f_name_dt% /OUT %f_name_log% 

goto checker
:check
cls
echo Process %process% is still running...
:checker
tasklist /FI "IMAGENAME eq %process%" /NH | findstr /i "%process%">nul
if %errorLevel% == 0 goto :check

rem процесс 1cv8s.exe был завершен, можно запускать следующий файл

@echo 1c запустили файлы создались: %f_name_dt% %f_name_log% >> %cmd_log%


SetLocal EnableDelayedExpansion >> %cmd_log%

rem =============================
rem ======== 7-Zip path =========
rem =============================

set s7z=C:\Program Files\7-Zip\7z.exe

@echo записали путь %s7z% >> %cmd_log%
rem =============================
rem == create backup directory ==
rem ==== DD.MM.YYYY_hhmmmss =====
rem =============================
@echo путь сохранения %CopyBackupDir% >> %cmd_log% 

rem =============================
rem ====== copy directory =======
rem =============================

xcopy %FullBackupDir% %CopyBackupDir%\ /E /F /H /R /K /Y /D 2>nul >nul 

@echo сохранение копии на диск Д >> %cmd_log% 

rem =============================
rem ====== zip directory ========
rem =============================

"%s7z%" a -tzip -bb0 -bd -sdel "%CopyBackupDir%%day%.zip" "%CopyBackupDir%" 2>nul >nul >> %cmd_log% 

@echo архивируем новые файлы >> %cmd_log% 

rem =============================
rem ==== remove old folders =====
rem =============================

@echo удаляем файлы C диска Д и С если больше 4 дней >> %cmd_log% 

cd /d "C:\back_up\daily\" && @forfiles /d -4 /C "cmd /c if @isdir==TRUE rd /s /q @file" >> %cmd_log%

cd /d "D:\back_up\daily\" && @forfiles /d -4 /C "cmd /c if @isdir==TRUE rd /s /q @file" >> %cmd_log%

@echo удаляем файлы первые если больше 4 >> %cmd_log% 
@echo отправляем файлы за 24 часа в облако >> %cmd_log% 
C:\Backup_script\rclone.exe copy --max-age 24h --no-traverse --size-only --progress D:\back_up\daily yandex:backups >> %cmd_log% 
dir %CopyBackupDir% >> %cmd_log%
C:\Backup_script\rclone.exe delete --min-age 4d --rmdirs yandex:backups >> %cmd_log%
@echo Удалили с диска все что старше 4 дней >> %cmd_log%
C:\Backup_script\rclone.exe cleanup yandex: >> %cmd_log%
@echo Очистили корзину на Яндексе >> %cmd_log%
C:\Backup_script\rclone.exe lsd yandex:backups\ >> %cmd_log%
@echo БИНГО! Бэкап на диске D и в облаке! >> %cmd_log%