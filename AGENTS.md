# Agent guide — Perl-NetFramework

Working agreement for **all** coding agents and human contributors working in
this repository. These rules are not optional. The full house spec lives in
the `Hawkynt/project-template` repo (`STANDARD.md`); this file is the
per-repo distillation.

## What this is

A **pure-Perl clone of the .NET BCL**: `System.pm` + the `System/` namespace
tree mirror the .NET type hierarchy, `CSharp.pm` provides the C#-flavoured
sugar (filters under `Filter/`). Tests live under `tests/` and run via
`tests/TestRunner.pl`.

## Commits

- **Group changes semantically/logically** — one type/namespace concern per
  commit.
- **Every subject line starts with a prefix**: `+` added · `-` removed ·
  `*` changed · `#` bug fixed · `!` critical todo.
- Never start a subject with "fix"/"bugfix"/"changed"/"modified".
- **No AI traces anywhere**: no `Co-Authored-By` AI lines, no "Generated
  with" footers, no agent mentions in messages, comments, or authorship.

## The loop (always, in this order)

1. **Before committing**: `perl -I. -c` every touched module and run the
   suite (`perl tests/TestRunner.pl`) until green — mind that behavior must
   hold on **threaded and non-threaded** perls (the thread tests branch on
   real availability; keep it that way). Update the README's structure/usage
   sections when the public surface changes; `CHANGELOG.md` is generated —
   never edit it by hand.
2. **Commit** (rules above) and **push**.
3. **Wait for CI**; on `main` a green CI triggers the nightly (prerelease +
   GFS prune). Fix and loop until everything is green.

Stable releases are **manual** (`gh workflow run release.yml`) — never cut
one unless explicitly asked.

## Code conventions

- `use strict; use warnings;` everywhere; `$VERSION` declarations are
  stamped by `version.pl` — keep them present and parseable.
- Mirror .NET naming for the public surface (PascalCase packages/methods),
  Perl conventions for internals; guard clauses over deep nesting.
- New types follow the existing folder-per-namespace layout
  (`System/Collections/…`), one package per file, kept in `MANIFEST`.
- Exceptions are objects usable from plain `eval` — preserve the documented
  interop contract (short-name aliasing, C#-style string operators).

## README & repo conventions

- Standard frame: title → badges → one-line `>` blockquote (no `## Overview`
  header — the blockquote is the intro); fixed emoji mapping for the
  standard sections (`## ✨ Features`, `## 🚀 Usage Examples`,
  `## 📦 Installation and Dependencies`, `## 🛠️ Development and Testing`,
  `## ❤️ Support`, `## 📜 License`).
- License is LGPL-3.0-or-later; the `## ❤️ Support` section and
  `.github/FUNDING.yml` stay intact.
