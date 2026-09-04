#!/usr/bin/env python3
"""Verify downloaded unsigned iPhone IPA against its CI manifest and checksum."""
import argparse
import hashlib
import json
import plistlib
import struct
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("ipa", type=Path)
parser.add_argument("--version", required=True)
parser.add_argument("--build", required=True)
parser.add_argument("--commit", required=True)
args = parser.parse_args()

digest = hashlib.sha256(args.ipa.read_bytes()).hexdigest()
root = args.ipa.parent
manifest = (root / "build-manifest.txt").read_text(encoding="utf-8")
checksums = (root / "SHA256SUMS.txt").read_text(encoding="utf-8")
assert digest in checksums.lower(), "IPA checksum mismatch"
assert f"Commit: {args.commit}" in manifest, "Commit manifest mismatch"
with zipfile.ZipFile(args.ipa) as archive:
    info = plistlib.loads(archive.read("Payload/MagicShop.app/Info.plist"))
    assert info["CFBundleShortVersionString"] == args.version, "Marketing version mismatch"
    assert info["CFBundleVersion"] == args.build, "Build mismatch"
    assert info["CFBundleSupportedPlatforms"] == ["iPhoneOS"], "Not an iPhoneOS binary"
    assert info["MinimumOSVersion"] == "16.0", "Unexpected deployment target"
    binary = archive.read(f"Payload/MagicShop.app/{info['CFBundleExecutable']}")
    magic, cpu = struct.unpack("<II", binary[:8])
    assert magic == 0xFEEDFACF and cpu == 0x0100000C, "Not an arm64 Mach-O"
print(json.dumps({
    "result": "PASS",
    "ipa": str(args.ipa.resolve()),
    "sha256": digest,
    "version": args.version,
    "build": args.build,
    "commit": args.commit,
    "platform": "iPhoneOS arm64",
    "minimum_iOS": info["MinimumOSVersion"],
    "installation": "Unsigned; Sideloadly must re-sign. Device install is a separate check."
}, indent=2))