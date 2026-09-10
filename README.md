# HeadstartAI

Shared GitHub Actions workflows for HeadstartAI

## Publishing a new version

Consumers reference these workflows by tag, e.g.:

```yaml
uses: HeadstartAI/workflows/.github/workflows/pr-review.yml@v1
```

- `v1.2.3` — immutable release tag, pinned to a specific commit.
- `v1` — moving major alias, points at the latest `v1.x.y` release.

To publish a new release, from a clean `main` branch run:

```bash
./scripts/release.sh 1.2.3
```

This tags `HEAD` as `v1.2.3`, pushes it, and prompts to force-update the
`v1` alias tag to point at the new release. Only update the alias once
you're confident the release is safe for all existing consumers pinned
to `v1`.
