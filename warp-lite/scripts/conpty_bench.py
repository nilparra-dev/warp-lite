import time
from pathlib import Path

from winpty import PtyProcess

path = Path(__file__).resolve().parent.parent / "notes" / "bench" / "big.txt"
proc = PtyProcess.spawn("cmd.exe")
time.sleep(0.2)
start = time.perf_counter()
proc.write(f'type "{path}" & echo __DONE__\r\n')
total = 0
seen = ""
while True:
    try:
        data = proc.read(65536)
    except EOFError:
        break
    if data:
        total += len(data)
        seen = (seen + data)[-200:]
        if "__DONE__" in seen:
            break
    elif not proc.isalive():
        break
elapsed = time.perf_counter() - start
mb = total / 1_048_576
print(f"chars={total} mb={mb:.2f} seconds={elapsed:.3f} mbps={mb / elapsed:.2f}")
