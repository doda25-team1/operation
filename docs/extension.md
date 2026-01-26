# Extension Proposal: Chaos Engineering using Chaos Mesh

## 1. The Problem

Our current testing strategy is limited to standard unit tests and basic integration checks (e.g., "Does the endpoint return 200 OK?"). We implicitly trust that our complex Istio Service Mesh configuration such as retries, circuit breakers, and failovers will protect us during a real-world outage. Therefore it is clear that we suffer from **Resilience Uncertainty**. We have configured Istio features like `retries` and `outlierDetection`, but we never verify them. This leads to a series of potential uncertainties:

*   *What happens if the `model-service` starts taking 5 seconds to respond?*
*   *What happens if a random pod crashes during a high-traffic event?*

Currently, we would only find out in production, which is too late. Our release pipeline does not validate the **robustness** of the release, only its **functionality**.

## 2. The Solution: Automated Chaos Engineering

We propose integrating **Chaos Mesh** into our Continuous Integration (CI) pipeline. **Chaos Mesh** is a cloud platform created and optimised for **Kubernetes** which has become and industry standard for testing infrastructures similar to our own. **Chaos Mesh** will insert certain controlled faults such:

* *Artificial Latency*
* *Random Pod Termination*

This artifical noise will actually force the **Istio** failsafes to trigger and test the overall robustness of the network.

## 3. Implementation Plan

1.  **Infrastructure Setup:**
    *   Install **Chaos Mesh** (a CNCF project) into the Kubernetes cluster using Helm.
    *   Configure permissions to allow the Chaos Controller to inject faults into the `doda` namespace.

2.  **Define Experiments:**
    *   Create `NetworkChaos` resources to simulate **High Latency** (e.g., inject 2000ms delay on 50% of packets to `model-service`).
    *   Create `PodChaos` resources to simulate **Pod Failure** (randomly kill 1 replica of `app-service` every 60 seconds).

3.  **Pipeline Integration:**
    *   Modify the GitHub Actions workflow. After the "Deploy to Staging" step, add a new job: `chaos-test`.
    *   **Workflow Logic:**
        1.  Apply `NetworkChaos` YAML.
        2.  Run the standard `load-test` script (using `k6` or `curl`).
        3.  Wait 2 minutes.
        4.  Delete Chaos resources.

4.  **Assertion:**
    *   The pipeline passes ONLY if the load test success rate remains **> 99%** (proving Istio retries masked the failures).

## 4. Expected Outcome & Measurement

**Improvement:**
*   **Proven Resilience:** We move from *hoping* Istio works to *proving* it works.
*   **Regression Prevention:** If a developer accidentally removes a retry policy from `values.yaml`, the connection to `model-service` will fail during the chaos test, and the pipeline will block the bad release.

**Measurement (Experiment Design):**
To measure the effectiveness of this extension, we perform a **Comparative Availability Test**:
1.  **Baseline (No Chaos):** Run load test. Success Rate: 100%.
2.  **Experiment A (Chaos + No Istio):** Disable Istio retries. Inject 50% packet loss. Success Rate should drop to ~50%. **(FAIL)**
3.  **Experiment B (Chaos + Istio):** Enable Istio retries. Inject 50% packet loss. Success Rate should remain near 100%. **(PASS)**

*The automated pipeline ensures we are always in the state of Experiment B.*

## 5. References & Inspiration

1.  **Tooling:** *Chaos Mesh - A Powerful Chaos Engineering Platform for Kubernetes*
    *   Source: [Chaos Mesh Documentation](https://chaos-mesh.org/)
2.  **Methodology:** *Principles of Chaos Engineering*
    *   Source: [PrinciplesOfChaos.org](https://principlesofchaos.org/)
3.  **Concept:** *Chaos engineering (Google Cloud Blog)*
    *   Source: [Google Cloud - Getting Started with Chaos Engineering](https://cloud.google.com/blog/products/devops-sre/getting-started-with-chaos-engineering)
