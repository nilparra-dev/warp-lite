# Benchmarks

This directory keeps the measurements and screenshots referenced by the phase reports. The JSON files are historical evidence; the PNGs are UI captures.

Large inputs and logs are deliberately not tracked (see `../.gitignore`). Regenerate them when needed.

## 19 MB throughput input

```powershell
# ~200k lines, 19 MB
$line = 'abcdefghijklmnopqrstuvwxyz0123456789'
1..200000 | ForEach-Object { "$line $_" } | Set-Content .\big.txt
```

## 1 MB throughput input

```powershell
$line = 'abcdefghijklmnopqrstuvwxyz0123456789'
1..10000 | ForEach-Object { "$line $_" } | Set-Content .\big1.txt
```

## Throughput inside the terminal

From a shell inside Warp/warp-lite:

```cmd
notes\bench\throughput.cmd
```

The script writes `throughput-done.txt` when it finishes; measure the wall time around it.

## Startup and memory

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\warp-lite\scripts\measure-startup.ps1 -Exe .\target\release\warp-oss.exe -Runs 5
```

Results are written as `startup-<timestamp>.json` in this directory.

## PTY ceiling

`ptybench.cmd` feeds `big.txt` through a raw PTY process. `scripts/conpty_bench.py` is the pywinpty variant and expects the `big.txt` file in this directory.
