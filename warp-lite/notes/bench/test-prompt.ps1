. "$env:TEMP\warp-lite-prompt.ps1"
$result = prompt
[Console]::Error.WriteLine("RET=[$result]")
[Console]::Error.WriteLine("DEF=[" + (Get-Command prompt).Definition + "]")
