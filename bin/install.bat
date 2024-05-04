@echo off 
setlocal enabledelayedexpansion
:AML
dir "%TMP%" >nul 2>&1
if %errorlevel%==1 goto tmppatch
del "%TMP%\*.sql" "%TMP%\*.log" >nul 2>&1
set seldb=vm
echo Citrix Existing to Dedicated Converter v1.0
echo 버전일자 2024-05-02
title Citrix Existing to Dedicated Converter v1.0
set location=%~dp0
cd %location%
timeout 1 >nul 2>&1
echo.
del "bin\temp2.bat"

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
del "bin\temp2.bat" >nul 2>&1
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

:main
set exialloty=n
set exiproty=n
set dedalloty=n
set dedproty=n
del "%TMP%\sapass.txt"
cls
echo ## Catalog Name 입력
echo.
echo 입력 순서 : Exsting Catalog Name 입력 후 Dedicated Catalog Name 순으로 입력합니다.
echo.
set /p existname=Existing Catalog Name 입력:
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
echo 입력하신 카탈로그가 Existing 카탈로그가 아닌것으로 보입니다.
echo 재 입력을 위해 아무 키나 누르십시오
pause > nul
goto main

:DediName
set /p mcsname=Dedicated Catalog Name 입력:
echo.

if %salist%==0 goto detype1
goto detype2

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
echo 입력하신 카탈로그가 Dedicated 카탈로그가 아닌것으로 보입니다.
echo 재 입력을 위해 아무 키나 누르십시오
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
echo Citrix CVAD Machine Catalog 변환이 완료되었습니다.
echo 아무 키나 누르거나 'X' 버튼을 클릭하여 닫으시면 됩니다.
pause >nul 2>&1
del "%TMP%\*.sql" >nul 2>&1
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
