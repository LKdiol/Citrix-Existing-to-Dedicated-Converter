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
<del> ## 주의사항 </del>
##<del> !! 진행하기전에 CVAD DB를 백업 후 진행하는 것을 권장드립니다. </del>
<p> 딱히 문제도 없고 기존 카탈로그로 원복도 가능해서 굳이 백업은 안해도 될 것으로 보임 </p>
----------

# 0. 초기 구성
## 1) Citrix_Catalog_Converter_vX.X.bat 실행
* 압축 풀기 후 bin디렉토리내에 내용과 같이 압축 풀기 진행 
* bat경로내에 bin디렉토리가 존재하지 않을 시 작동 불가, bin내 파일이 없을 시 작동불가
* 과정: Citrix_Catalog_Converter_vX.X.bat 실행 --> CVAD Site DB정보 입력 --> SQL 서버 인증 방식 선택(예시는 (SQL Server 인증)) --> DB서버 접속 정보 입력(단 미러 서버로 구성 시 주서버만 입력)
  <p> --> Site DB명 DB_User,Password 입력 --> ODBC,SQLCMD 설치 필요 설치는 <a href="https://github.com/LKdiol/Citrix-CVAD-VDI-UUID-Changer">Citrix CVAD VDI UUID Changer</a> 에서 bin 파일에 해당 프로그램 설치 후 진행 </p>
    DB패스워드(sapass)부분은 보안상 암호화로 저장

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/132ed746-5130-44a6-b1a1-8ede49c59ee0)

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/8ff052dd-84d9-4531-a9d2-d16176ca7ca9)

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/34ae9acd-21c6-4515-8894-c29af275127e)

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/8f8d56bd-0d4c-4ecb-be24-aec7148558ee)

![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/9ee4e10f-7d2f-4203-bc51-a375878e22a1)


# Converting 과정
## Catalog Name 입력
과정: 변환 대상 Existing Catalog Name 입력 --> Dedicated Catalog Name 입력 --> Existing 및 Dedicated 카탈로그 입력 중 잘못 된 형식의 카탈로그 지정 시 다음 과정으로 진행 불가 --> 
 예시)
- Existing Catalog: Win10-MCS
- Dedicated Catalog: Win10-EX
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/23ec5f1f-bf31-4870-acd9-0e12f08d8923)
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/4c3fb447-b41e-458a-a14d-266f749b6b90)


## 잘못된 카탈로그 값 입력 시 오류 상황
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/2a711bed-ec67-40b8-b209-eb504369ed9b)

## 변환 완료
<img width="1040" alt="image" src="https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/d8365c68-b8af-4744-806a-bc7c88442499">

## 변환 완료 후 MCS VM 생성 테스트
이전에 VM-User01에서 VM-User03만 생성되었던 것을 카탈로그 변환 후에도 정상적으로 생성이 가능하게 되었습니다.
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/2654545e-6243-4383-9af2-a03af39a995c)
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/c3b7ac84-e37c-4e02-a569-cfb55286ce39)

# 지원되지 않는 기능
## 변환되기 전 Existing으로 생성된 VM 삭제 시 VM과 AD Computer OU를 삭제하거나 비활성화 하는 기능이 작동하지 않음
![image](https://github.com/LKdiol/Citrix-Existing-to-Dedicated-Converter/assets/126259075/ea6d8486-56cf-4504-8466-7be2eb5dbc02)


