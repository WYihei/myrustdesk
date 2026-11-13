"""Package a built Flutter release as the Carousel single Windows executable."""
import argparse
import base64
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dist', type=Path, default=ROOT / 'flutter/build/windows/x64/runner/Release')
    parser.add_argument('--check', action='store_true', help='Check configuration and inputs without packaging')
    args = parser.parse_args()
    data = json.loads((ROOT / 'res/carousel/client.json').read_text(encoding='utf-8'))
    if not data['id_server'] or len(base64.b64decode(data['public_key'], validate=True)) != 32:
        raise SystemExit('Configure a server address and a 32-byte public key in res/carousel/client.json')
    if args.check:
        print('Server configuration valid. Only a public key is embedded; key not printed.')
        return
    source = args.dist.resolve()
    binary = source / 'rustdesk.exe'
    if not binary.is_file():
        raise SystemExit(f'Build Flutter Windows first. Missing {binary}')
    # Stage separately: keep the original Flutter output usable by upstream tools.
    stage = ROOT / 'dist/carousel-payload'
    if stage.exists():
        raise SystemExit(f'{stage} already exists. Move it aside before packaging again.')
    shutil.copytree(source, stage)
    (stage / 'rustdesk.exe').rename(stage / 'CarouselRemote.exe')
    packer = ROOT / 'libs/portable'
    subprocess.run([sys.executable, str(packer / 'generate.py'), '-f', str(stage),
                    '-o', str(packer), '-e', str(stage / 'CarouselRemote.exe')],
                   cwd=ROOT, check=True)
    output = ROOT / 'dist/旋转木马远程桌面.exe'
    shutil.copy2(ROOT / 'target/release/rustdesk-portable-packer.exe', output)
    print('Created Carousel Windows EXE in dist/.')


if __name__ == '__main__':
    main()
