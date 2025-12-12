# Continuous Experimentation: CTA Emphasis A/B Test

## What Changed (v2 vs v1)
- **UI only**: The submit button is now a primary call-to-action labeled “Analyze Now” with a highlighted style and a small experiment banner (v2). The control (v1) keeps the original gray “Send” button and no banner.
- **No backend/model change**: Same prediction logic and latency profile; only the CTA styling/text differs.
- **Variant flag**: `APP_VERSION` (default `v1`) is injected via Helm and rendered into the template. V2 pods set `APP_VERSION=v2`.

## Hypothesis (Falsifiable)
> Making the CTA more prominent (text + styling) increases prediction requests by **at least 20%** without increasing latency.

## Metrics (Prometheus)
- `sms_app_requests_total{variant, status}` — counter incremented on `/sms/predict`.
- `app_http_requests_total{endpoint, status, variant}` — existing per-endpoint counter, now labeled by variant.
- `app_http_request_duration_seconds_{bucket,sum,count}{variant}` — latency histogram labeled by variant.
- `app_active_requests{variant}` — gauge for in-flight requests.

## Decision Process
1. Compare `rate(sms_app_requests_total{variant="v2"}[1m])` vs `...{variant="v1"}`.  
   - **Pass** if v2 ≥ 1.2 × v1 over a stable window and sample size ≥ 30 requests per variant.
2. Check latency: `histogram_quantile(0.95, rate(app_http_request_duration_seconds_bucket{variant="v2"}[5m]))` should stay within the same range as v1 (no regression).
3. If both hold, promote v2; otherwise keep v1 CTA.
