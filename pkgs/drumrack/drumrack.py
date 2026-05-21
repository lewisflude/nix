#!/usr/bin/env python3
"""Generate Ableton Drum Rack .adg files from samples.

Two modes:
  build-from-folder  Auto-categorise a kit folder (Kicks/Snares/Hats/…) and
                     emit a 4×4 Push-layout rack.
  build-from-spec    Build from an explicit JSON pad list (stdin or file).

The .adg is gzipped Live 12 XML. We mutate a vendored template (Sewer Drums,
16 single-sample pads, no InstrumentGroupDevice wrapper), keeping only the
pads we need and rewriting each branch's UserName, ReceivingNote, and
FileRef (Path, OriginalFileSize, OriginalCrc).

Sample paths are translated Linux → macOS (SMB mount) so Ableton on Mercury
resolves them. ReceivingNote is encoded as 127 − midi_note, matching the
template's existing values (verified empirically once the first rack loads).
"""

from __future__ import annotations

import argparse
import gzip
import io
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

DEFAULT_LINUX_PREFIX = "/home/lewisflude/Music/samples/"
DEFAULT_MAC_PREFIX = "/Users/lewisflude/mnt/jupiter-music/samples/"
DEFAULT_TEMPLATE = str(Path(__file__).resolve().parent / "sewer.adg")

SAMPLE_EXTS = {".wav", ".aif", ".aiff", ".flac"}
MAX_PADS = 16

# Category buckets and the MIDI notes (C1-D#2 Push layout) they fill.
# Pads are 4×4: row 1 (bottom) = kicks, row 2 = snares, row 3 = hats, row 4 = percs.
CATEGORY_NOTES = {
    "kick": [36, 37, 38, 39],
    "snare": [40, 41, 42, 43],
    "hat": [44, 45, 46, 47],
    "perc": [48, 49, 50, 51],
}

CATEGORY_PATTERNS = [
    ("kick", re.compile(r"\bkick", re.I)),
    ("snare", re.compile(r"\b(snare|clap|rim)\b", re.I)),
    ("hat", re.compile(r"\b(hat|hihat|hi-hat|hh)\b", re.I)),
    ("perc", re.compile(r"\b(perc|tom|ride|crash|cymbal|fx|shake|tamb|cowbell)\b", re.I)),
]


@dataclass
class PadSpec:
    midi_note: int
    name: str
    sample: Path  # absolute Linux path


# ─────────────────────────────────────────────────────────────────────
# CRC-16-CCITT-FALSE (poly 0x1021, init 0xFFFF, no xorout/reflect)
# ─────────────────────────────────────────────────────────────────────

def crc16_ccitt_false(data: bytes, crc: int = 0xFFFF) -> int:
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def compute_file_crc(path: Path, max_bytes: int = 16384) -> int:
    with path.open("rb") as fh:
        return crc16_ccitt_false(fh.read(max_bytes))


# ─────────────────────────────────────────────────────────────────────
# Path translation
# ─────────────────────────────────────────────────────────────────────

def linux_to_mac(path: Path, linux_prefix: str, mac_prefix: str) -> str:
    s = str(path)
    if not s.startswith(linux_prefix):
        raise ValueError(
            f"Sample {s!r} is not under linux prefix {linux_prefix!r}; "
            "use --linux-prefix to override"
        )
    return mac_prefix + s[len(linux_prefix):]


# ─────────────────────────────────────────────────────────────────────
# Category detection
# ─────────────────────────────────────────────────────────────────────

def _classify(name: str) -> str:
    for label, pat in CATEGORY_PATTERNS:
        if pat.search(name):
            return label
    return "misc"


def categorise(folder: Path) -> dict[str, list[Path]]:
    """Walk folder, group samples by category using folder and filename hints."""
    buckets: dict[str, list[Path]] = defaultdict(list)
    for root, _, files in os.walk(folder, followlinks=False):
        root_path = Path(root)
        folder_label = _classify(root_path.name)
        for fname in files:
            if Path(fname).suffix.lower() not in SAMPLE_EXTS:
                continue
            label = folder_label if folder_label != "misc" else _classify(fname)
            buckets[label].append(root_path / fname)
    for samples in buckets.values():
        samples.sort()
    return dict(buckets)


def assign_pads(buckets: dict[str, list[Path]]) -> list[PadSpec]:
    """Map categorised samples to the 4×4 Push layout, alphabetical pick."""
    pads: list[PadSpec] = []
    for category, notes in CATEGORY_NOTES.items():
        samples = buckets.get(category, [])
        for note, sample in zip(notes, samples):
            pads.append(PadSpec(midi_note=note, name=sample.stem, sample=sample))
    pads.sort(key=lambda p: p.midi_note)
    return pads


# ─────────────────────────────────────────────────────────────────────
# Template mutation
# ─────────────────────────────────────────────────────────────────────

def load_template(template_path: str | None = None) -> ET.ElementTree:
    path = template_path or os.environ.get("DRUMRACK_TEMPLATE") or DEFAULT_TEMPLATE
    with gzip.open(path, "rb") as fh:
        return ET.parse(fh)  # type: ignore[return-value]


def _find_branches(root: ET.Element) -> list[ET.Element]:
    # Branches live under DrumGroupDevice/Branches; in Live 12 templates the path is
    # GroupDevicePreset/Device/DrumGroupDevice/Branches/DrumBranchPreset.
    return root.findall(".//DrumBranchPreset")


def _first_descendant(elem: ET.Element, tag: str) -> ET.Element | None:
    for child in elem.iter(tag):
        if child is not elem:
            return child
    return None


def _require_root(tree: ET.ElementTree) -> ET.Element:
    root = tree.getroot()
    if root is None:
        raise RuntimeError("template has no root element")
    return root


def _set_value(elem: ET.Element, value: str) -> None:
    elem.set("Value", value)


_TEMPLATE_VOLUME_MARKER = "/Volumes/data/tmp/trunk/"
_TEMPLATE_NAME_MARKER = "Sewer Drums.adg"
_TEMPLATE_PACK_NAME = "Lost and Found"
_TEMPLATE_PACK_ID = "www.ableton.com/308"


def _scrub_template_self_refs(root: ET.Element, new_name: str) -> None:
    """Strip every reference to the Sewer template's original location.

    Live serialises a saved preset's path into many places — top-level
    LastPresetRef, the sibling PresetRef on GroupDevicePreset, per-pad
    metadata (LowerDisplayString breadcrumbs), and embedded device-preset
    references inside the pad's effect chain. Leaving these pointing at the
    factory volume confuses Live's "where did this come from" tracking and
    breaks the rack's identity in the browser.

    swap_pad rewrites the per-pad sample FileRef separately; this scrub
    cleans everything else.
    """
    for path_node in root.iter("Path"):
        value = path_node.get("Value") or ""
        if value.startswith(_TEMPLATE_VOLUME_MARKER):
            _set_value(path_node, "")
    for rel_node in root.iter("RelativePath"):
        value = rel_node.get("Value") or ""
        if value.startswith(("Drum Racks/", "Samples/", "Devices/")):
            _set_value(rel_node, "")
    for label in root.iter("UpperDisplayString"):
        if _TEMPLATE_NAME_MARKER in (label.get("Value") or ""):
            _set_value(label, f"{new_name}.adg")
    for label in root.iter("LowerDisplayString"):
        value = label.get("Value") or ""
        if value.startswith("Sewer Drums |"):
            _set_value(label, value.replace("Sewer Drums |", f"{new_name} |", 1))
    for pack_name in root.iter("LivePackName"):
        if (pack_name.get("Value") or "") == _TEMPLATE_PACK_NAME:
            _set_value(pack_name, "")
    for pack_id in root.iter("LivePackId"):
        if (pack_id.get("Value") or "") == _TEMPLATE_PACK_ID:
            _set_value(pack_id, "")
    for rel_type in root.iter("RelativePathType"):
        if (rel_type.get("Value") or "") == "5":
            _set_value(rel_type, "0")


def swap_pad(
    branch: ET.Element,
    pad: PadSpec,
    linux_prefix: str,
    mac_prefix: str,
) -> None:
    """Mutate a single DrumBranchPreset in place to host `pad`."""
    # Pad label — first UserName descendant is the DrumCell's display name.
    user_name = _first_descendant(branch, "UserName")
    if user_name is not None:
        _set_value(user_name, pad.name)

    # ReceivingNote — encoded as 127 − midi_note (matches template range 77–92).
    receiving = branch.find(".//ZoneSettings/ReceivingNote")
    if receiving is not None:
        _set_value(receiving, str(127 - pad.midi_note))

    # Sample display name inside the sampler.
    sample_name = branch.find(".//SampleParts/MultiSamplePart/Name")
    if sample_name is not None:
        _set_value(sample_name, pad.sample.stem)

    # FileRef — rewrite for absolute mac path, real size + CRC, clear pack hints.
    file_ref = branch.find(".//SampleParts/MultiSamplePart/SampleRef/FileRef")
    if file_ref is None:
        raise RuntimeError(f"branch missing FileRef; template malformed?")

    mac_path = linux_to_mac(pad.sample, linux_prefix, mac_prefix)
    size = pad.sample.stat().st_size
    crc = compute_file_crc(pad.sample)

    field_values = {
        "RelativePathType": "0",
        "RelativePath": "",
        "Path": mac_path,
        "Type": "2",
        "LivePackName": "",
        "LivePackId": "",
        "OriginalFileSize": str(size),
        "OriginalCrc": str(crc),
    }
    for tag, value in field_values.items():
        node = file_ref.find(tag)
        if node is None:
            node = ET.SubElement(file_ref, tag)
        _set_value(node, value)

    # LastModDate (sibling of FileRef) — set to source file's mtime so Live's
    # change-detection doesn't flag stale.
    sample_ref = branch.find(".//SampleParts/MultiSamplePart/SampleRef")
    if sample_ref is not None:
        last_mod = sample_ref.find("LastModDate")
        if last_mod is None:
            last_mod = ET.SubElement(sample_ref, "LastModDate")
        _set_value(last_mod, str(int(pad.sample.stat().st_mtime)))


def build_tree(
    pads: list[PadSpec],
    kit_name: str,
    linux_prefix: str,
    mac_prefix: str,
    template_path: str | None = None,
) -> ET.ElementTree:
    if not pads:
        raise ValueError("no pads to build — kit is empty")
    if len(pads) > MAX_PADS:
        raise ValueError(f"too many pads ({len(pads)} > {MAX_PADS}); template caps at 16")

    tree = load_template(template_path)
    root = _require_root(tree)

    # Rename the rack itself.
    rack_name = root.find(".//DrumGroupDevice/UserName")
    if rack_name is not None:
        _set_value(rack_name, kit_name)

    # Annotation under the DrumGroupDevice is "Created by: Iftah Gabbai" in the
    # template — clear it so it doesn't mislead.
    rack_annotation = root.find(".//DrumGroupDevice/Annotation")
    if rack_annotation is not None:
        _set_value(rack_annotation, "")

    _scrub_template_self_refs(root, kit_name)

    branches = _find_branches(root)
    if len(branches) < len(pads):
        raise RuntimeError(
            f"template has {len(branches)} branches but {len(pads)} pads requested"
        )

    # Template encodes pads in descending ReceivingNote order (pad 0 = lowest MIDI),
    # so sort our specs the same way before zipping into existing branches.
    pads_sorted = sorted(pads, key=lambda p: -p.midi_note)

    parent: ET.Element | None = next(
        (p for p in root.iter() if branches[0] in list(p)), None
    )
    if parent is None:
        raise RuntimeError("could not locate Branches parent element")

    for idx, (branch, pad) in enumerate(zip(branches, pads_sorted)):
        swap_pad(branch, pad, linux_prefix, mac_prefix)
        branch.set("Id", str(idx))

    for extra in branches[len(pads_sorted):]:
        parent.remove(extra)

    return tree


def write_adg(tree: ET.ElementTree, out_path: Path, force: bool = False) -> None:
    if out_path.exists() and not force:
        raise FileExistsError(f"refusing to overwrite {out_path} (use --force)")
    tmp = out_path.with_suffix(out_path.suffix + ".tmp")
    xml_bytes = ET.tostring(_require_root(tree), encoding="utf-8")
    # Ableton uses double-quoted, uppercase UTF-8 in the declaration.
    declaration = b'<?xml version="1.0" encoding="UTF-8"?>\n'
    # Build deterministically in memory, then write. Passing filename="" suppresses
    # the FNAME flag (GzipFile would otherwise derive a basename from fileobj.name
    # and embed it in the header, breaking byte-determinism across runs).
    buf = io.BytesIO()
    with gzip.GzipFile(
        filename="", fileobj=buf, mode="wb", compresslevel=6, mtime=0
    ) as fh:
        fh.write(declaration)
        fh.write(xml_bytes)
    tmp.write_bytes(buf.getvalue())
    os.replace(tmp, out_path)


# ─────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────

def _print_table(pads: list[PadSpec]) -> None:
    print(f"{'pad':>3}  {'midi':>4}  {'name':<24}  source")
    print(f"{'-'*3}  {'-'*4}  {'-'*24}  {'-'*40}")
    for i, p in enumerate(sorted(pads, key=lambda p: p.midi_note)):
        print(f"{i+1:>3}  {p.midi_note:>4}  {p.name[:24]:<24}  {p.sample}")


def _resolve_out_path(out: str | None, folder: Path, name: str) -> Path:
    if out:
        return Path(out).expanduser().resolve()
    return folder / f"{name}.adg"


def cmd_build_from_folder(args: argparse.Namespace) -> int:
    folder = Path(args.folder).expanduser().resolve()
    if not folder.is_dir():
        print(f"error: {folder} is not a directory", file=sys.stderr)
        return 2

    name = args.name or folder.name
    buckets = categorise(folder)
    pads = assign_pads(buckets)

    if not pads:
        print(f"error: no samples found in {folder} matching known categories", file=sys.stderr)
        print("  buckets seen:", {k: len(v) for k, v in buckets.items()}, file=sys.stderr)
        return 3

    out_path = _resolve_out_path(args.out, folder, name)

    print(f"kit:    {name}")
    print(f"source: {folder}")
    print(f"output: {out_path}")
    print()
    _print_table(pads)
    print()
    print(f"categories filled: {[k for k in CATEGORY_NOTES if buckets.get(k)]}")
    print(f"pads:              {len(pads)}/16")

    if args.dry_run:
        print("\n(dry-run; no .adg written)")
        return 0

    tree = build_tree(pads, name, args.linux_prefix, args.mac_prefix, args.template)
    write_adg(tree, out_path, force=args.force)
    print(f"\nwrote {out_path}")
    mac_out = linux_to_mac(out_path, args.linux_prefix, args.mac_prefix) \
        if str(out_path).startswith(args.linux_prefix) else None
    if mac_out:
        print(f"mac path: {mac_out}")
    return 0


def cmd_build_from_spec(args: argparse.Namespace) -> int:
    raw = sys.stdin.read() if args.spec == "-" else Path(args.spec).read_text()
    spec = json.loads(raw)

    pads = [
        PadSpec(midi_note=p["midi_note"], name=p["name"], sample=Path(p["sample"]).expanduser().resolve())
        for p in spec["pads"]
    ]
    name = spec.get("name", "Drum Rack")
    out_path = Path(args.out or spec["out_path"]).expanduser().resolve()

    print(f"kit:    {name}")
    print(f"output: {out_path}")
    _print_table(pads)

    if args.dry_run:
        print("\n(dry-run; no .adg written)")
        return 0

    tree = build_tree(pads, name, args.linux_prefix, args.mac_prefix, args.template)
    write_adg(tree, out_path, force=args.force)
    print(f"\nwrote {out_path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    summary = (__doc__ or "").splitlines()[0] if __doc__ else "Generate Ableton Drum Racks"
    parser = argparse.ArgumentParser(prog="drumrack", description=summary)
    parser.add_argument("--template", help=f"path to .adg template (default: {DEFAULT_TEMPLATE})")
    parser.add_argument("--linux-prefix", default=DEFAULT_LINUX_PREFIX,
                        help=f"linux sample prefix (default: {DEFAULT_LINUX_PREFIX})")
    parser.add_argument("--mac-prefix", default=DEFAULT_MAC_PREFIX,
                        help=f"mac sample prefix (default: {DEFAULT_MAC_PREFIX})")

    sub = parser.add_subparsers(dest="cmd", required=True)

    folder = sub.add_parser("build-from-folder", help="build a rack from a categorised kit folder")
    folder.add_argument("folder", help="kit folder with Kicks/Snares/Hats subfolders or labelled filenames")
    folder.add_argument("--out", help="output .adg path (default: <folder>/<folder-name>.adg)")
    folder.add_argument("--name", help="rack display name (default: folder basename)")
    folder.add_argument("--dry-run", action="store_true", help="print the pad table and exit")
    folder.add_argument("--force", action="store_true", help="overwrite existing .adg")
    folder.set_defaults(func=cmd_build_from_folder)

    spec = sub.add_parser("build-from-spec", help="build from a JSON spec (stdin with -, or file)")
    spec.add_argument("spec", help="path to spec JSON, or - for stdin")
    spec.add_argument("--out", help="override output path from spec")
    spec.add_argument("--dry-run", action="store_true")
    spec.add_argument("--force", action="store_true")
    spec.set_defaults(func=cmd_build_from_spec)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
