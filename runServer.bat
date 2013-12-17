@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "node_modules\coffee-script\bin\coffee" server.coffee
) ELSE (
  node  "node_modules\coffee-script\bin\coffee" server.coffee
)
PAUSE
