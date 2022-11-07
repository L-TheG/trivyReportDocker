# Generate and run local Hugo server

**Prerequisite:** 
- A [Trivy](https://aquasecurity.github.io/trivy/v0.34/docs/) report has to be in this folder.
- The report should be generated with the ```trivy k8s``` ([reference](https://aquasecurity.github.io/trivy/v0.34/docs/kubernetes/cli/scanning/)) command
  - Example command to generate ```trivy k8s --kubeconfig <path/to/kubeconfig> --format json -o report.json cluster```
- the report must be in json format has to be named ```report.json```.

**Usage**
run ```docker-compose up --build``` from this directory to start the service.

After a while, you should be able to look at the report on localhost:1313

If you want to use a new report, you should run ```docker-compose rm``` and remove the previous docker trivy report container.
