# Shipping a release (3.0.0 and onward)

Local Xcode is a beta, so releases build on GitHub Actions
([.github/workflows/release.yml](../.github/workflows/release.yml)) and upload
straight to App Store Connect with cloud signing — no certificates on this machine.

## One-time setup (needs the account holder — ~3 minutes)

1. In [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api),
   generate a **Team Key** with the **App Manager** role. Note the **Key ID** and
   **Issuer ID**, and download the `AuthKey_XXXXXXXXXX.p8` file (only downloadable once).
2. Add the three repo secrets from a terminal:

   ```sh
   gh secret set ASC_KEY_ID    --body "XXXXXXXXXX"
   gh secret set ASC_ISSUER_ID --body "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   gh secret set ASC_KEY_P8    < ~/Downloads/AuthKey_XXXXXXXXXX.p8
   ```

That's it. Cloud signing (`-allowProvisioningUpdates`) manages the distribution
certificate, registers the widget bundle ID (`rojo.happy-places-moments.HappyPlacesWidgets`),
and attaches the App Group capability automatically.

## Each release

1. Bump `MARKETING_VERSION` in project.pbxproj (all app + widget configs must match).
2. Merge to `main`, then either:
   - `git tag v3.0.0 && git push origin v3.0.0`, or
   - `gh workflow run "Release to App Store"`.
3. The build number is the workflow run number — every run uploads a fresh build.
4. In App Store Connect: create the version, paste `whats-new-3.0.0.txt`, upload
   the screenshots from `AppStore/screenshots/`, pick the build once it finishes
   processing, and submit. `review-notes.txt` has the App Review notes.

## Release checklist reminders (from CLAUDE.md)

- CloudKit: any new record type must be promoted Development → Production
  **before** release (currently pending: `CD_PlacePhoto`).
- First widget release: verify the App Group shows up on both App IDs in the
  developer portal after the first CI build.
