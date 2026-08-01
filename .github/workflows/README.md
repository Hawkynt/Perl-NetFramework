# CI/CD Pipeline — Perl-NetFramework

> Everything in this folder is the automated pipeline for this repository.
> Workflows live here, their helper scripts live in `scripts/`.
> It follows the Hawkynt repository standard (non-.NET flavour).

## What this does

Three workflows, one shared build block, three helper scripts:

| File                            | Trigger                             | Purpose                                   |
|---------------------------------|-------------------------------------|-------------------------------------------|
| `ci.yml`                        | push + PR + `workflow_call`         | Syntax check + tiered tests + lint        |
| `release.yml`                   | **manual dispatch**                 | Package CPAN dist, then tag `vyyyyMMdd`   |
| `nightly.yml`                   | successful CI run on `main`         | Publish `nightly-yyyyMMdd` prerelease     |
| `_build.yml`                    | `workflow_call` (internal)          | Packages the CPAN distribution archives   |
| `scripts/version.pl`            | invoked by the workflows            | Stamp System.pm's `$VERSION` + build count|
| `scripts/update-changelog.mjs`  | invoked by the workflows            | Bucketise commits into CHANGELOG.md       |
| `scripts/prune-nightlies.mjs`   | invoked by the workflows            | 3-gen (GFS) retention of nightlies        |

## How it works

```
                push / PR
                    │
                    ▼
            ┌───────────────┐
            │    ci.yml     │──► tiered tests on ubuntu + windows
            └───┬───────┬───┘    (Perl 5.30 / 5.32 / 5.34 / 5.36) + lint
                │       │
   dispatch ────┤       │  on success on main
                ▼       ▼
        ┌──────────┐  ┌─────────────┐
        │ release  │  │  nightly    │
        │  .yml    │  │   .yml      │
        └────┬─────┘  └─────┬───────┘
             │              │
             ▼              ▼
        (both call _build.yml: CPAN dist .tar.gz + .zip)
             │              │
             ▼              ▼
  publish + tag vyyyyMMdd  nightly-yyyyMMdd (prerelease)
                                │
                                ▼
                       scripts/prune-nightlies.mjs
                       (GFS: 7 daily + 4 weekly + 3 monthly)
```

## Test tiers

| Tier                          | Runs on every PR? | Purpose                                     |
|-------------------------------|-------------------|---------------------------------------------|
| Build (syntax check)          | ✓ (must pass)     | `perl -c` on CSharp.pm, Filter, System.pm   |
| Test (core)                   | ✓ (must pass)     | C# filter tests + System type smoke tests   |
| Test (full suite, advisory)   | ✓ (allow-fail)    | Every test file, 120s timeout per file      |
| Test (methodology, advisory)  | ✓ (allow-fail)    | TestRunner.pl compile + coverage report     |
| Perl Lint                     | ✓ (allow-fail)    | Perl::Critic severity 4 + full syntax sweep |

Core tiers are **required**; the advisory tiers report known-red backlog files
(`continue-on-error: true`) without blocking a merge. As backlog files turn
green, promote them into the required tier.

## Why it's built this way

- **No cron triggers.** Event-driven only — CI fires on PRs, nightlies fire when CI passes on main, stable releases fire on manual dispatch.
- **Files drive versions, never tags.** `System.pm` keeps its own `$VERSION`; `version.pl --stamp` appends the commit count of its parent folder. There is no single repo version, so the repo-level Release/tag is the date marker `vyyyyMMdd`.
- **Release calls CI via `workflow_call`,** keeping tests and releases in lockstep with zero copy-paste.
- **Nightly builds from the `workflow_run` payload's SHA**, not branch tip — so a nightly is always a build of code CI actually validated.
- **`_build.yml` is the single packaging block**, shared by release and nightly so they never diverge.
- **3-generation (GFS) retention**, not "keep last N". GFS guarantees at least one build per week for a month and one per month for a quarter.

## Shared actions

This repo carries no pipeline scripts of its own. Versioning, changelog generation and nightly
pruning come from composite actions in
[`Hawkynt/RepositoryTemplate`](https://github.com/Hawkynt/RepositoryTemplate), so the single
canonical copy cannot drift between repos.

### `stamp-version`

The one versioner. Here it finds `System.pm`'s `$VERSION` and stamps it as `X.Y.BUILD`, where BUILD
is the number of commits touching the declaring file's folder.

```yaml
- uses: Hawkynt/RepositoryTemplate/stamp-version@v1     # rewrite the version in every manifest
- uses: Hawkynt/RepositoryTemplate/stamp-version@v1     # or compute without touching the tree:
  with:
    mode: print
```

It needs `actions/checkout` with `fetch-depth: 0`, since the build number is a commit count; a
shallow checkout fails the step rather than stamping everything with 1.

To bump the base version, edit `$VERSION` in `System.pm`; the build number follows the commit count
automatically. To run it by hand, clone the template and invoke `scripts/version.pl` from this
repo's working directory.

### `update-changelog.mjs`

Prepends a new section to `CHANGELOG.md`. Commit-subject convention: `+` Added, `*` Changed, `#` Fixed, `-` Removed, `!` TODO, anything else → Other.

### `prune-nightlies.mjs`

GFS retention with `DAILY_KEEP=7`, `WEEKLY_KEEP=4`, `MONTHLY_KEEP=3`. Dry-run with `--dry-run`.

## Release artifacts

| Artifact                                      | Produced by          |
|-----------------------------------------------|----------------------|
| `Perl-NetFramework-<version>.tar.gz` (CPAN)   | release + nightly    |
| `Perl-NetFramework-<version>.zip`             | release + nightly    |
