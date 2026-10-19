#!/usr/bin/env python3
"""init_project.py -- stamp a fresh template clone as a new project.

Automates section 1 (the "identity stamp") of SETUP-NEW-PROJECT.md: rename the
five document files, fix the paper's LaTeX cross-references, and set the conda
environment name. Optional flags clear the shipped demo/scaffolding (sections
4/5/7). See SETUP-NEW-PROJECT.md for the full, human-readable rationale -- this
script is only the *how* for the mechanical bits; that guide is the *why*.

Deliberate scope (do not widen without updating SETUP-NEW-PROJECT.md):
  - Touches ONLY the document files, their in-paper cross-refs, and
    environment.yml. It never edits prose/config (README.md,
    config.local.mk.example) -- those are the human's job (sections 2/3).
  - Never commits. It stages a clean, reviewable changeset via git and prints
    the commit command for you to run.

Usage:
    python init_project.py <slug> [--drop-demo] [--drop-code-reference]
                                  [--self-destruct] [--dry-run] [--allow-dirty]

Stdlib only, so it runs on a bare clone before the conda env exists.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

# Markers that identify the template repo root (guards against the script being
# copied and run somewhere else).
REPO_MARKERS = ("Makefile", "SETUP-NEW-PROJECT.md", ".git")

# A slug must be a valid conda env name AND a LaTeX filename stem AND safe inside
# \documentclass[...]/\subfile{...}: lowercase, start with a letter, internal
# single hyphens only. Excludes _ . space / % # $ & { } ~ ^ \ which break LaTeX
# or filenames.
SLUG_RE = re.compile(r"^[a-z][a-z0-9]*(-[a-z0-9]+)*$")

# (dir, old_stem) for each document. new_stem swaps "template" for the slug.
# The .tex source and .pdf output share a stem; both move (tracked ones only).
DOC_STEMS = [
    ("writing/notes", "template-notes"),
    ("writing/paper", "template-appendices"),
    ("writing/paper", "template-body"),
    ("writing/paper", "template-combined"),
    ("writing/slides", "template-slides"),
]

# Cross-refs live ONLY in writing/paper/. Anchored to the three macros and the
# three known sibling stems, so it can never match \setbeamertemplate{...} (the
# beamer calls in slides) or prose, and it no-ops on re-run.
CROSSREF_RE = re.compile(
    r"(\\(?:documentclass\[|subfile\{|externaldocument\{))template-(body|appendices|combined)"
)
PAPER_CROSSREF_FILES = (
    "writing/paper/template-body.tex",
    "writing/paper/template-appendices.tex",
    "writing/paper/template-combined.tex",
)

# Section 4 (demo) / 5 (code/reference) / 7 (self-destruct) deletion targets.
DEMO_FILES = [
    "code/fetch/fetch_fred.py",
    "code/build/build_price_rent.py",
    "code/model/step01_solve.m",
    "code/model/step02_plot_transition.do",
    "output/tables/price_rent_corr.tex",
]
DEMO_GLOBS = ["code/analysis/price_rent_*.do"]
DEMO_DIRS = [
    "output/figures/price_rent_scatter",
    "output/figures/price_rent_timeseries",
    "output/figures/solow_transition",
]
CODE_REFERENCE_DIRS = ["code/reference"]
DESTRUCT_FILES = ["SETUP-NEW-PROJECT.md", "RETROFIT-EXISTING-PROJECT.md", "init_project.py"]


# --------------------------------------------------------------------------- #
# Small helpers
# --------------------------------------------------------------------------- #
def die(msg: str) -> "NoReturn":  # type: ignore[name-defined]
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(2)


def run_git(
    args: list[str], *, root: Path, check: bool = True, dry: bool = False
) -> subprocess.CompletedProcess:
    """Run `git -C <root> <args>`. With dry=True, print the command and no-op --
    callers pass dry=dry only for mutating commands."""
    cmd = ["git", "-C", str(root), *args]
    if dry:
        print(f"  [dry-run] would run: git {' '.join(args)}")
        return subprocess.CompletedProcess(cmd, 0, "", "")
    try:
        return subprocess.run(
            cmd, check=check, capture_output=True, text=True
        )
    except FileNotFoundError:
        die("'git' not found on PATH")


def git_query(args: list[str], *, root: Path, check: bool = True) -> subprocess.CompletedProcess:
    """A git call that runs even under --dry-run (read-only)."""
    return run_git(args, root=root, check=check, dry=False)


def tracked(pathspec: str, *, root: Path) -> list[str]:
    """Tracked files matching a pathspec (excludes gitignored build artifacts)."""
    out = git_query(["ls-files", "--", pathspec], root=root).stdout
    return [line for line in out.splitlines() if line]


# --------------------------------------------------------------------------- #
# Validation & guards
# --------------------------------------------------------------------------- #
def validate_slug(slug: str) -> str:
    if slug == "template":
        die("slug 'template' is the template's own name; choose a project slug (e.g. 'vantage')")
    if not (1 <= len(slug) <= 40):
        die(f"slug {slug!r} must be 1-40 characters")
    if not SLUG_RE.match(slug):
        die(
            f"invalid slug {slug!r}: use lowercase letters/digits/hyphens, start with a "
            "letter, no leading/trailing/double hyphen (e.g. 'vantage', 'house-prices')"
        )
    return slug


def check_repo_root(root: Path) -> None:
    missing = [m for m in REPO_MARKERS if not (root / m).exists()]
    if missing:
        die(
            "must be run from the template repo root "
            f"(missing: {', '.join(missing)})"
        )


def ensure_git_repo(root: Path) -> None:
    res = git_query(["rev-parse", "--is-inside-work-tree"], root=root, check=False)
    if res.returncode != 0 or res.stdout.strip() != "true":
        die("not a git repository")


def check_git_clean(root: Path, *, allow_dirty: bool) -> None:
    if allow_dirty:
        return
    dirty = git_query(["status", "--porcelain"], root=root).stdout.strip()
    if dirty:
        die("working tree has uncommitted changes; commit/stash first, or pass --allow-dirty")


def detect_state(root: Path) -> str:
    """pristine | already_stamped | partial, based on remaining template-*.tex
    and the environment.yml env name."""
    tpl = tracked("writing/*/template-*.tex", root=root)
    env_is_template = bool(
        re.search(
            r"^name:\s*template\s*$",
            (root / "environment.yml").read_text("utf-8"),
            re.MULTILINE,
        )
    )
    if len(tpl) == 5 and env_is_template:
        return "pristine"
    if len(tpl) == 0 and not env_is_template:
        return "already_stamped"
    return "partial"


# --------------------------------------------------------------------------- #
# Section 1 -- identity stamp
# --------------------------------------------------------------------------- #
def rename_docs(slug: str, *, root: Path, dry: bool) -> int:
    """git mv each tracked companion of the five stems. Returns files moved."""
    moved = 0
    for d, old_stem in DOC_STEMS:
        new_stem = old_stem.replace("template", slug, 1)
        companions = tracked(f"{d}/{old_stem}.*", root=root)
        if not companions:
            # Already renamed, or nothing tracked -- idempotent skip.
            if tracked(f"{d}/{new_stem}.*", root=root):
                print(f"  {d}/{old_stem}.* -> already renamed, skipping")
            else:
                print(f"  {d}/{old_stem}.* -> no tracked files, skipping")
            continue
        for old in companions:
            new = str(Path(old).with_name(Path(old).name.replace(old_stem, new_stem, 1)))
            run_git(["mv", old, new], root=root, dry=dry)
            moved += 1
    return moved


def fix_crossrefs(slug: str, *, root: Path, dry: bool) -> int:
    """Rewrite the 6 in-paper cross-refs at their post-rename paths. Returns
    total substitutions."""
    total = 0
    edited_files = 0
    for old_rel in PAPER_CROSSREF_FILES:
        new_rel = old_rel.replace("template-", f"{slug}-", 1)
        path = root / new_rel
        if not path.exists():
            # Fall back to the un-renamed path (e.g. crossrefs run standalone).
            path = root / old_rel
            if not path.exists():
                print(f"  {new_rel} -> not found, skipping cross-ref edit")
                continue
        text = path.read_text("utf-8")
        new_text, n = CROSSREF_RE.subn(rf"\g<1>{slug}-\2", text)
        if n:
            total += n
            edited_files += 1
            if dry:
                print(f"  [dry-run] would rewrite {n} cross-ref(s) in {path.relative_to(root)}")
            else:
                path.write_text(new_text, "utf-8")
                run_git(["add", str(path.relative_to(root))], root=root, dry=dry)
    if total:
        verb = "would fix" if dry else "fixed"
        print(f"  {verb} {total} cross-ref(s) in {edited_files} file(s)")
    else:
        print("  no cross-refs to fix (already stamped)")
    return total


def stamp_environment_yml(slug: str, *, root: Path, dry: bool) -> bool:
    """Set the conda env name throughout environment.yml (functional name: line
    plus the header comments that name the env). Anchored subs, idempotent."""
    path = root / "environment.yml"
    text = path.read_text("utf-8")
    subs = [
        (re.compile(r"^name:\s*template\s*$", re.MULTILINE), f"name: {slug}"),
        (re.compile(r'creates env "template"'), f'creates env "{slug}"'),
        (re.compile(r"conda activate template\b"), f"conda activate {slug}"),
        (re.compile(r"`template`"), f"`{slug}`"),
    ]
    new_text = text
    total = 0
    for pat, repl in subs:
        new_text, n = pat.subn(repl, new_text)
        total += n
    if total and not dry:
        path.write_text(new_text, "utf-8")
        run_git(["add", "environment.yml"], root=root, dry=dry)
    if dry and total:
        print(f"  [dry-run] would update {total} env-name token(s) in environment.yml")
    elif total:
        print(f"  stamped environment.yml env name ({total} token(s))")
    else:
        print("  environment.yml env name already stamped")
    return total > 0


def verify_stamp(slug: str, *, root: Path) -> None:
    """Run the guide's own grep check plus a tracked-file assertion. Read-only,
    but the caller skips it under --dry-run (nothing has changed yet, so it would
    spuriously fail)."""
    # The guide's contract: no stray template cross-refs remain.
    res = git_query(
        [
            "grep",
            "-nE",
            r"\\(subfile|documentclass|externaldocument)\{[^}]*template",
            "--",
            "writing/**/*.tex",
        ],
        root=root,
        check=False,
    )
    # git grep: exit 1 == no matches (what we want), 0 == matches found.
    if res.returncode == 0 and res.stdout.strip():
        die("verification failed -- stray template cross-refs remain:\n" + res.stdout)
    if tracked("writing/*/template-*.tex", root=root):
        die("verification failed -- template-*.tex files still tracked")
    print("  verified: 0 stray template refs")


# --------------------------------------------------------------------------- #
# Sections 4/5/7 -- deletions
# --------------------------------------------------------------------------- #
def drop_paths(files: list[str], dirs: list[str], label: str, *, root: Path, dry: bool) -> None:
    removed = 0
    for f in files:
        if tracked(f, root=root):
            run_git(["rm", f], root=root, dry=dry)
            removed += 1
        else:
            print(f"  {f} -> already removed, skipping")
    for d in dirs:
        if tracked(d, root=root):
            run_git(["rm", "-r", d], root=root, dry=dry)
            removed += 1
        else:
            print(f"  {d} -> already removed, skipping")
    print(f"  {label}: staged {removed} path(s) for removal")


def drop_demo(root: Path, dry: bool) -> None:
    files = list(DEMO_FILES)
    for g in DEMO_GLOBS:
        files.extend(tracked(g, root=root))
    drop_paths(files, DEMO_DIRS, "demo pipeline", root=root, dry=dry)


def drop_code_reference(root: Path, dry: bool) -> None:
    drop_paths([], CODE_REFERENCE_DIRS, "code/reference guide", root=root, dry=dry)


def self_destruct(root: Path, dry: bool) -> None:
    drop_paths(DESTRUCT_FILES, [], "setup guides + init script", root=root, dry=dry)


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="init_project.py",
        description="Stamp a fresh template clone as a new project (section 1 of "
        "SETUP-NEW-PROJECT.md), with optional demo/scaffolding cleanup.",
        epilog="Leaves all changes uncommitted for review; prints the commit "
        "command when done. See SETUP-NEW-PROJECT.md for full rationale.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("slug", help="project slug, e.g. 'vantage' (lowercase, hyphens ok)")
    p.add_argument("--drop-demo", action="store_true", help="remove the demo pipeline: price/rent (fetch/build/analysis) + Solow model (section 4)")
    p.add_argument("--drop-code-reference", action="store_true", help="remove code/reference/, the house-style + skeletons guide (section 5)")
    p.add_argument(
        "--self-destruct",
        action="store_true",
        help="remove the setup guides and this script itself (section 7); runs last",
    )
    p.add_argument("--dry-run", action="store_true", help="print planned actions, change nothing")
    p.add_argument("--allow-dirty", action="store_true", help="proceed despite an uncommitted working tree")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    dry = args.dry_run
    root = Path(__file__).resolve().parent

    check_repo_root(root)
    ensure_git_repo(root)
    slug = validate_slug(args.slug)
    check_git_clean(root, allow_dirty=args.allow_dirty)

    state = detect_state(root)
    do_deletions = args.drop_demo or args.drop_code_reference or args.self_destruct

    if state == "already_stamped" and not do_deletions:
        print("Repo already initialized (no template-*.tex, env renamed); nothing to do.")
        return 0
    if state == "partial":
        print("warning: repo is partially stamped; each step is idempotent, continuing.")

    prefix = "[dry-run] " if dry else ""

    if state != "already_stamped":
        print(f"{prefix}Stamping project identity: {slug}")
        rename_docs(slug, root=root, dry=dry)
        fix_crossrefs(slug, root=root, dry=dry)
        stamp_environment_yml(slug, root=root, dry=dry)
        if not dry:
            verify_stamp(slug, root=root)
    else:
        print(f"{prefix}Identity already stamped; running requested deletions only.")

    if args.drop_demo:
        print(f"{prefix}Removing demo pipeline (section 4)")
        drop_demo(root, dry)
    if args.drop_code_reference:
        print(f"{prefix}Removing code/reference guide (section 5)")
        drop_code_reference(root, dry)
    if args.self_destruct:
        print(f"{prefix}Removing setup guides + init script (section 7)")
        self_destruct(root, dry)

    # Footer / next steps.
    print()
    if dry:
        print("[dry-run] no changes made. Re-run without --dry-run to apply.")
        return 0
    print("Done (nothing committed). Review:  git status  /  git diff --staged")
    print(f'Commit section 1:  git commit -m "Stamp {slug} identity"')
    if args.self_destruct:
        print("(the setup guides and init_project.py are staged for removal)")
    print("Next: SETUP-NEW-PROJECT.md section 2 (machine setup) and "
          "section 3 (re-voice README/CLAUDE opening).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
