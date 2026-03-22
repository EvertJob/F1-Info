import re
from pathlib import Path

text = Path("lib/main.dart").read_text(encoding="utf-8")
keys = re.findall(r"'([a-zA-Z0-9_]+)'\.tr\(", text)
keys2 = re.findall(r"\.tr\('([a-zA-Z0-9_]+)'", text)
print("simple .tr:", len(keys), "unique:", len(set(keys)))
print("context.tr:", len(keys2), "unique:", len(set(keys2)))
allk = sorted(set(keys) | set(keys2))
for k in allk:
    print(k)
