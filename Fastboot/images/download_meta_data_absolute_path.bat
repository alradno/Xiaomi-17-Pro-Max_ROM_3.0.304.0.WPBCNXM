@REM @echo off
setlocal enabledelayedexpansion

:: 获取当前目录
set "current_dir=%cd%"

:: 替换反斜杠为双反斜杠，以便在JSON中使用
set "current_dir=%current_dir:\=\\%"

:: 读取download_meta_data.json文件内容
set "json_content="
for /f "usebackq delims=" %%a in ("download_meta_data.json") do (
    set "line=%%a"
    :: 替换path\为当前目录
    set "line=!line:.\\=%current_dir%\\!"
    set "json_content=!json_content!!line!"
)

:: 将修改后的内容写回download_meta_data.json
echo !json_content! > download_meta_data.json

echo 当前目录已替换到download_meta_data.json中的path。