#!/usr/bin/env python3
"""Export stable authored Ink references for translators; --check is content validation, not a gameplay test."""
import argparse,json,re
from pathlib import Path
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');parser.add_argument('--out');args=parser.parse_args()
ar=json.loads((root/'content/locales/ar_EG.json').read_text())['messages'];en=json.loads((root/'content/locales/en.json').read_text())['messages']
records=[];seen=set()
for path in sorted((root/'content/stories').glob('*.ink')):
 for number,line in enumerate(path.read_text().splitlines(),1):
  for id in re.findall(r'#\s*loc:([a-zA-Z0-9_.]+)',line):
   if id in seen:raise SystemExit('Duplicate Ink localization ID: '+id)
   seen.add(id)
   if id not in ar or id not in en:raise SystemExit('Missing shipped Ink translation: '+id)
   if sorted(re.findall(r'\{(\w+)\}',ar[id]))!=sorted(re.findall(r'\{(\w+)\}',en[id])):raise SystemExit('Parameter mismatch: '+id)
   records.append({'id':id,'source_file':str(path.relative_to(root)),'line':number,'kind':'choice' if '[' in line else 'line','speaker':'fathi' if path.stem=='supplier' else '', 'ar_EG':ar[id],'en':en[id]})
if args.out:Path(args.out).write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
print(str(len(records))+' stable Ink localization references validated')
