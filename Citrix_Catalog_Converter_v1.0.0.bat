@echo off
set batscript=Citrix_Catalog_Converter_v1.0.0.bat
set location=%~dp0
cd %location%
"%location%bin\iconv" -f UTF-8 -t CP949 "%location%bin\install.bat" > temp.bat
echo move %batscript% bat.del > bin\temp2.bat
echo move temp.bat %batscript% >> bin\temp2.bat
echo start %batscript% >> bin\temp2.bat
echo del bat.del "%location%bin\install.bat" >> bin\temp2.bat
echo exit >> bin\temp2.bat
start bin\temp2.bat
