# GitHub Action: Build module catalog

## Inputs

### `tagName`

**Required** The tag that will used for the module version

### `distDir`

**Required** The directory where the catalog should be output

### `publishBranch`

**Optional** The branch where the catalog should be published, Defaults to `gh-pages`

### `repoSlug`

**Deprecated** The git repo slug (owner/repo). This value is loaded from `env.GITHUB_REPOSITORY`

## Example usage

```yaml
uses: ibm-garage-cloud/action-module-catalog@main
with:
  tagName: ${{ github.event.release.tag_name }}
  distDir: ${{ env.DIST_DIR }}
  publishBranch: ${{ env.PUBLISH_BRANCH }}
```