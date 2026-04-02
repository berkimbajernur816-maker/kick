# Privacy Policy

*Updated: April 2, 2026*

KiCk runs locally on your device by default. The app does not operate its own servers to process your prompts or responses.

## What Is Stored Locally
All data stays on your device:
* **Settings:** theme, ports, limits, custom model IDs, and analytics consent.
* **Account data:** email, `PROJECT_ID`, Kiro session parameters, and limit statuses.
* **Authentication:** Google OAuth tokens, locally stored Kiro Builder ID data, and your local KiCk API key.
* **Logs:** stored locally for debugging. Full raw prompt logging is **disabled** by default. Sensitive data is masked when logs are exported.

## Network Connections
The app connects only to:
* Google servers, for OAuth sign-in and Gemini CLI requests.
* AWS and Kiro services, for AWS Builder ID sign-in, Kiro session refresh, and Kiro requests.
* The local host at `127.0.0.1`.
* Aptabase servers, **only** if you explicitly enable anonymous analytics.
* GlitchTip or another Sentry-compatible endpoint, if that diagnostics option is enabled in a specific build.

## Analytics (Strictly Optional)
Data collection is **disabled** by default. If you enable it, KiCk sends only basic metrics such as app launches, proxy errors, and account connection success.

**Never collected:** prompt or response text, API keys, tokens, email addresses, `PROJECT_ID`, or raw logs.

## Access Modes
By default, the proxy listens only on `127.0.0.1`. If you enable `Allow LAN` (binding to `0.0.0.0`) or disable `Require API key`, you take responsibility for the security of your local network.

**Contact:** For privacy questions, open a regular issue in the repository.
