# eigs-package-template

Starting point for an [EigenScript](https://github.com/InauguralSystems/EigenScript)
package. Fork or clone, rename, push, tag — and the package is consumable
by anyone with `eigenscript --pkg add`.

## Layout

```
.
├── eigs.json          # manifest: name, version, deps
├── mypkg.eigs         # entry point — must match eigs.json's `name`
├── tests/
│   └── test_smoke.sh  # consumer-shaped integration test
└── .github/workflows/test.yml
```

Two rules the package tool relies on:

1. The file at the repo root named `<leaf>.eigs` is the entry point.
   Its top-level bindings become the importable surface.
2. By convention `eigs.json`'s `name` field equals the entry-point
   filename without `.eigs` — call it the *leaf*. A consumer adds the
   package as `--pkg add <owner>/<leaf> <url>`, and the resolver
   looks for `eigs_modules/<leaf>/<leaf>.eigs`. If the repo's
   entry-point filename doesn't match the `<leaf>` portion of the
   consumer's `--pkg add` invocation, `import <leaf>` fails at
   runtime. Keep them aligned.

Names defined with a leading underscore (`_helper`) stay private — they
are visible inside the module file but not to importers.

## Rename for your package

1. Pick a name. EigenScript package names are lowercase, no hyphens
   (an importer writes `import mypkg`, and identifiers can't contain
   `-`). Underscores are fine; keep names short.
2. Rename `mypkg.eigs` to `<your-name>.eigs`.
3. Edit `eigs.json` — set `name` to match.
4. Update this README and the entry point's banner comment.

## Develop locally

```sh
# parse + run the entry point in isolation
eigenscript mypkg.eigs

# the smoke test stages the package into a tmpdir under
# eigs_modules/<name>/ and imports it the way a consumer would
bash tests/test_smoke.sh
```

CI builds EigenScript from source on Linux and runs `tests/test_smoke.sh`
on every push and PR. See `.github/workflows/test.yml`.

## Publish

A "publish" is a git tag in this repo. Consumers pin against tags:

```sh
git tag v0.1.0
git push --tags
```

Follow [semver](https://semver.org/):

- **patch** (`v0.1.1`) — bugfixes, no surface change
- **minor** (`v0.2.0`) — added surface, nothing removed or repurposed
- **major** (`v1.0.0`) — removed or repurposed surface

Lockfiles pin a commit SHA, so a force-pushed tag won't sneak a
different tree past a consumer who has already run `--pkg install` —
but it *will* break `--pkg add` for new consumers. Prefer cutting
a new tag over moving an existing one.

## Consume

Once pushed and tagged:

```sh
eigenscript --pkg add you/mypkg https://github.com/you/eigs-mypkg v0.1.0
```

Package identifiers must be `<owner>/<name>` — the tool rejects bare
names like `mypkg`. The on-disk dir and the `import` form still use
the leaf only, so this clones into `eigs_modules/mypkg/`, records the
resolved commit (under the key `"you/mypkg"`) in `eigs.lock.json`,
and lets the consumer's code do:

```eigenscript
import mypkg
print of mypkg.greet of "world"
```

## License

MIT — see [LICENSE](LICENSE). Drop in your own when you fork.
