"""Repack a verified Editor 1.1 ZIP with host tools, without recopying installed apps.

Plugins/servers stay pinned to the same lazy-lock.json. No user state is read.
Requires Python 3.11+ on the build PC only, not to start Hilvim.
"""
import argparse
import hashlib
import json
from datetime import datetime, timezone
import zipfile
from pathlib import Path, PurePosixPath


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--extract", action="store_true")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1]
    base, output = args.base.resolve(), args.output.resolve()
    if output.suffix.lower() != ".zip" or output.exists():
        raise SystemExit("Output must be a new .zip file")
    folder = output.with_suffix("")
    if args.extract and folder.exists():
        raise SystemExit("Extraction folder already exists")
    expected = Path(str(base) + ".sha256").read_text().split()[0]
    with base.open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual != expected:
        raise SystemExit("Base ZIP checksum mismatch")

    root = output.stem + "/"
    replacements = {}
    for name in ("init.lua", "asciiart.txt", "lazy-lock.json", "lazyvim.json", ".neoconf.json", "README.md", "LICENSE"):
        replacements["config/nvim/" + name] = (source / name).read_bytes()
    for path in (source / "lua").rglob("*.lua"):
        replacements["config/nvim/" + path.relative_to(source).as_posix()] = path.read_bytes()
    for name in ("launch.ps1", "launch-editor.ps1", "check-editor.lua", "check-portable.lua", "install-local.ps1", "debugpy-launcher.py"):
        replacements["scripts/" + name] = (source / "portable" / name).read_bytes()
    for name in ("Hilvim.cmd", "Comprobar.cmd", "Instalar-en-esta-PC.cmd", "LEEME.txt"):
        replacements[name] = (source / "portable" / name).read_bytes()
    replacements["data/nvim-data/mason/bin/debugpy-adapter.cmd"] = (source / "portable/debugpy-adapter.cmd").read_bytes()
    replacements["data/nvim-data/mason/packages/debugpy/debugpy-adapter.cmd"] = replacements["data/nvim-data/mason/bin/debugpy-adapter.cmd"]
    replacements["data/nvim-data/mason/packages/jdtls/jdtls.cmd"] = (source / "portable/jdtls.cmd").read_bytes()
    forbidden = ("tools/git/", "tools/node/", "tools/python/", "tools/dotnet/", "tools/java/", "tools/gcc/",
                 "cache/", "state/", "user/", "temp/", "config/github-copilot/", "config/gh/",
                 "licenses/git/", "licenses/node/", "licenses/python/", "tools/bin/tree-sitter.exe")
    debugpy_prefix = "tools/python/Lib/site-packages/"
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(base) as previous:
        base_root = base.stem + "/"
        if previous.read(base_root + "config/nvim/lazy-lock.json") != replacements["config/nvim/lazy-lock.json"]:
            raise SystemExit("Plugin lock changed; use build-portable.ps1 instead")
        manifest = json.loads(previous.read(base_root + "bundle.json"))
        if manifest.get("profile") != "editor":
            raise SystemExit("Base must be an Editor bundle")
        lock = json.loads(replacements["config/nvim/lazy-lock.json"])
        tag = previous.read(base_root + "data/nvim-data/lazy/blink.cmp/target/release/version").decode().strip()
        if not tag.startswith("v"):
            raise SystemExit("Expected a tagged prebuilt Blink native library")
        manifest.update(hostTools=True, blink={"tag": tag, "sha": lock["blink.cmp"]["commit"]},
                        built=datetime.now(timezone.utc).isoformat(), repackedFromSHA256=actual)
        replacements["bundle.json"] = json.dumps(manifest, indent=2).encode()
        seen = set()
        with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as packed:
            for info in previous.infolist():
                if not info.filename.startswith(base_root):
                    raise ValueError("Unexpected ZIP root")
                relative = info.filename[len(base_root):]
                path = PurePosixPath(relative)
                if path.is_absolute() or ".." in path.parts or "\\" in relative or ":" in relative:
                    raise ValueError("Unsafe ZIP entry")
                if info.is_dir():
                    continue
                # Keep the adapter package, not its Python runtime.
                if relative.startswith(debugpy_prefix + "debugpy"):
                    relative = "data/nvim-data/mason/packages/debugpy/lib/" + relative[len(debugpy_prefix):]
                elif relative.startswith(forbidden) or ".git" in path.parts:
                    continue
                if relative in seen:
                    raise ValueError("Duplicate ZIP entry: " + relative)
                seen.add(relative)
                packed.writestr(root + relative, replacements.pop(relative) if relative in replacements else previous.read(info))
            for relative, content in replacements.items():
                packed.writestr(root + relative, content)
    with output.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    Path(str(output) + ".sha256").write_text(digest + "  " + output.name + "\n", encoding="ascii")
    with zipfile.ZipFile(output) as packed:
        if packed.testzip() is not None:
            raise ValueError("Output CRC failure")
        if args.extract:
            # Entries were validated above; root matches the new, absent folder.
            packed.extractall(output.parent)
        print(f"REPACK_VERIFIED files={len(packed.infolist())} bytes={output.stat().st_size} sha256={digest}", flush=True)


if __name__ == "__main__":
    main()
