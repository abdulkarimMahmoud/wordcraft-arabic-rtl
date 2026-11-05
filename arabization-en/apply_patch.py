#!/usr/bin/env python3
"""Apply this fork's Arabic TSV corrections to a craft-i18n checkout."""
import os
from pathlib import Path

root = Path(os.environ['CRAFT_I18N_DIR']) / 'locales' / 'ar'
patch_path = Path(__file__).with_name('04-Translation-Patch.tsv')
if not root.is_dir():
    raise SystemExit(f'Arabic catalog directory does not exist: {root}')
patch = {}
for lineno, line in enumerate(patch_path.read_text(encoding='utf-8').splitlines(), 1):
    if not line.strip() or line.lstrip().startswith('#'):
        continue
    parts = line.split('\t')
    if len(parts) == 3:
        context, english, translated = parts
    elif len(parts) == 2:
        context, (english, translated) = '', parts
    else:
        raise SystemExit(f'{patch_path}:{lineno}: expected two or three TSV columns')
    key = (context.strip(), english.strip())
    if not key[1] or not translated.strip() or key in patch:
        raise SystemExit(f'{patch_path}:{lineno}: blank or duplicate key')
    patch[key] = translated.strip()
if not patch:
    raise SystemExit('Arabic patch is empty')

present = set()
for name in ('common.tsv', 'wordcraft.tsv', 'pdfcraft.tsv', 'cadcraft.tsv'):
    path = root / name
    if not path.is_file():
        if name in ('common.tsv', 'wordcraft.tsv'):
            raise SystemExit(f'Required Arabic catalog missing: {path}')
        continue
    out = []
    changed = 0
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip() or line.startswith('#'):
            out.append(line)
            continue
        cols = line.split('\t', 2)
        if len(cols) < 3:
            out.append(line)
            continue
        key = (cols[0], cols[1])
        if name in ('common.tsv', 'wordcraft.tsv'):
            present.add(key)
        if key in patch:
            out.append(f'{key[0]}\t{key[1]}\t{patch[key]}')
            changed += 1
        else:
            out.append(line)
    path.write_text('\n'.join(out) + '\n', encoding='utf-8')
    print(f'{name}: updated {changed} Arabic entries')

missing = [(context, english, translated) for (context, english), translated in patch.items() if (context, english) not in present]
if missing:
    with (root / 'wordcraft.tsv').open('a', encoding='utf-8') as f:
        for context, english, translated in missing:
            f.write(f'{context}\t{english}\t{translated}\n')
    print(f'wordcraft.tsv: added {len(missing)} missing Arabic entries')

home = patch.get(('', 'Home'))
if not home or f'\tHome\t{home}' not in (root / 'common.tsv').read_text(encoding='utf-8').splitlines():
    raise SystemExit('Arabic Home translation was not correctly patched')
print(f'Applied {len(patch)} Arabic correction keys; Home verified')
