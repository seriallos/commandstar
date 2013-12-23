cd %~dp0

@IF EXIST "%~dp0\npm" (
  call "%~dp0\npm" install
) ELSE (
  call npm install
)

@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\node_modules\coffee-script\bin\coffee" lib\comandstar.coffee
) ELSE (
  node  "%~dp0\node_modules\coffee-script\bin\coffee" lib\commandstar.coffee
)

PAUSE

