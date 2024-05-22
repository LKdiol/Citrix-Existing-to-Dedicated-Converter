@echo off 
setlocal enabledelayedexpansion
:AML
dir "%TMP%" >nul 2>&1
if %errorlevel%==1 goto tmppatch
del "%TMP%\*.sql" "%TMP%\*.log" "%TMP%\mokrokc.txt" >nul 2>&1
set seldb=vm
echo Citrix Existing to Dedicated Converter v1.5
echo �������� 2024-05-22
title Citrix Existing to Dedicated Converter v1.5
set location=%~dp0
cd %location%
timeout 1 >nul 2>&1
echo.

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

:injeung
if %salist%==0 goto intype1
goto intype2

:intype1
sqlcmd -S %userDBip%,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [Uid] FROM [%userDB%].[chb_Config].[Catalogs]" >nul 2>&1
if %errorlevel%==0 goto main
if %errorlevel%==1 goto intype3

:intype2
sqlcmd -S %userDBip%,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [Uid] FROM [%userDB%].[chb_Config].[Catalogs]" >nul 2>&1
if %errorlevel%==0 goto main
if %errorlevel%==1 goto intype3

:intype3
echo.
echo CVAD DB ������ �ùٸ��� �ʾ� DB config �� �Է��� �ʿ��մϴ�.
echo �� �Է��� ���� �ƹ� Ű�� �����ʽÿ�
pause > nul
goto input

:main
set exialloty=n
set exiproty=n
set dedalloty=n
set dedproty=n
set existname=n
set mcsname=n
del "%TMP%\sapass.txt" >nul 2>&1
::substring (A.DisplayName,0,20)
echo SET NOCOUNT ON; > "%TMP%\view.sql"
echo SET QUOTED_IDENTIFIER ON >> "%TMP%\view.sql"
echo. >> "%TMP%\view.sql"
echo GO >> "%TMP%\view.sql"
echo Select SUBSTRING(CAST(ROW_NUMBER() OVER (ORDER BY A.Uid DESC) AS VARCHAR(5)), 0, 5) AS "Num", substring (A.DisplayName,0,20) AS"Catalogs Name",CASE WHEN A.ProvisioningType like '2' THEN 'MCS(Dedicated) Catalogs' WHEN A.ProvisioningType like '0' THEN 'Existing Catalogs' END AS "Catalogs Type" , >> "%TMP%\view.sql"
echo CASE WHEN A.PhysicalMachines like '0' THEN 'Power Managed' WHEN A.PhysicalMachines like '1' THEN 'Not Power Managed' END AS "VM Power Type", >> "%TMP%\view.sql"
echo B.MasterImageVM, >> "%TMP%\view.sql"
echo substring (C.DisplayName,0,10) AS "Hypervisor Name" >> "%TMP%\view.sql"
echo From [%userDB%].[chb_Config].[Catalogs] A >> "%TMP%\view.sql"
echo LEFT OUTER JOIN [%userDB%].[DesktopUpdateManagerSchema].[ProvisioningScheme] B ON A.ProvisioningSchemeId = B.ProvisioningSchemeUid >> "%TMP%\view.sql"
echo LEFT OUTER JOIN [%userDB%].[chb_Config].[HypervisorConnections] C ON A.HypervisorConnectionUid = C.Uid >> "%TMP%\view.sql"
echo where A.AllocationType=0 >> "%TMP%\view.sql"
echo.
cls
if %salist%==0 sqlcmd -Y 25 -E -S %userDBip%,%dbport% -s " " -i "%TMP%\view.sql" > "%TMP%\mokrokc.txt"
if %salist%==1 sqlcmd -Y 25 -S %userDBip%,%dbport% -U %sauser% -P !sapass! -s " " -i "%TMP%\view.sql" > "%TMP%\mokrokc.txt"

echo ##īŻ�α� ���
echo.
type "%TMP%\mokrokc.txt"

echo.
echo ## Catalog Name �Է�
echo.
echo �Է� ���� : īŻ�α� ��Ͽ� ���� �ִ� Exsting Catalog Num(��ȣ) �Է� �� 
echo         Dedicated Catalog Num(��ȣ) ������ �Է��մϴ�.
echo.
echo x. ������
echo.
set /p existnum=Existing Catalog Num �Է�:
echo.

if %existnum%==x exit
if %existnum%==X exit
if %existnum%==�� exit
if %existnum%==v goto ver

if %salist%==0 goto extype1
goto extype2

:extype1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; WITH NUM AS (SELECT DisplayName,ROW_NUMBER() OVER (ORDER BY Uid DESC) AS RowNum FROM [%userDB%].[chb_Config].[Catalogs] WHERE AllocationType=0) SELECT DisplayName FROM NUM WHERE RowNum = %existnum%"') do set existname=%%i

for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exialloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set exiproty=%%i
goto extype3

:extype2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; WITH NUM AS (SELECT DisplayName,ROW_NUMBER() OVER (ORDER BY Uid DESC) AS RowNum FROM [%userDB%].[chb_Config].[Catalogs] WHERE AllocationType=0) SELECT DisplayName FROM NUM WHERE RowNum = %existnum%"') do set existname=%%i

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
set /p mcsnum=Dedicated Catalog Num �Է�:
echo.
if %mcsnum%==x exit
if %mcsnum%==X exit
if %mcsnum%==�� exit

if %salist%==0 goto detype1
goto detype2

:detype1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; WITH NUM AS (SELECT DisplayName,ROW_NUMBER() OVER (ORDER BY Uid DESC) AS RowNum FROM [%userDB%].[chb_Config].[Catalogs] WHERE AllocationType=0) SELECT DisplayName FROM NUM WHERE RowNum = %mcsnum%"') do set mcsname=%%i

for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedalloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedproty=%%i

goto detype3

:detype2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; WITH NUM AS (SELECT DisplayName,ROW_NUMBER() OVER (ORDER BY Uid DESC) AS RowNum FROM [%userDB%].[chb_Config].[Catalogs] WHERE AllocationType=0) SELECT DisplayName FROM NUM WHERE RowNum = %mcsnum%"') do set mcsname=%%i

for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [AllocationType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedalloty=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [ProvisioningType] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set dedproty=%%i

:detype3
if not %dedalloty%==0 goto dwarmsg
if not %dedproty%==2 goto dwarmsg

goto pwermanag

:dwarmsg
echo.
echo �Է��Ͻ� īŻ�αװ� Dedicated īŻ�αװ� �ƴѰ����� ���Դϴ�.
echo �� �Է��� ���� �ƹ� Ű�� �����ʽÿ�
pause > nul
goto main


:pwermanag
if %salist%==0 goto pwrtype1
goto pwrtype2

:pwrtype1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [PhysicalMachines] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set pwrmachine=%%i
goto pwermanag2

:pwrtype2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [PhysicalMachines] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%existname%'"') do set pwrmachine=%%i
echo.
:pwermanag2
if %pwrmachine%==0 set pwhawl=Ȱ��ȭ
if %pwrmachine%==1 set pwhawl=��Ȱ��ȭ
set pomname=%pwrmachine%
echo.
echo ���� Existing (%existname%) īŻ�α��� �Ŀ����� ������ (%pwhawl%)�Ǿ� �ֽ��ϴ�.
echo �Է� ���� �Ѿ �� (%existname%) īŻ�α��� �Ŀ����� ������� �Ŀ����� (%pwhawl%) ���� �����ǰ� �˴ϴ�.
echo. 
echo Y.�ӽ� �Ŀ����� Ȱ��ȭ
echo N.�ӽ� �Ŀ����� ��Ȱ��ȭ
echo.
set /p pomname=Existing īŻ�α� �Ŀ����� Y/N �Է�:
echo.
if %pwrmachine%==%pomname% goto pwermanag3
if %pomname%==Y set powma=0 && goto StartConvert
if %pomname%==y set powma=0 && goto StartConvert
if %pomname%==N set powma=1 && goto StartConvert
if %pomname%==n set powma=1 && goto StartConvert

goto pwarmsg

:pwarmsg
echo.
echo �Է��Ͻ� ���� Y/N �� �Է��Ͽ����� �ٽ��ѹ� Ȯ�����ּ���
echo �� �Է��� ���� �ƹ� Ű�� �����ʽÿ�
pause > nul
goto pwermanag

:pwermanag3
set powma=%pwrmachine%

:StartConvert
if %salist%==0 goto type1
goto type2

:type1
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [ProvisioningSchemeId] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set provschid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; SELECT [HypervisorConnectionUid] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set hypuid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -E -W -h -1 -Q "set nocount on; select B.IdentityPoolUid FROM [%userDB%].[chb_Config].[Catalogs] A LEFT OUTER JOIN [%userDB%].[DesktopUpdateManagerSchema].[ProvisioningScheme] B ON A.ProvisioningSchemeId = B.ProvisioningSchemeUid where A.DisplayName='%mcsname%'"') do set idenpoolid=%%i

goto start

:type2
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [ProvisioningSchemeId] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set provschid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; SELECT [HypervisorConnectionUid] FROM [%userDB%].[chb_Config].[Catalogs] where DisplayName='%mcsname%'"') do set hypuid=%%i
for /f "tokens=1" %%i in ('sqlcmd -S %userDBip%^,%dbport% -U %sauser% -P !sapass! -W -h -1 -Q "set nocount on; select B.IdentityPoolUid FROM [%userDB%].[chb_Config].[Catalogs] A LEFT OUTER JOIN [%userDB%].[DesktopUpdateManagerSchema].[ProvisioningScheme] B ON A.ProvisioningSchemeId = B.ProvisioningSchemeUid where A.DisplayName='%mcsname%'"') do set idenpoolid=%%i

:start
echo SET QUOTED_IDENTIFIER ON > "%TMP%\converter.sql"
echo. >> "%TMP%\converter.sql"
echo GO >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set PhysicalMachines='0' where DisplayName='%existname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningType='2' where DisplayName='%existname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningSchemeId='%provschid%' where DisplayName='%existname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set HypervisorConnectionUid='%hypuid%' where DisplayName='%existname%' >> "%TMP%\converter.sql"

echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningSchemeId=NULL where DisplayName='%mcsname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set HypervisorConnectionUid=NULL where DisplayName='%mcsname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set ProvisioningType='0' where DisplayName='%mcsname%' >> "%TMP%\converter.sql"
echo update [%userDB%].[chb_Config].[Catalogs] set PhysicalMachines='%powma%' where DisplayName='%mcsname%' >> "%TMP%\converter.sql"

echo update [%userDB%].[DesktopUpdateManagerSchema].[ProvisioningScheme] set ProvisioningSchemeName='%existname%' where ProvisioningSchemeUid='%provschid%' >> "%TMP%\converter.sql"
echo update [%userDB%].[ADIdentitySchema].[IdentityPool] set IdentityPoolName='%existname%' where IdentityPoolUid='%idenpoolid%' >> "%TMP%\converter.sql"

if %salist%==0 sqlcmd -E -S %userDBip%,%dbport% -i "%TMP%\converter.sql"
if %salist%==1 sqlcmd -S %userDBip%,%dbport% -U %sauser% -P !sapass! -i "%TMP%\converter.sql"

echo.
echo SET NOCOUNT ON; > "%TMP%\result.sql"
echo SET QUOTED_IDENTIFIER ON >> "%TMP%\result.sql"
echo. >> "%TMP%\result.sql"
echo GO >> "%TMP%\result.sql"
echo Select SUBSTRING(CAST(ROW_NUMBER() OVER (ORDER BY A.Uid DESC) AS VARCHAR(5)), 0, 5) AS "Num", substring (A.DisplayName,0,20) AS"Catalogs Name",CASE WHEN A.ProvisioningType like '2' THEN 'MCS(Dedicated) Catalogs' WHEN A.ProvisioningType like '0' THEN 'Existing Catalogs' END AS "Catalogs Type" , >> "%TMP%\result.sql"
echo CASE WHEN A.PhysicalMachines like '0' THEN 'Power Managed' WHEN A.PhysicalMachines like '1' THEN 'Not Power Managed' END AS "VM Power Type", >> "%TMP%\result.sql"
echo B.MasterImageVM, >> "%TMP%\result.sql"
echo substring (C.DisplayName,0,10) AS "Hypervisor Name" >> "%TMP%\result.sql"
echo From [%userDB%].[chb_Config].[Catalogs] A >> "%TMP%\result.sql"
echo LEFT OUTER JOIN [%userDB%].[DesktopUpdateManagerSchema].[ProvisioningScheme] B ON A.ProvisioningSchemeId = B.ProvisioningSchemeUid >> "%TMP%\result.sql"
echo LEFT OUTER JOIN [%userDB%].[chb_Config].[HypervisorConnections] C ON A.HypervisorConnectionUid = C.Uid >> "%TMP%\result.sql"
echo where A.AllocationType=0 >> "%TMP%\result.sql"
echo.


cls
echo Citrix CVAD Machine Catalog ��ȯ�� �Ϸ�Ǿ����ϴ�.
echo ##��ȯ ��
echo.
type "%TMP%\mokrokc.txt"
echo.
echo ##��ȯ ��
echo.
if %salist%==0 sqlcmd -Y 25 -E -S %userDBip%,%dbport% -s " " -i "%TMP%\result.sql"
if %salist%==1 sqlcmd -Y 25 -S %userDBip%,%dbport% -U %sauser% -P !sapass! -s " " -i "%TMP%\result.sql"
echo.
echo �ƹ� Ű�� �����ų� 'X' ��ư�� Ŭ���Ͽ� �����ø� �˴ϴ�.
pause >nul 2>&1
del "%TMP%\*.sql" "%TMP%\mokrokc.txt" >nul 2>&1
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


:tmppatch
SET TEMP=%USERPROFILE%\AppData\Local\Temp\2
SET TMP=%USERPROFILE%\AppData\Local\Temp\2
mkdir "%TEMP%"
mkdir "%TMP%"
goto AML

:ver
cls
echo ���� ���� Citrix Catalog Converter v1.5
echo Release 2024-05-22
echo Copyright 2024 �� Leedk. All rights reserved.
echo.
pause
goto main