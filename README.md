# gloss Site & Project Map (`site` branch)

This orphan branch isolates the web frontend and architecture-map tooling from the `main` R package core:

- **Portal Home & 3D Architecture Space** (`src/`, `index.html`, `3d/index.html`): React + Vite + Tailwind + Three.js interactive showcase.
- **LikeC4 Project Map & Live Probe** (`project-map/`): C4 architecture model (`project-map/model/`) and live alignment probe (`project-map/build_map.R`) that scans `main`.

## Branch Architecture

| Branch | Role |
| :--- | :--- |
| `main` | Clean R package source (`R/`, `man/`, `tests/`, `vignettes/`, `skills/`, `dev_docs/`). |
| `site` | Portal frontend source + LikeC4 architecture map & alignment probe (this branch). |
| `gh-pages` | Auto-generated static GitHub Pages bundle (never edited by hand). |

## Local Development

```bash
# Portal + 3D space dev server
npm ci
npm run dev

# Type check, unit test, and production build
npm run lint
npm test
npm run build

# Refresh LikeC4 status against a local checkout of `main`
Rscript project-map/build_map.R --repo-dir /path/to/gloss-main --run-tests
npx --yes likec4@latest start project-map/model
```
