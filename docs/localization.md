# Localization

## Overview

- Source locale: `en`
- Source ARB file: `lib/l10n/app_en.arb`
- Translation files: `lib/l10n/app_<locale>.arb`
- Generated Flutter localizations: `lib/l10n/generated/`

English is the canonical source locale for Flutter `gen_l10n` and for external translation platforms.

## Local workflow

1. Add or update strings in `lib/l10n/app_en.arb`.
2. Update existing translations, for example `lib/l10n/app_ru.arb`.
3. Run:

```powershell
flutter gen-l10n
```

4. Commit the updated ARB files together with `lib/l10n/generated/`.

## Self-hosted Weblate setup

These settings match this repository structure and are used by the self-hosted Weblate instance at `https://weblate.nikz.lol`.

### Repository access

Self-hosted Weblate can use a dedicated GitHub bot account or a repository deploy key with write access. Configure the Weblate SSH public key in GitHub and add the `github.com` host key in the Weblate admin UI.

Recommended repository settings:

- Source code repository: `git@github.com:mxnix/kick.git`
- Repository push URL: `git@github.com:mxnix/kick.git`
- Version control system: `GitHub pull requests`
- Push branch: `l10n/weblate-translations`
- Repository branch: `main`

If you leave `Push branch` empty, Weblate will push from a fork instead of the upstream branch.

### Component settings

Create a single component for the Flutter app strings with the following values:

- File mask: `lib/l10n/app_*.arb`
- Monolingual base language file: `lib/l10n/app_en.arb`
- Template for new translations: *leave empty*
- File format: `ARB file`

Suggested language setup:

- Source language: English
- Initial target language: Russian, ...

### GitHub automation in this repository

This repository includes `.github/workflows/sync-generated-localizations.yml`.

When Weblate updates any `lib/l10n/*.arb` file in a branch, this workflow runs `flutter gen-l10n` and commits the refreshed generated files back to the same branch. That allows Weblate pull requests to merge cleanly even though Flutter localization outputs are committed to the repository.

`CI` also checks that generated localization files are up to date.
