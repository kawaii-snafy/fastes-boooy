#!/usr/bin/env python3
"""Package every addon directory under addons/ into dist/<Name>-<Version>.zip.

The version comes from the addon's TOC (``## Version: x.y.z``). The archive holds the
addon folder at its root (``AdventureAtlas/AdventureAtlas.toc``, ...), as WoW expects when the
zip is extracted into ``Interface/AddOns``. Archives are reproducible: entries are sorted,
timestamps are fixed (1980-01-01) and permissions normalized. Dotfiles and editor
leftovers are skipped.

usage:
    python3 -I tools/package_addons.py [--addons DIR] [--dist DIR] [name ...]
"""
import argparse
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SKIP = re.compile(r'(^\.|~$|\.swp$|\.orig$|\.rej$)')
FIXED_TIME = (1980, 1, 1, 0, 0, 0)


def toc_version(addon_dir, name):
    for cand in (name + ".toc", name + "_Camelot.toc", name + "_Mainline.toc"):
        p = os.path.join(addon_dir, cand)
        if os.path.isfile(p):
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                for line in fh:
                    m = re.match(r'^##\s*Version\s*:\s*(\S+)', line.strip())
                    if m:
                        return m.group(1)
            return None
    return None


def files_of(addon_dir):
    out = []
    for base, dirs, files in os.walk(addon_dir):
        dirs[:] = sorted(d for d in dirs if not SKIP.search(d))
        for f in sorted(files):
            if SKIP.search(f):
                continue
            out.append(os.path.join(base, f))
    return sorted(out)


def package(addon_dir, dist):
    name = os.path.basename(addon_dir.rstrip("/"))
    version = toc_version(addon_dir, name)
    if not version:
        print("skip %s: no TOC or no '## Version:'" % name, file=sys.stderr)
        return None
    if not re.match(r'^[A-Za-z0-9._-]+$', version):
        print("skip %s: invalid version %r" % (name, version), file=sys.stderr)
        return None
    os.makedirs(dist, exist_ok=True)
    out = os.path.join(dist, "%s-%s.zip" % (name, version))
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for path in files_of(addon_dir):
            rel = os.path.relpath(path, os.path.dirname(addon_dir.rstrip("/")))
            info = zipfile.ZipInfo(rel.replace(os.sep, "/"), date_time=FIXED_TIME)
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(path, "rb") as fh:
                zf.writestr(info, fh.read())
    print("wrote %s" % os.path.relpath(out, ROOT))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--addons", default=os.path.join(ROOT, "addons"))
    ap.add_argument("--dist", default=os.path.join(ROOT, "dist"))
    ap.add_argument("names", nargs="*", help="addon directory names (default: all)")
    args = ap.parse_args()
    names = args.names or sorted(d for d in os.listdir(args.addons)
                                 if os.path.isdir(os.path.join(args.addons, d)) and not d.startswith("."))
    ok = 0
    for n in names:
        if package(os.path.join(args.addons, n), args.dist):
            ok += 1
    if ok == 0:
        sys.exit("no addon packaged")


if __name__ == "__main__":
    main()
