### Week Q2.1 (Nov 13+)

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


### Week Q2.2 (Nov 21+)
- Deon: https://github.com/doda25-team1/operation/pull/7
I worked on the steps 4 to 7 of A2. I implemented secure SSH key-based access to all VMs by registering multiple team public keys using Ansible. Then disabled SWAP both immediately and permanently, ensuring Kubernetes compatibility by stopping active swap and removing it from /etc/fstab. Finally, configured Kubernetes networking at the kernel level by loading br_netfilter and overlay modules and enabling required sysctl parameters for IP forwarding and bridged traffic. Made some fixes to run initial vagrant setup