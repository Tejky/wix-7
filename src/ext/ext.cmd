@setlocal
@pushd %~dp0

@set _C=Debug
@set _L=%~dp0..\..\build\logs
@set _SuppressWixClean=false

:parse_args
@if /i "%1"=="release" set _C=Release
@if /i "%1"=="inc" set _SuppressWixClean=true
@if not "%1"=="" shift & goto parse_args

%~dp0..\..\build\wix\%_C%\publish\wix\wix.exe eula accept wix0
msbuild ext_t.proj -p:Configuration=%_C% -p:SuppressWixClean=%_SuppressWixClean% -p:PlatformToolset=v145 -p:NuGetAuditLevel=critical -p:NuGetAudit=false -m -tl -nologo -bl:%_L%\ext_build.binlog || exit /b

@popd
@endlocal
