Versioning & tag policy

But: this repository uses semantic-ish tags for releases and a commit-based tag for images.

Tag formats

- Release tags: vMAJOR.MINOR.PATCH (example: v1.0.0)
  - Created when you want a new deployable release.
  - CI will build and publish an image using the release tag.

- Commit-derived image tag: sha-<short-sha> (example: sha-abc123)
  - Always built for the commit that triggered the action.
  - Useful for reproducing a deploy from a specific commit.

How images are named

- Registry used in workflow: GitHub Container Registry (ghcr.io)
- Image naming convention: ghcr.io/OWNER/REPO:TAG
  - Example: ghcr.io/myorg/myapp:v1.2.3
  - Example: ghcr.io/myorg/myapp:sha-abc123

Release flow (recommended)

1. Develop on feature branches, open PRs to `main` (CI runs checks).
2. Merge to `main` when green.
3. Create an annotated tag on `main`, e.g.:

   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0

4. The GitHub Actions workflow triggers on the tag, builds images, and pushes to ghcr.io.

Registry credentials / permissions

- The workflow uses `secrets.GITHUB_TOKEN` to authenticate to GHCR. Ensure repository permissions allow `packages: write` for the workflow (configured in the workflow header).
- If you prefer Docker Hub, update the workflow and use `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets.

Rollback

- To rollback, deploy the previous tagged image (by release tag or commit tag).

Notes

- Keep tags immutable and use annotated tags for releases.
- Consider storing a small CHANGELOG file referencing release tags.
