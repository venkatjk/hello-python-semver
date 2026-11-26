# hello-python-semver

A hello-world Python app that shows automatic semantic versioning in GitHub Actions.
It follows the same idea as the Jenkins `ppc.Jenkinsfile` setup, with two differences:
the bump type comes from commit messages, and the CHANGELOG is enforced.

## Run it

```bash
python hello.py            # Hello, World!
python hello.py Ada        # Hello, Ada!
```

## How versioning works

| Step | Rule |
|---|---|
| Current version | Highest `vX.Y.Z` tag, or `0.0.0` if none exists |
| Bump | `BREAKING CHANGE:` footer or `type!:` prefix → major; `feat:` → minor; anything else → patch |
| Changelog check | `CHANGELOG.md` must contain `## [X.Y.Z] - YYYY-MM-DD` for the calculated version, with at least one bullet |
| Tag | Annotated tag `vX.Y.Z` on the commit that was merged to `main` |

Use [Conventional Commits](https://www.conventionalcommits.org/) messages, for example `feat: add farewell command`.

### Pipeline

| Event | Job | Result |
|---|---|---|
| Pull request to `main` | Changelog dry run | Fails if the changelog does not match the calculated version |
| Push to `main` | Release | Creates and pushes the tag only if the changelog matches |
| Changelog mismatch on `main` | Release | Fails before any tag is created |

## Releasing a change

1. Make your change on a branch and add the commit messages you want (`feat:`, `fix:`, or `feat!:`).
2. Add a changelog entry with the version the pipeline will calculate. Run the script locally to see it:
   ```bash
   bash scripts/release.sh --dry-run
   ```
   The error message names the expected heading, for example `## [0.1.1] - 2026-11-30`.
3. Open a pull request. The `Check version and changelog` job must pass.
4. Merge into `main`. The release job creates the tag, for example `v0.1.1`.

## Files

| File | Purpose |
|---|---|
| `hello.py` | The application |
| `CHANGELOG.md` | Release notes, one dated section per version |
| `scripts/release.sh` | Calculates the version, checks the changelog, creates and pushes the tag |
| `.github/workflows/ci-release.yml` | The GitHub Actions workflow |


## Repository settings to check

- **Branch protection on `main`**: require the `Check version and changelog` status check before merging.
- **Tag protection**: if you add a tag ruleset, allow `github-actions[bot]` to create `v*` tags, or the release job cannot push.
- The workflow sets `contents: write` for the release job only, so the repository's default token permissions do not need changing.
