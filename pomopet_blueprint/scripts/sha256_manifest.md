# SHA256 manifest generation

Remote hot-update `manifest.json` should include real sha256 for each file.

Node:

```bash
node -e "const fs=require('fs');const crypto=require('crypto');const files=['strings_zh.json','events.json','game_config.json','timer_presets.json'];for(const f of files){const b=fs.readFileSync(f);const h=crypto.createHash('sha256').update(b).digest('hex');console.log(f,h)}"
```

Python:

```bash
python3 - <<'PY'
import hashlib
files=['strings_zh.json','events.json','game_config.json','timer_presets.json']
for f in files:
    h=hashlib.sha256(open(f,'rb').read()).hexdigest()
    print(f,h)
PY
```
