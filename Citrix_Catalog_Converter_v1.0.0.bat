@echo off 
setlocal enabledelayedexpansion
del "%TMP%\*.sql" "%TMP%\*.log" >nul 2>&1
set seldb=vm
echo Citrix Existing to Dedicated Converter v1.0
echo �������� 2024-05-02
title Citrix Existing to Dedicated Converter v1.0
set location=%~dp0
cd %location%
:: ������� 0�̸� AD������ ����, 1�̸� SQL Server ����
set salist=0


:: bin ���� ����
IF EXIST bin (
goto mvcconfig
) ELSE (
 goto notbin
)

:notbin
echo.
echo bin ������ �������� �ʽ��ϴ�. 
echo ����� ��ο��� bin���� ������ �ʾҴ��� �ٽ��ѹ� Ȯ�����ּ���. 
pause 
exit

:mvcconfig
:: config ���� ����
IF EXIST config.conf (
goto confdb
) ELSE (
 goto input
)
:: pause


:input
cls
set dbport=1433
echo Citrix Existing to Dedicated Converter �ʱⱸ�� Config ���� 
echo ���� �Ϸ� �� Citrix_Catalog_Converter.bat ��ο� Config.conf ���� ����
echo.
:: config ���� ------

:: DB���� IP or ������ ����
echo 1.DB���� IP �Է�
set /p userDBip=�Է�:
echo.
:: DB���� ��Ʈ ����
echo 2.DB����Port �Է�
echo �Է¾��ϰ� �Ѿ �� �⺻ 1433��Ʈ�� �ڵ� �Է�
set /p dbport=�Է�:
echo.
echo 3. CVAD Site DB ����
set /p userDB=�Է�:
goto input1
:derr
echo ������ ��� �Է��Դϴ�.
echo �߸��� ������ ó�� ȭ������ �ٽ� ���ư��ϴ�.
pause
goto main

:input1
cls
set seldb=vm
echo ## DB�������� ���� �޴�
echo.
echo 1) DB ������ AD������ �� SQL Server ������ ���� �� �� �ֽ��ϴ�.
echo   -- ������ ������ �ƴ� ȣ��Ʈ������ AD������ ������ �ص� �ڵ����� SQL Server �������� ����
echo 2) Citrix Controller�� ���� �� Site DB�� �Է�
echo.
echo 1.AD����������
echo 2.SQL Server ����
echo.
echo x. ������  
echo.
set /p seldb=DB ������� ����:
if %seldb%==vm goto derr
if %seldb%==x exit
if %seldb%==X exit
if %seldb%==1 goto join
if %seldb%==2 goto selc1

:join
set salist=0
:: ������ ���� ���� 
:: ���� ȣ��Ʈ���� ������ ���λ��¿� ���� DB���� �����Է����� �ڵ� ��ȯ
if %computername%==%userdomain% goto selc1
goto input3

:input3
echo salist= %salist% > config.conf
echo userDBip= %userDBip% >> config.conf
echo dbport= %dbport% >> config.conf
echo userDB= %userDB% >> config.conf
echo sauser= %sauser% >> config.conf
echo sapass= %passenc% >> config.conf
echo.

:confdb
setlocal EnableDelayedExpansion
set sapass=err
for /f "tokens=2" %%i in ('findstr "salist" config.conf') do set salist=%%i
for /f "tokens=2" %%i in ('findstr "userDBip" config.conf') do set userDBip=%%i
for /f "tokens=2" %%i in ('findstr "dbport" config.conf') do set dbport=%%i
for /f "tokens=2" %%i in ('findstr "userDB" config.conf') do set userDB=%%i
for /f "tokens=2" %%i in ('findstr "sauser" config.conf') do set sauser=%%i
for /f "tokens=2" %%i in ('findstr "sapass" config.conf') do set passenc=%%i
echo.

echo %passenc% |bin\openssl.exe enc -d -aes256 -a -k %COMPUTERNAME% > "%TMP%\sapass.txt"
set /p sapass=<"%TMP%\sapass.txt"
set sa2pass=!sapass!
if !sapass!==err goto sapassline


:sapassline
if NOT !sapass!==err goto main
echo %passenc%= |bin\openssl.exe enc -d -aes256 -a -k %COMPUTERNAME% > "%TMP%\sapass.txt"
set /p sapass=<"%TMP%\sapass.txt"
set sa2pass=!sapass!

:main
set exialloty=n
set exiproty=n
set dedalloty=n
set dedproty=n
del "%TMP%\sapass.txt"
cls
echo ## Catalog Name �Է�
echo.
echo �Է� ���� : Exsting Catalog Name �Է� �� Dedicated Catalog Name ������ �Է��մϴ�.
echo.
set /p existname=Existing Catalog Name �Է�:
echo.

if %salist%==0 goto extype1
goto extype2

:extype1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exialloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exiproty=%%i
goto extype3

:extype2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exialloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exiproty=%%i

:extype3
if not %exialloty%==0 goto ewarmsg
if not %exiproty%==0 goto ewarmsg

goto DediName

:ewarmsg
echo.
echo �Է��Ͻ� īŻ�αװ� Existing īŻ�αװ� �ƴѰ����� ���Դϴ�.
echo �� �Է��� ���� �ƹ� Ű�� �����ʽÿ�
pause > nul
goto main

:DediName
set /p mcsname=Dedicated Catalog Name �Է�:
echo.

:detype1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedalloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedproty=%%i
goto detype3

:detype2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedalloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedproty=%%i

:detype3
if not %dedalloty%==0 goto dwarmsg
if not %dedproty%==2 goto dwarmsg

goto StartConvert

:dwarmsg
echo.
echo �Է��Ͻ� īŻ�αװ� Dedicated īŻ�αװ� �ƴѰ����� ���Դϴ�.
echo �� �Է��� ���� �ƹ� Ű�� �����ʽÿ�
pause > nul
goto main

:StartConvert
if %salist%==0 goto type1
goto type2

:type1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningSchemeId] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set provschid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [HypervisorConnectionUid] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set hypuid=%%i

goto start

:type2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [ProvisioningSchemeId] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set provschid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [HypervisorConnectionUid] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set hypuid=%%i

:start
echo SET QUOTED_IDENTIFIER ON > "%TMP%\converter.sql"
echo. >> "%TMP%\converter.sql"
echo GO >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningType='2' where DisplayName='%existname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningSchemeId='%provschid%' where DisplayName='%existname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set HypervisorConnectionUid='%hypuid%' where DisplayName='%existname%' >> "%TMP%\converter.sql"

echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningSchemeId=NULL where DisplayName='%mcsname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set HypervisorConnectionUid=NULL where DisplayName='%mcsname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningType='0' where DisplayName='%mcsname%' >> "%TMP%\converter.sql"


if %salist%==0 sqlcmd -E -S %userDBip%,%dbport% -i "%TMP%\converter.sql"
if %salist%==1 sqlcmd -S %userDBip%,%dbport% -U %sauser% -P !sapass! -i "%TMP%\converter.sql"

echo.
echo Citrix CVAD Machine Catalog ��ȯ�� �Ϸ�Ǿ����ϴ�.
echo �ƹ� Ű�� �����ų� 'X' ��ư�� Ŭ���Ͽ� �����ø� �˴ϴ�.
pause >nul 2>&1
del "%TMP%\*.sql" >nul 2>&1
exit


:selc1
set salist=1
set sauser=sa
cls
echo # SQL Server ������� ����
echo.
echo 1.DB user �Է� 
echo �Է¾��ϰ� �Ѿ �� sa�������� �ڵ� �Է�
set /p sauser=�Է�:
echo.
echo 2.DB %sauser% ���� �н����� �Է�
call :mssqlPass usersapass "�Է�: "
echo.

:mssqlPass
SetLocal DisableDelayedExpansion
echo �Է�:
Set "Line="
For /F %%# In ('"Prompt;$H&For %%# in (1) Do Rem"') Do Set "BS=%%#"

:PassLoop
Set "Key="
For /F "delims=" %%# In (
'Xcopy /L /W "%~f0" "%~f0" 2^>Nul'
) Do If Not Defined Key Set "Key=%%#"
Set "Key=%Key:~-1%"
SetLocal EnableDelayedExpansion
If Not Defined Key Goto :PassEnd
If %BS%==^%Key% (Set /P "=%BS% %BS%" <Nul
Set "Key="
If Defined Line Set "Line=!Line:~0,-1!"
) Else Set /P "=*" <Nul
If Not Defined Line (EndLocal &Set "Line=%Key%"
) Else For /F delims^=^ eol^= %%# In (
"!Line!") Do EndLocal &Set "Line=%%#%Key%"
goto :PassLoop


:PassEnd
::��ȣȭ
echo(
for /f "tokens=1" %%i in ('echo !Line! ^|bin\openssl.exe enc -e -aes256 -a -k %COMPUTERNAME%') do set passenc=%%i
goto dbpassenc
:dbpassenc
goto input3