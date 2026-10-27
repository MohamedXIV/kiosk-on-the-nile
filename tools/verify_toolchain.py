"""Verify installed Godot/Web templates against authoritative pinned archives."""
import configparser
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verified_engine():
    lock = json.loads((ROOT / 'tools/dependencies.lock.json').read_text())
    version = lock['godot']['version']
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
        raise ValueError('Toolchain verifier currently expects a stable Godot version')
    archives = {}
    for key in ['godot', 'templates']:
        path = ROOT / '.cache/downloads' / lock[key]['url'].rsplit('/', 1)[-1]
        if not path.is_file() or digest(path) != lock[key]['sha256']:
            raise ValueError(f'{key}: missing/mismatched pinned archive; run tools/setup.sh')
        archives[key] = path
    binary = ROOT / '.cache/bin' / ('godot-' + version)
    with zipfile.ZipFile(archives['godot']) as archive:
        names = [name for name in archive.namelist() if name.endswith('linux.x86_64')]
        if len(names) != 1:
            raise ValueError('Pinned Godot archive layout changed')
        expected_editor = hashlib.sha256(archive.read(names[0])).hexdigest()
    if not binary.is_file() or digest(binary) != expected_editor:
        raise ValueError('Installed Godot differs from pinned archive; run tools/setup.sh')
    reported = subprocess.check_output(['bash', str(ROOT / 'tools/godot.sh'), '--version'], text=True).strip()
    if not reported.startswith(version + '.'):
        raise ValueError('Godot launcher reports a different version')
    template_root = ROOT / '.cache/data/godot/export_templates' / (version + '.stable')
    templates = {}
    with zipfile.ZipFile(archives['templates']) as archive:
        for name in archive.namelist():
            basename = Path(name).name
            if basename == 'version.txt' or (basename.startswith('web_') and basename.endswith('.zip')):
                expected = hashlib.sha256(archive.read(name)).hexdigest()
                installed = template_root / basename
                if not installed.is_file() or digest(installed) != expected:
                    raise ValueError(f'Installed template differs from pinned archive: {basename}')
                templates[basename] = expected
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(ROOT / 'export_presets.cfg')
    for section in ['preset.0.options', 'preset.1.options']:
        for key in ['custom_template/debug', 'custom_template/release']:
            if presets.get(section, key, fallback='').strip('"'):
                raise ValueError('Custom templates need an explicit verified-toolchain contract')
        for key in ['variant/extensions_support', 'variant/thread_support']:
            if presets.get(section, key) != 'false':
                raise ValueError('Update the verified-template contract before enabling threads/extensions')
    wasm = {}
    for mode in ['debug', 'release']:
        with zipfile.ZipFile(template_root / f'web_nothreads_{mode}.zip') as archive:
            wasm[mode] = hashlib.sha256(archive.read('godot.wasm')).hexdigest()
    return dict(name='Godot', version=version, reported_version=reported, editor_sha256=expected_editor,
                templates_sha256=templates, web_wasm_sha256=wasm,
                pinned_archives={key: lock[key]['sha256'] for key in archives})
