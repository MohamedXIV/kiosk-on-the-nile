#!/usr/bin/env python3
"""Project release metadata and packaging. No gameplay or save migration work."""
import argparse
import configparser
import datetime as dt
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from functools import lru_cache
from pathlib import Path
from verify_toolchain import verified_engine

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = 'https://github.com/MohamedXIV/kiosk-on-the-nile'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git(*args, optional=False):
    result = subprocess.run(['git', '-C', str(ROOT), *args], capture_output=True, text=True)
    if optional and result.returncode:
        return ''
    require(result.returncode == 0, result.stderr.strip() or 'Git command failed')
    return result.stdout.strip()


def parse_version(value):
    match = re.fullmatch(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-([0-9A-Za-z.-]+))?', value)
    require(match is not None and len(value) <= 80, 'VERSION must be SemVer without build metadata')
    identifiers = match[4].split('.') if match[4] else []
    require(all(re.fullmatch(r'[0-9A-Za-z-]+', part) and not (part.isdigit() and len(part) > 1 and part[0] == '0') for part in identifiers), 'Invalid SemVer prerelease identifiers')
    if identifiers:
        require(len(identifiers) == 2 and identifiers[0] in ['prealpha', 'alpha', 'beta', 'rc'] and identifiers[1].isdigit(), 'Project candidates use channel.N (prealpha, alpha, beta, rc)')
    return tuple(int(match[i]) for i in [1, 2, 3]), identifiers


def version():
    value = (ROOT / 'VERSION').read_text().strip()
    parse_version(value)
    return value


def dirty():
    return bool(git('status', '--porcelain', '--untracked-files=all'))


def source():
    return git('rev-parse', 'HEAD')


def stage(value):
    _, identifiers = parse_version(value)
    return {'prealpha': 'pre-alpha'}.get(identifiers[0], identifiers[0]) if identifiers else 'release'


def check():
    value = version()
    project = (ROOT / 'project.godot').read_text()
    require(re.findall(r'^config/version="([^"]*)"$', project, re.M) == [value], 'Godot version drift; run release.py set-version <VERSION>')
    changelog = (ROOT / 'CHANGELOG.md').read_text()
    require(changelog.count('## [Unreleased]') == 1, 'CHANGELOG requires one Unreleased section')
    return value


def set_version(value):
    new_core, new_pre = parse_version(value)
    if (ROOT / 'VERSION').exists():
        old_core, old_pre = parse_version(version())
        def precedence(core, pre):
            # Our channel.N policy permits a simple SemVer ordering key.
            return core, not bool(pre), pre[0] if pre else '', int(pre[1]) if pre else 0
        require(precedence(new_core, new_pre) >= precedence(old_core, old_pre), 'Version precedence must not decrease')
    project_path = ROOT / 'project.godot'
    project = project_path.read_text()
    line = f'config/version="{value}"'
    if re.search(r'^config/version=', project, re.M):
        project = re.sub(r'^config/version=.*$', line, project, flags=re.M)
    else:
        require('[application]\n' in project, 'Godot application section missing')
        project = project.replace('[application]\n', '[application]\n' + line + '\n', 1)
    (ROOT / 'VERSION').write_text(value + '\n')
    project_path.write_text(project)
    check()


def check_tag(tag=None):
    value = check()
    expected = 'v' + value
    require(tag is None or tag == expected, f'Tag must match VERSION: {expected}')
    require(not dirty(), 'Formal release requires a clean source tree')
    require(git('cat-file', '-t', f'refs/tags/{expected}', optional=True) == 'tag', 'Formal release requires a matching annotated tag')
    require(git('rev-parse', f'refs/tags/{expected}^{{}}') == source(), 'Tag does not identify this source commit')
    text = (ROOT / 'CHANGELOG.md').read_text()
    entry = re.search(r'^## \[' + re.escape(value) + r'\] - (\d{4}-\d{2}-\d{2})\n(.*?)(?=^## |\Z)', text, re.M | re.S)
    require(entry is not None, 'Formal release requires a dated changelog entry')
    dt.date.fromisoformat(entry[1])
    require('**Save compatibility:**' in entry[2], 'Release entry must state save compatibility/reset impact')
    return expected


def tagged():
    try:
        return check_tag()
    except ValueError:
        return None


def stem():
    return f'kiosk-{check()}-{source()[:12]}'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_map(directory):
    require(directory.is_dir() and not directory.is_symlink(), 'Expected a real directory')
    result = {}
    for path in sorted(directory.rglob('*')):
        require(not path.is_symlink(), f'Symlinks are not release inputs: {path}')
        if path.is_file():
            result[path.relative_to(directory).as_posix()] = sha(path.read_bytes())
    return result


def content_digest(files):
    return sha(json.dumps(files, sort_keys=True, separators=(',', ':')).encode())


def save_format():
    text = (ROOT / 'game/persistence/save_codec.gd').read_text()
    result = {}
    for key, constant in [('schema', 'SCHEMA_VERSION'), ('revision', 'SCHEMA_REVISION')]:
        match = re.search(r'^const ' + constant + r' := ([0-9]+)$', text, re.M)
        require(match is not None, f'Missing save-format constant: {constant}')
        result[key] = int(match[1])
    return result


@lru_cache(maxsize=1)
def engine():
    return verified_engine()


def context():
    return dict(version=check(), source=source(), source_dirty=dirty(), engine=engine(), save_format=save_format(), content_sha256=content_digest(file_map(ROOT / 'content')))


def export_files(web_root):
    build_stem = stem()
    files = file_map(web_root)
    files.pop('BUILD.json', None)
    require('index.html' in files and 'content/manifest.json' in files, 'Incomplete Web export')
    for name in files:
        require(name == 'index.html' or name.startswith('content/') or ('/' not in name and name.startswith(build_stem + '.')), f'Unexpected/stale export file: {name}')
    for suffix in ['.wasm', '.pck', '.js']:
        require(build_stem + suffix in files, f'Missing matching engine file: {build_stem + suffix}')
    require(sum(name.endswith('.wasm') for name in files) == 1 and sum(name.endswith('.pck') for name in files) == 1, 'Export must contain one WASM/PCK pair')
    require(build_stem + '.js' in (web_root / 'index.html').read_text(), 'HTML references a different engine')
    return files


def metadata(web_root, mode, initial_context):
    value = check()
    require(isinstance(initial_context, dict) and initial_context == context(), 'Source/version/content/cleanliness changed during export; rebuild')
    files = export_files(web_root)
    expected_content = file_map(ROOT / 'content')
    actual_content = {name.removeprefix('content/'): digest for name, digest in files.items() if name.startswith('content/')}
    require(actual_content == expected_content, 'Exported content differs from source; rebuild into a fresh directory')
    require(files[stem() + '.wasm'] == engine()['web_wasm_sha256'][mode], 'Exported WASM differs from the verified selected template')
    tag = tagged()
    result = dict(build_manifest_version=1, version=value, stage=stage(value), source=source(), source_dirty=dirty(), source_tag=tag,
                  publication_state='tagged' if tag else 'development', build_mode=mode, build_id=f'{value}+g{source()[:12]}',
                  engine=engine(), save_format=save_format(), engine_stem=stem(), content_sha256=content_digest(expected_content),
                  built_at_utc=dt.datetime.now(dt.timezone.utc).isoformat(), files=files)
    (web_root / 'BUILD.json').write_text(json.dumps(result, indent=2) + '\n')


def package(web_root, out, formal):
    value = check()
    require((web_root / 'BUILD.json').is_file(), 'Build metadata missing; export through tools/build.sh')
    data = json.loads((web_root / 'BUILD.json').read_text())
    require(isinstance(data, dict), 'Build metadata must be an object')
    require(data.get('build_manifest_version') == 1 and data.get('source') == source() and data.get('version') == value, 'Stale export source/version; rebuild')
    require(data.get('engine') == engine() and data.get('save_format') == save_format() and data.get('engine_stem') == stem(), 'Export toolchain/format metadata mismatch')
    require(data.get('source_dirty') == dirty(), 'Source cleanliness changed after export; rebuild')
    require(data.get('files') == export_files(web_root), 'Export files changed after metadata generation')
    actual_content = {name.removeprefix('content/'): digest for name, digest in data['files'].items() if name.startswith('content/')}
    require(actual_content == file_map(ROOT / 'content'), 'Packaged content differs from current source')
    require(data.get('content_sha256') == content_digest(file_map(ROOT / 'content')), 'Source content changed after export')
    mode = data.get('build_mode')
    require(mode in ['debug', 'release'] and data['files'][stem() + '.wasm'] == engine()['web_wasm_sha256'][mode], 'Package WASM differs from the verified template')
    if formal:
        tag = check_tag()
        require(data.get('source_tag') == tag and data.get('publication_state') == 'tagged' and data.get('build_mode') == 'release', 'Formal package requires an optimized export from the tagged source')
    filename = f'kiosk-on-the-nile-{value}' + ('' if formal else f'-dev-{source()[:12]}') + '-web.zip'
    target = out / filename if out.suffix != '.zip' else out
    require(not formal or target.name == filename, 'Formal package filename must include its canonical version/platform')
    require(target.resolve() != web_root.resolve() and web_root.resolve() not in target.resolve().parents, 'Package output must be outside the Web root')
    require(not target.exists() and not target.with_suffix(target.suffix + '.sha256').exists(), 'Package/checksum already exists; do not overwrite published/reviewed bytes')
    target.parent.mkdir(parents=True, exist_ok=True)
    run = f'Version: {value}\nStage: {stage(value)}\nSource: {source()}\nExtract into a fresh folder and keep all files together.\nWindows: py -m http.server 8765 --bind 127.0.0.1\nLinux/macOS: python3 -m http.server 8765 --bind 127.0.0.1\nOpen http://127.0.0.1:8765/ (never file://).\nSee CHANGELOG.md for save/reset impact and known limits.\n'
    with zipfile.ZipFile(target, 'x', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in sorted([*data['files'], 'BUILD.json']):
            payload = (web_root / name).read_bytes()
            if name == 'BUILD.json':
                require(json.loads(payload) == data, 'Build metadata changed while packaging')
            else:
                require(sha(payload) == data['files'][name], f'Export changed while packaging: {name}')
            archive.writestr(name, payload)
        for path, name in [(ROOT / 'VERSION', 'VERSION'), (ROOT / 'CHANGELOG.md', 'CHANGELOG.md'), (ROOT / 'docs/RELEASING.md', 'RELEASING.md'),
                           (ROOT / 'docs/PLAYTEST_GUIDE_AR.md', 'PLAYTEST_GUIDE_AR.md'),
                           (ROOT / 'third_party/licenses/Godot-LICENSE.txt', 'licenses/Godot-LICENSE.txt'), (ROOT / 'assets/fonts/OFL.txt', 'licenses/Cairo-OFL.txt'),
                           (ROOT / 'addons/inkgd/LICENSE', 'licenses/inkgd-LICENSE'), (ROOT / 'addons/inkgd/UPSTREAM_LICENSE.txt', 'licenses/inkgd-UPSTREAM_LICENSE.txt')]:
            archive.write(path, name)
        archive.writestr('RUN.txt', run)
    digest = sha(target.read_bytes())
    target.with_suffix(target.suffix + '.sha256').write_text(f'{digest}  {target.name}\n')
    print(json.dumps({'path': str(target), 'bytes': target.stat().st_size, 'sha256': digest}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('check')
    commands.add_parser('stem')
    commands.add_parser('context')
    commands.add_parser('toolchain')
    set_parser = commands.add_parser('set-version'); set_parser.add_argument('version')
    tag_parser = commands.add_parser('check-tag'); tag_parser.add_argument('--tag')
    meta_parser = commands.add_parser('metadata'); meta_parser.add_argument('--web-root', type=Path, required=True); meta_parser.add_argument('--mode', choices=['debug', 'release'], required=True); meta_parser.add_argument('--context', required=True)
    package_parser = commands.add_parser('package'); package_parser.add_argument('--web-root', type=Path, required=True); package_parser.add_argument('--out', type=Path, required=True); package_parser.add_argument('--release', action='store_true')
    args = parser.parse_args()
    try:
        if args.command == 'check': print(check())
        elif args.command == 'stem': print(stem())
        elif args.command == 'context': print(json.dumps(context()))
        elif args.command == 'toolchain': print(json.dumps(engine(), indent=2))
        elif args.command == 'set-version': set_version(args.version); print(check())
        elif args.command == 'check-tag': print(check_tag(args.tag))
        elif args.command == 'metadata': metadata(args.web_root, args.mode, json.loads(args.context))
        elif args.command == 'package': package(args.web_root, args.out, args.release)
    except (ValueError, OSError, KeyError, json.JSONDecodeError, subprocess.SubprocessError, configparser.Error) as error:
        parser.exit(1, f'Release error: {error}\n')


if __name__ == '__main__':
    main()
