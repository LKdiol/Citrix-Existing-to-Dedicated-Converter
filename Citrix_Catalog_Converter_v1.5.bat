@echo off 
setlocal enabledelayedexpansion
:AML
dir "%TMP%" >nul 2>&1
if %errorlevel%==1 goto tmppatch
del "%TMP%\*.sql" "%TMP%\*.log" "%TMP%\mokrokc.txt" >nul 2>&1
set seldb=vm
echo Citrix Existing to Dedicated Converter v1.5
echo 버전일자 2024-05-22
title Citrix Existing to Dedicated Converter v1.5
set location=%~dp0
cd %location%
timeout 1 >nul 2>&1
echo.

:: 인증방식 0이면 AD도메인 인증, 1이면 SQL Server 인증
set salist=0


:: bin 폴더 유무
IF EXIST bin (
goto mvcconfig
) ELSE (
 goto notbin
)

:notbin
echo.
echo bin 폴더가 존재하지 않습니다. 
echo 실행된 경로에서 bin폴더 빠지지 않았는지 다시한번 확인해주세요. 
pause 
exit

:mvcconfig
:: config 파일 유무
IF EXIST config.conf (
goto confdb
) ELSE (
 goto input
)
:: pause


:input
cls
set dbport=1433
echo Citrix Existing to Dedicated Converter 초기구성 Config 구성 
echo 구성 완료 시 Citrix_Catalog_Converter.bat 경로에 Config.conf 파일 생성
echo.
:: config 설정 ------

:: DB서버 IP or 도메인 설정
echo 1.DB서버 IP 입력
set /p userDBip=입력:
echo.
:: DB서버 포트 설정
echo 2.DB서버Port 입력
echo 입력안하고 넘어갈 시 기본 1433포트로 자동 입력
set /p dbport=입력:
echo.
echo 3. CVAD Site DB 설정
set /p userDB=입력:
goto input1
:derr
echo 범위를 벗어난 입력입니다.
echo 잘못된 값으로 처음 화면으로 다시 돌아갑니다.
pause
goto main

:input1
cls
set seldb=vm
echo ## DB접속정보 설정 메뉴
echo.
echo 1) DB 인증을 AD도메인 및 SQL Server 인증을 선택 할 수 있습니다.
echo   -- 도메인 조인이 아닌 호스트에서는 AD도메인 인증을 해도 자동으로 SQL Server 인증으로 설정
echo 2) Citrix Controller에 설정 된 Site DB명 입력
echo.
echo 1.AD도메인인증
echo 2.SQL Server 인증
echo.
echo x. 나가기  
echo.
set /p seldb=DB 인증방식 선택:
if %seldb%==vm goto derr
if %seldb%==x exit
if %seldb%==X exit
if %seldb%==1 goto join
if %seldb%==2 goto selc1

:join
set salist=0
:: 도메인 조인 여부 
:: 로컬 호스트에서 도메인 조인상태에 따라 DB조인 수동입력으로 자동 전환
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
echo CVAD DB 접근이 올바르지 않아 DB config 재 입력이 필요합니다.
echo 재 입력을 위해 아무 키나 누르십시오
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

echo ##카탈로그 목록
echo.
type "%TMP%\mokrokc.txt"

echo.
echo ## Catalog Name 입력
echo.
echo 입력 순서 : 카탈로그 목록에 나와 있는 Exsting Catalog Num(번호) 입력 후 
echo         Dedicated Catalog Num(번호) 순으로 입력합니다.
echo.
echo x. 나가기
echo.
set /p existnum=Existing Catalog Num 입력:
echo.

if %existnum%==x exit
if %existnum%==X exit
if %existnum%==ㅌ exit
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
echo 입력하신 카탈로그가 Existing 카탈로그가 아닌것으로 보입니다.
echo 재 입력을 위해 아무 키나 누르십시오
pause > nul
goto main

:DediName
set /p mcsnum=Dedicated Catalog Num 입력:
echo.
if %mcsnum%==x exit
if %mcsnum%==X exit
if %mcsnum%==ㅌ exit

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
echo 입력하신 카탈로그가 Dedicated 카탈로그가 아닌것으로 보입니다.
echo 재 입력을 위해 아무 키나 누르십시오
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
if %pwrmachine%==0 set pwhawl=활성화
if %pwrmachine%==1 set pwhawl=비활성화
set pomname=%pwrmachine%
echo.
echo 현재 Existing (%existname%) 카탈로그의 파워관리 설정이 (%pwhawl%)되어 있습니다.
echo 입력 없이 넘어갈 시 (%existname%) 카탈로그의 파워관리 설정대로 파워관리 (%pwhawl%) 값이 설정되게 됩니다.
echo. 
echo Y.머신 파워관리 활성화
echo N.머신 파워관리 비활성화
echo.
set /p pomname=Existing 카탈로그 파워관리 Y/N 입력:
echo.
if %pwrmachine%==%pomname% goto pwermanag3
if %pomname%==Y set powma=0 && goto StartConvert
if %pomname%==y set powma=0 && goto StartConvert
if %pomname%==N set powma=1 && goto StartConvert
if %pomname%==n set powma=1 && goto StartConvert

goto pwarmsg

:pwarmsg
echo.
echo 입력하신 값이 Y/N 을 입력하였는지 다시한번 확인해주세요
echo 재 입력을 위해 아무 키나 누르십시오
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
echo Citrix CVAD Machine Catalog 변환이 완료되었습니다.
echo ##변환 전
echo.
type "%TMP%\mokrokc.txt"
echo.
echo ##변환 후
echo.
if %salist%==0 sqlcmd -Y 25 -E -S %userDBip%,%dbport% -s " " -i "%TMP%\result.sql"
if %salist%==1 sqlcmd -Y 25 -S %userDBip%,%dbport% -U %sauser% -P !sapass! -s " " -i "%TMP%\result.sql"
echo.
echo 아무 키나 누르거나 'X' 버튼을 클릭하여 닫으시면 됩니다.
pause >nul 2>&1
del "%TMP%\*.sql" "%TMP%\mokrokc.txt" >nul 2>&1
exit


:selc1
set salist=1
set sauser=sa
cls
echo # SQL Server 인증방식 설정
echo.
echo 1.DB user 입력 
echo 입력안하고 넘어갈 시 sa계정으로 자동 입력
set /p sauser=입력:
echo.
echo 2.DB %sauser% 계정 패스워드 입력
call :mssqlPass usersapass "입력: "
echo.

:mssqlPass
SetLocal DisableDelayedExpansion
echo 입력:
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
::암호화
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
echo 현재 버전 Citrix Catalog Converter v1.5
echo Release 2024-05-22
echo Copyright 2024 ⓒ Leedk. All rights reserved.
echo.
pause
goto main