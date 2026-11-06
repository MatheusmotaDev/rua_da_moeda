param([Parameter(ValueFromRemainingArguments = $true)][string[]]$FlutterArguments)
# Work around a broken SDK batch wrapper without changing the installed SDK.
$flutterCommand = Get-Command flutter -ErrorAction Stop
$sdkPath = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent
$gitPath = Join-Path $sdkPath 'bin\mingit\cmd'
if (Test-Path -LiteralPath $gitPath) { $env:PATH = $gitPath + ';' + $env:PATH }
$dartPath = Join-Path $sdkPath 'bin\cache\dart-sdk\bin\dart.exe'
$snapshotPath = Join-Path $sdkPath 'bin\cache\flutter_tools.snapshot'
& $dartPath $snapshotPath @FlutterArguments
exit $LASTEXITCODE
