
1. 安装7z

2. 然后

git clone --recurse-submodules https://github.com/WinMerge/winmerge.git

3. 安装依赖

cd build\WinMergeDownloadDeps
wget https://www.magicnotes.com/steelbytes/SBAppLocale_ENG.zip

.\DownloadDeps.cmd


4. 修改脚本

打开 C:\Users\yoj\code\winmerge\BuildBin.vs2022.cmd

删除

-cscript /nologo ExpandEnvironmenStrings.js Version.in > Version.h

然后打开

C:\Users\yoj\code\winmerge\SetVersion.cmd

将内容修改如下

```
@echo off

set MAJOR=2
set MINOR=16
set REVISION=45
set PATCHLEVEL=1
set STRPRIVATEBUILD=""

set RCVER=%MAJOR%.%MINOR%.%REVISION%.%PATCHLEVEL%
set STRVER=%MAJOR%.%MINOR%.%REVISION%.%PATCHLEVEL%
rem set STRVER=%MAJOR%.%MINOR%.%REVISION%
SET PRIVATEBUILD=%STRPRIVATEBUILD:"=%
if %STRPRIVATEBUILD% == "" (
  set APPVER=%STRVER%
  set SAFEAPPVER=%STRVER%
) else (
  set APPVER=%STRVER%+-%PRIVATEBUILD%
  set SAFEAPPVER=%STRVER%-%PRIVATEBUILD%
)

rem 整合ExpandEnvironmenStrings.js的功能并输出到Version.h
setlocal enabledelayedexpansion
(
for /f "usebackq delims=" %%a in ("Version.in") do (
    call echo %%a
)
) > Version.h
endlocal
```


# Mac编译WinMerge

```
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DwxBUILD_SHARED=OFF \
    -DwxBUILD_SAMPLES=ALL \
    -DwxBUILD_DEMOS=ON \
    -DwxBUILD_TESTS=ALL \
    -DCMAKE_CXX_STANDARD=17
```