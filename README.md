# Citrix-Existing-to-Dedicated-Converter
Citrix Existing 및 Dedicated 카탈로그 변환기

## 실행화면
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/f216f623-94ed-4321-882a-3b48ffec15be)

# 개요

* 해당 툴의 목적은 기존 사용중인 Existing 카탈로그를 Dedicated로 변환하여 VM생성까지 그대로 사용이 가능하게 만들어진 툴입니다.
* 예시) 신규로 구성된 DDC에서 이전에 구성된 Dedicated 정보를 그대로 카피하여 Existing으로 생성 후 Dedicated로 변환이 가능하도록 만들었습니다.
* 해당 툴은 MSSQL 쿼리를 적용하는 방식인 SQLCMD 커맨드가 적용 되어 있습니다.
  <p>관련 코드는 <a href="https://github.com/LKdiol/Citrix-CVAD-VDI-UUID-Changer">Citrix CVAD VDI UUID Changer</a> 의 코드를 참고하여 작성되었습니다.</p>
   
(모든 7버전에서 될 것으로 예상되나 7.6 이상에서 사용하는 것을 권장드립니다.)
(그 이하 버전인 6버전 및 5버전은 테이블 방식이 다름으로 권장하지 않습니다.)
## 주의사항
## !! 진행하기전에 CVAD DB를 백업 후 진행하는 것을 권장드립니다.
----------

# 0. 초기 구성
## 1) Citrix_Catalog_Converter_vX.X.bat 실행
* 압축 풀기 후 bin디렉토리내에 내용과 같이 압축 풀기 진행 
* bat경로내에 bin디렉토리가 존재하지 않을 시 작동 불가, bin내 파일이 없을 시 작동불가
* 과정: Citrix_Catalog_Converter_vX.X.bat 실행 --> CVAD Site DB정보 입력 --> SQL 서버 인증 방식 선택(예시는 (SQL Server 인증)) --> DB서버 접속 정보 입력(단 미러 서버로 구성 시 주서버만 입력)
  <p> --> Site DB명 DB_User,Password 입력 --> ODBC,SQLCMD 설치 필요 설치는 <a href="https://github.com/LKdiol/Citrix-CVAD-VDI-UUID-Changer">Citrix CVAD VDI UUID Changer</a> 에서 bin 파일에 해당 프로그램 설치 후 진행 </p>
    DB패스워드(sapass)부분은 보안상 암호화로 저장

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/132ed746-5130-44a6-b1a1-8ede49c59ee0)

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/6810a356-5fe7-4849-998d-00ae583f44a1)



