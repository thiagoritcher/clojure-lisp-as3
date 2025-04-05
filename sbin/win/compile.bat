@echo off
call %FLEX_HOME%\bin\mxmlc.exe ^
-output bin-release/repl.swf ^
-compiler.source-path=src ^
-compiler.verbose-stacktraces=true ^
-static-link-runtime-shared-libraries=true ^
-compiler.optimize=false ^
-warnings ^
-debug=true ^
src\componentes\REPL.as
