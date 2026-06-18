@echo off
setlocal ENABLEEXTENSIONS
echo.
echo EFI Unlocker 1.2.0 for VMware
echo =============================
echo (c) Dave Parsons 2018

echo.
set KeyName="HKLM\SOFTWARE\VMware, Inc.\VMware Workstation"
REG QUERY %KeyName% /v InstallPath >nul 2>&1
if %errorlevel% neq 0 (
    set KeyName="HKLM\SOFTWARE\Wow6432Node\VMware, Inc.\VMware Player"
)

:: delims is a TAB followed by a space
for /F "tokens=2* delims=	 " %%A in ('REG QUERY %KeyName% /v InstallPath') do set InstallPath=%%B
echo VMware is installed at: %InstallPath%

for /F "tokens=2* delims=	 " %%A in ('REG QUERY %KeyName% /v ProductVersion') do set ProductVersion=%%B
echo VMware product version: %ProductVersion%

for /F "tokens=1,2,3,4 delims=." %%a in ("%ProductVersion%") do (
   set Major=%%a
   set Minor=%%b
   set Revision=%%c
   set Build=%%d
)

echo %Major% | findstr /R /C:"[0-9][0-9][Hh][1-2]" >nul
if %errorlevel% equ 0 (
    set IsModern=1
) else (
    set IsModern=0
    if %Major% lss 14 (
        echo VMware Workstation/Player version 14 or greater required!
        exit /b
    )
)

pushd %~dp0

echo.
if exist "%InstallPath%x64\EFI32.ROM" (
    echo Patching 32-bit ROM...
    xcopy /F /Y "%InstallPath%x64\EFI32.ROM" .
    .\windows\UEFIPatch.exe EFI32.ROM patches.txt -o EFI32-MACOS.ROM
    del /f EFI32.ROM
    echo.
)

if exist "%InstallPath%x64\EFI64.ROM" (
    echo Patching 64-bit ROM...
    xcopy /F /Y "%InstallPath%x64\EFI64.ROM" .
    .\windows\UEFIPatch.exe EFI64.ROM patches.txt -o EFI64-MACOS.ROM
    del /f EFI64.ROM
)

set PatchTPM=0
if %IsModern% equ 1 set PatchTPM=1
if %IsModern% equ 0 if %Major% geq 17 set PatchTPM=1

if %PatchTPM% equ 1 (
    if exist "%InstallPath%x64\EFI20-32.ROM" (
        echo.
        echo Patching 32-bit TPM 2.0 ROM...
        xcopy /F /Y "%InstallPath%x64\EFI20-32.ROM" .
        .\windows\UEFIPatch.exe EFI20-32.ROM patches.txt -o EFI20-32-MACOS.ROM
        del /f EFI20-32.ROM
    )

    if exist "%InstallPath%x64\EFI20-64.ROM" (
        echo.
        echo Patching 64-bit TPM 2.0 ROM...
        xcopy /F /Y "%InstallPath%x64\EFI20-64.ROM" .
        .\windows\UEFIPatch.exe EFI20-64.ROM patches.txt -o EFI20-64-MACOS.ROM
        del /f EFI20-64.ROM
    )
)

popd
echo.
echo Finished
