### Week Q2.2 (Nov 13-23)

- Deon: https://github.com/doda25-team1/app/pull/3, https://github.com/doda25-team1/model-service/pull/3
I worked on the F8 task of A1, implementing automated versioning and GitHub workflows for both the app and backend. I explored ways to extract versions directly from pom.xml and pyproject.toml, and set up automated image building and pushing. I also added a mechanism to automatically bump the version after each successful workflow run.

- Nicolas: https://github.com/doda25-team1/model-service/pull/1
I worked on creating the docker file, upgraded it to contain 2 stages, created PORT as an enviromental variable and allowed for multi-arhitecture compatibility. Therefore satisfying F3,F4 (for the model-service) and F5,F6.

- Daniel: https://github.com/doda25-team1/app/pull/1, https://github.com/doda25-team1/lib-version/pull/7
I made the Dockerfile for the app service, integrated the lib-version library, and made small adjustments to workflows, other configuration, and docs.

- Alex: https://github.com/doda25-team1/model-service/pull/2, https://github.com/doda25-team1/app/pull/2, https://github.com/doda25-team1/operation/pull/1
I made the Dockefile compose and made sure the PORT numbers for both services are configurable and overwritten by compose.

- Ion: https://github.com/doda25-team1/model-service/pull/4, https://github.com/doda25-team1/model-service/pull/7, https://github.com/doda25-team1/operation/pull/3
I worked on creting a manually-triggered workflow for training and releasing a new model (F9 and F10). The model version is passed as a virtual environment MODEL_VERSION. If no model found on the mounted volume, it will be downloaded from the corresponding release.

- Noah: https://github.com/doda25-team1/lib-version/pull/1, https://github.com/doda25-team1/lib-version/pull/2. 
I worked on creating the intial lib-version setup, and worked on feature branch versioning for this too.

### Week Q2.3 (Nov 24-30)

- Deon: https://github.com/doda25-team1/operation/pull/7
I worked on the steps 4 to 7 of A2. I implemented secure SSH key-based access to all VMs by registering multiple team public keys using Ansible. Then disabled SWAP both immediately and permanently, ensuring Kubernetes compatibility by stopping active swap and removing it from /etc/fstab. Finally, configured Kubernetes networking at the kernel level by loading br_netfilter and overlay modules and enabling required sysctl parameters for IP forwarding and bridged traffic. Made some fixes to run initial vagrant setup

- Daniel: https://github.com/doda25-team1/operation/pull/10
I was responsible for steps 18, 19, and 20. I made a small addition to the node.yml so that worker nodes can get the command they need to run to join the cluster, and I also created the finalization.yml playbook, which configures the MetalLB loadbalancer on the controller node. I also added my public key to the repo.

- Ion: https://github.com/doda25-team1/operation/pull/9
I worked on setting up kubernetes on the controller VM and making sure the .kube config file is accessible on both the ctrl and the host machine.

- Alex: I don't have the PR. See commits below. I worked on the Step 1-3 and Step 8, defined the Vagrant file. Set up the Ansible provisioner in it and managed etc/hosts dynamically via Jinja.
Step 1&2: https://github.com/doda25-team1/operation/commit/1dbde8d6d031568011c642070f44b4d838d8598a
Step 3: https://github.com/doda25-team1/operation/commit/5eb4e59f25b4087bd21a6624ea2de46106c5df63
Step 8: https://github.com/doda25-team1/operation/commit/ed5fe512027dd012ec72b63b5ec9d65125df193c

- Noah: I worked on steps 21-23 of A2, and was trying to test the vagrant setup, but this was tough using WSL.

- Nicolas: https://github.com/doda25-team1/operation/pull/8
    Steps 8-11. I worked on implementing the Kubernetes cluster setup using the Ansible playbooks. Configured the containerd as the container runtime and starting kublet.

### Week Q2.4 (Dec 1-7)

- Alex: https://github.com/doda25-team1/operation/pull/11
Worked on deployment and service manifests, created ingress, and implemented values.yaml to allow changing hostnames and URLs.

- Noah: https://github.com/doda25-team1/operation/pull/12
I worked on finalising the last few steps i was working on from last week. I was not able to start with A3 as I was tasked to finalise that task too.

- Ion: https://github.com/doda25-team1/operation/pull/15 (fixed some files written by Noah), https://github.com/doda25-team1/operation/pull/16 (fixed some files written by Deon and added new ones), https://github.com/doda25-team1/app/pull/9 (app metrics)
I worked on fixing some of the files from a2 and for a3. Mostly I focuesd on providing metrics for the app. Implemented Counter, Gauge, and Histogram metrics for captured requests.

- Deon https://github.com/doda25-team1/operation/pull/16. Worked on the implementation for deployment and configuration of model service but couldnt test it properly last week due to laptop issues. Tested the changes this week.

- Daniel: no work. (compensated using week 2)

- Nicolas: https://github.com/doda25-team1/operation/pull/13
    Steps 19-20. I worked on installing the Ingress Controller and Kubernetes Dashboard, configured LoadBalancer in finalization.yml

### Week Q2.5 (Dec 8-14)
- Alex: https://github.com/doda25-team1/operation/pull/20 Setup the ingress gateway, parametrized ingress name, and configured service port.

- Daniel: https://github.com/doda25-team1/operation/pull/19 I added the configuration for Prometheus such that it monitors the app service and it scrapes for metrics. Additionally, I set the alert manager.

- Deon: https://github.com/doda25-team1/operation/pull/18 -> Implemented ServiceMonitor for monitoring deployments. 
https://github.com/doda25-team1/operation/pull/21 -> Added changes for shared volume to persist changes for all pods.
Additionally, tested end to end till prometheus montoring on minikube cluster

### Week Q2.6 (Dec 15–21)

### Week Q2.7 (Jan 5–11)

### Week Q2.8 (Jan 12–18)

### Week Q2.9 (Jan 19–25)

### Week Q2.10 (Jan 26–27) (final submission!)
