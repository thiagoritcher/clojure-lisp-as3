@echo off
call %FLEX_HOME%\bin\mxmlc.exe ^
-output bin-release/repl-test.swf ^
-compiler.source-path=src ^
-compiler.verbose-stacktraces=true ^
-static-link-runtime-shared-libraries=true ^
-compiler.optimize=false ^
-compiler.incremental=true ^
-warnings ^
-debug=true ^
src\componentes\ReplTEST.as
rem -static-link-runtime-shared-libraries=src ^

start %FLEX_HOME%\runtimes\player\11.1\win\FlashPlayerDebugger.exe bin-release-temp/repl-test.swf &
start %FLEX_HOME%\bin\fdb.exe &

pause
taskkill /f /im FlashPlayerDebugger.exe
taskkill /f /im fdb.exe

