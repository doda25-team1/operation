# Continuous Experimentation: A/B Testing Strategy

## Hypothesis
We hypothesize that modifying the Call-To-Action (CTA) on the SMS Checker landing page (v2) will act as a stronger cue for users, leading to a higher engagement rate compared to the original design (v1). Specifically, we expect a **5% increase in prediction requests** from users exposed to the v2 variant.

## Metrics
To validate this hypothesis, we will monitor the following Prometheus metrics exported by our application:

1.  **Primary Metric (Engagement):** `sms_app_requests_total{status="200"}`
    -   We compare the rate of successful prediction requests between `variant="v1"` and `variant="v2"`.
    -   Since traffic is split 90/10, we normalize the v2 count by multiplying by 9 to compare against v1, or look at the ratio of `predictions / page_views` (if page views were tracked separately). For this experiment, we look for a significant proportional increase in v2 usage.

2.  **Guardrail Metric (Performance):** `app_http_request_duration_seconds`
    -   We must ensure that the v2 changes do not introduce any latency regression.
    -   We monitor the 99th percentile latency (`histogram_quantile(0.99, rate(...))`) to ensure it remains steady.

## Decision Process
The experiment will run for a fixed duration (e.g., 1 hour or 1000 requests).

1.  **Analyze Results:**
    -   Compare the normalized prediction volume of v2 vs v1.
    -   Check latency graphs for anomalies.
2.  **Decision Criteria:**
    -   **PASS:** If v2 shows a statistically significant increase in predictions (> 5%) AND latency is largely unchanged (within 5% margin). -> **Promote v2 to Stable**.
    -   **FAIL:** If v2 shows no improvement, fewer predictions, or higher latency. -> **Rollback to v1**.

![A/B Testing Traffic Flow](./images/experiment.png)