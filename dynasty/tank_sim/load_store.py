"""Write the raw blocks of the Sleeper data store doc back to files the sim reads.
Usage: python3 load_store.py <path to v*_Sleeper_Data_2026.md> /home/claude/sleeper"""
import re, sys, os, json
src, dst = sys.argv[1], sys.argv[2]; os.makedirs(dst, exist_ok=True)
t = open(src).read()
for nm, body in re.findall(r"### (\w+)\n```json\n(.*?)\n```", t, re.S):
    json.loads(body); open(os.path.join(dst, nm + '.json'), 'w').write(body); print('wrote', nm)
