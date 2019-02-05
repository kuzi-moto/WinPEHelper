wpeinit
wpeutil UpdateBootInfo

@echo off
@CLS
setlocal enabledelayedexpansion
call powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

for /F "skip=1 tokens=3" %%A in ('reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType') do set FIRMWARE=%%A
if %FIRMWARE%==0x1 set FW=BIOS
if %FIRMWARE%==0x2 set FW=UEFI

:TEST
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist %%i:\Images set DRIVE=%%i:
set "DIR=%DRIVE%\Images"
if [%DRIVE%] == [] goto FAIL
goto DISKTST

:FAIL
cls
echo Could not find an Images folder located on an external drive.
echo OPTIONS:
echo 1 - Rescan for drives (may take a few moments to recognize)
echo 2 - Create a new folder.
echo.
set /P I=Enter 1 or 2 then press ENTER: 
if %I%==1 goto TEST
if %I%==2 goto CREATE
goto FAIL

:CREATE
cls
call diskpart /s ListVolumes.txt
echo.
set /P DRIVE=Enter the drive letter where you would like to create the folder: 
mkdir %DRIVE%\Images
set "DIR=%DRIVE%\Images"
set "NODEPLOY=true"
goto DISKTST

:DISKTST
cls
call diskpart /s ListDisk0.txt
echo.
echo Please examine the information above. Ensure that the drive model and
echo volumes match the internal disk of the PC. This is the disk to be used when
echo deploying an image, and will be completely erased.
echo.
echo If the information shows an external USB drive, select option 6 at the next
echo screen and check that the computer has a functioning drive installed.
echo.
echo By continuing you agree that you have confirmed the correct drive is being
echo used otherwise ~~~ you will format your external USB drive! ~~~
pause

:MENU
cls
echo.
echo         -----------------------------------------------
echo                   Please enter your selection
echo         -----------------------------------------------
echo.
echo            **** The PC is booted in %FW% mode. ****
echo.
echo OPTIONS:
echo 1 - Deploy default image (%DIR%\image.wim)
echo 2 - Deploy custom image (%DIR%\...)
echo 3 - Create image
echo 4 - Backup system
echo 5 - Reboot
echo 6 - Shutdown
echo 7 - Exit menu
echo.

set /P I=Type 1, 2, 3, 4 or 5 then press ENTER: 
if %I%==1 goto DEPLOY
if %I%==2 goto CDEPLOY
if %I%==3 goto CREATE
if %I%==4 goto BACKUP
if %I%==5 exit
if %I%==6 wpeutil Shutdown
if %I%==7 goto :EOF
goto MENU

:DEPLOY
cls
if defined NODEPLOY goto NDEPLOY
echo.
echo         -----------------------------------------------
echo                  Starting the imaging process
echo         -----------------------------------------------
echo.
echo.
echo         -----------------------------------------------
echo                   (1/2) Creating Partitions
echo         -----------------------------------------------
echo.
call diskpart /s CreatePartitions-%FW%.txt
echo.
echo         -----------------------------------------------
echo                 (2/2) Applying Image to Disk
echo         -----------------------------------------------
echo.
call ApplyImage.bat %DIR%\image.wim
echo.
echo.
echo.
echo.
echo         -----------------------------------------------
echo                    Imaging process completed
echo             You may now disconnect drives and reboot
echo         -----------------------------------------------
echo.
pause
goto MENU

:CDEPLOY
CLS
if defined NODEPLOY goto NDEPLOY
echo.
echo         -----------------------------------------------
echo                  Starting the imaging process
echo         -----------------------------------------------
echo.
echo Existing images:
echo.

set Index=1
for %%A in (%DIR%\*.wim) do (
  set "Subfolders[!Index!]=%%A"
  set /a Index+=1
)
set /a UBound=Index-1

echo Available images:
echo.
for /l %%i in (1,1,%UBound%) do echo   %%i - !Subfolders[%%i]!
echo.

:SELECTION
set /p choice=Enter the number of the image to deploy: 
if "%choice%"=="" goto SELECTION
if %choice% LSS 1 goto SELECTION
if %choice% GTR %UBound% goto SELECTION
set IMG=!Subfolders[%Choice%]!

echo.
echo         -----------------------------------------------
echo                       Creating Partitions
echo         -----------------------------------------------
echo.
call diskpart /s CreatePartitions-%FW%.txt
echo.
echo         -----------------------------------------------
echo                     Applying Image to Disk
echo         -----------------------------------------------
echo.
call ApplyImage.bat %IMG%
echo.
echo.
echo.
echo         -----------------------------------------------
echo                    Imaging process completed
echo             You may now disconnect drives and reboot
echo         -----------------------------------------------
echo.
pause
goto MENU

:NDEPLOY
echo Since you have just created an Images folder, you have no images to deploy.
echo Please select another option.
echo.
pause
goto MENU

:CREATE
CLS
echo If you have not already run sysprep before starting this process,
echo please exit and run "sysprep /generalize /oobe /shutdown" first.
echo.
echo         -----------------------------------------------
echo               Starting the image capture process
echo         -----------------------------------------------
echo.
echo These are the existing images found on external drive:
for %%i in (%DIR%\*.wim) do @echo %%~ni
echo.
echo Enter the filename of the image, existing images will be overwritten.
set /P F=filename: 
echo.
echo Enter the image name:
set /P N=Name: 
echo.
echo         -----------------------------------------------
echo                       Capturing image
echo                Saving to %DIR%\%F%.wim
echo         -----------------------------------------------
echo.
dism /Capture-Image /CaptureDir:C:\ /ImageFile:"%DIR%\%F%.wim" /Name:"%N%"
echo.
echo.
echo.
echo         -----------------------------------------------
echo                    Capture process completed
echo             You may now disconnect drives and reboot
echo         -----------------------------------------------
echo.
set NODEPLOY=
pause
goto MENU

:BACKUP
cls
if not exist %DRIVE%\Backups\ mkdir %DRIVE%\Backups
echo This option creates a 7zip backup of this system's C: drive. Please note
echo this is not to be used as a complete system image, just to ensure a
echo complete backup of User data in case files were saved in unexpected
echo locations, such as on the root of the C: drive.
echo.
echo This will create a 7z archive of the entire drive, skipping the following
echo file extensions: dll, msp, sys, iso, exe, cab, fsd, img, msi, jar, bin,
echo dmp, wim, esd, dat, edb, vdm, vdb, tmp
echo as well as the Windows, and Program Files folders.
echo.
set /P F=Please enter a name for the file: 
echo.
echo Starting backup...
set "DEST=%DRIVE%\Backups\%F%.7z"
%SystemRoot%\7z\7za.exe a -t7z %DEST% C:\* -xr^^!*.dll -xr^^!*.msp -xr^^!*.sys -xr^^!*.iso -xr^^!*.cab -xr^^!*.fsd -xr^^!*.img -xr^^!*.msi -xr^^!*.jar -xr^^!*.bin -xr^^!*.dmp -xr^^!*.wim -xr^^!*.esd -xr^^!*.dat -xr^^!*.exe -xr^^!*.edb -xr^^!*.vdm -xr^^!*.vdb -xr^^!*.tmp -x^^!Windows\* -x^^!"Program Files"\* -x^^!"Program Files (x86)" -x^^!"$WINDOWS.~BT" -x^^!PerfLogs
echo.
echo Completed! Saved to %DEST%
echo.
pause
goto MENU