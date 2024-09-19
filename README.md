# code-cicd-demo

__Panoptica CI/CD CLI Demos for Code Security__

There are several categories of demos documented in this repo:

- Container Image Scanning via CLI: Both [remote repo](./README.md#container-image-demos) and [local image](./README.md#local-container-build-and-scan-example)
- [IaC Scanning via CLI](./README.md#iac-scanning-demos)
- [Secret Scanning via CLI](./README.md#secret-scanning-demos)
- [GitHub Pull Request scanning](./README.md#github-pull-request-scanning-example)

## Container Image Demos

See [pre-requisites](./README.md#pre-requisites) for the required software and setup required to perform these demos.

Scanning an image or a local file/directory does NOT require API access to Panoptica. Referencing policies or reporting job results DOES require API key and access to Panoptica.

The series of commands starts at minimal and progress to increasing capabilities.  To ensure everything is properly prepared before you begin, run the following command (after all the setup):

```bash
source demo-setup.sh
```

You should see a single line response: **Panoptica CI/CD CLI Setup Successful**

### Basic Scanning

Grab any container image and scan it for CVE vulnerabilities.

```
${CICD_COMMAND} image nginx:latest
```

Example output of this command is here: [outputs/nginx-latest.image.txt](./outputs/nginx-latest.image.txt)

### Basic Scanning a Local Image with User Block Policy

Get local container, scan it, and - if any vulnerability possess a severity of critical - exit the scanner CLI with an error status.

```
${CICD_COMMAND} image nginx:latest --local --exit-on-severity critical
```

Example output of this command is here: [outputs/nginx-latest.local-severity.txt](./outputs/nginx-latest.local-severity.txt)

### Scanning Using a Panoptica Policy (API key required)

```bash
${CICD_COMMAND} image nginx:latest --policies "Demo - Vulnerable Package Detection"
```

Example output of this command is here: [outputs/nginx-latest.policy.txt](./outputs/nginx-latest.policy.txt)

### Scanning Using a Panoptica Policy, Reporting Result to UI (API key required)

```bash
${CICD_COMMAND} image nginx:latest --policies "Demo - Vulnerable Package Detection" --report
```

Example output of this command is here: [outputs/nginx-latest.report.txt](./outputs/nginx-latest.report.txt)

More importantly, the results now show up in the Panoptica UI. These results can be found in the [Panoptica CI/CD Scans](https://console.panoptica.app/scan-reports/metadata) view.

The overview page with the list of jobs reported to the UI:

![CI/CD Scans Overview Page](./images/CY24Q3-demo-cicd-scans-overview.png)

Clicking on the specific scan job will present the detailed findings:

![CI/CD Scans Container Image Details](./images/CY24Q3-demo-cicd-scans-details.png)

To see the related policy that the image was evaluated against, navigate to the [Policies](https://console.panoptica.app/global-policies/) menu and select the "CI/CD" tab.  Selecting the [Demo - Vulnerable Package Detection](https://console.panoptica.app/global-policies/rule/1be9b0c1-e8b2-4dee-8bb8-5ecf3a487e9d) policy will show the rule logic details:

![CI/CD Policy Vulnerable Package Detection](./images/CY24Q3-demo-policy-cicd-image.png)

## IaC Scanning Demos

Now that you're seasoned in the demos, we'll be a bit more brief going forward. Each example will generate a text output and report the results to the Panoptica UI. As a result, you'll need to have the API KEY variable defined.

The IaC scans identify a range of issues from typical infrastructure as code (IaC) text files, ranging from Terraform, Helm, Kubernetes YAML, and Dockerfiles. The scans are conducted on a local filesystem (whether in CI/CD pipeline runner or local laptop).

In this demo, the [Damn Vulnerable Web Application](https://github.com/digininja/DVWA.git) has been cloned and connected as a git submodule in [vuln-web-app](./vuln-web-app/).  We'll scan it without policy first, then with policy second.

```bash
${CICD_COMMAND} iac vuln-web-app --report > outputs/dvwa.iac.default.txt
${CICD_COMMAND} iac vuln-web-app --report --policies "Demo - Block IaC Critical Misconfigurations" > outputs/dvwa.iac.policy.txt
```

## Secret Scanning Demos

Secret detection walks through the provided filesystem and searches for a wide variety of secrets (PEM files, embedded tokens, etc.) that may have been inadvertently left in the filesystem or hardcoded into the files. Like IaC, the local filesystem is scanned and we'll continue to use the DWVA [vuln-web-app](./vuln-web-app/) git submodule:

```bash
${CICD_COMMAND} secrets vuln-web-app --report > outputs/dvwa.secrets.default.txt
# ${CICD_COMMAND} secrets vuln-web-app --report --policies "Demo - Block Detected Secrets" > outputs/dvwa.secrets.policies.txt
```

(Note: Secret policies are not yet supported)

## Local Container Build and Scan Example

For demo purposes - and for the love of all that is holy, don't run/deploy this container you are about to build - we can build the vulnerable app into a container and scan it to showcase a typical CI workflow:

```bash
cd vuln-web-app
docker build -t local/dvwa:20240918 . > ../outputs/dvwa.docker-build.txt
cd ..

${CICD_COMMAND} image local/dvwa:20240918 --local --report > outputs/dvwa.image.txt
```

## YAML Configuration for Scan Jobs

For comprehensive scanning governance, many policies tend to be applied to prevent the maximum amount of risk that is acceptible. As you have seen, itemizing all those policy definitions can become overwhelming. To support these more sophisticated security needs, the Panoptica CI/CD scanner supports the use of a YAML file to configure the CLI operations. You can refer to the [CI/CD CLI Tool](https://docs.panoptica.app/docs/cicd-cli-tool) documentation for all the details.

A couple of examples are provided in this repo:

- [IaC Scanning Example](./configs/config-iac.yaml)
- [Image Scanning Example](./configs/config-images.yaml)
- [Secrets Detection Example](./configs/config-secrets.yaml)

An example command to leverage the YAML configuration for scanning images:

```bash
${CICD_COMMAND} images nginx:latest --config configs/config-images.yaml
```

## GitHub Pull Request Scanning Example

This "demo" is already set up for you and all you have to do is look at the behavior. The generated [pull request](https://github.com/eti-tme-org/vuln-web-app/pull/2) is based on the following actions in the [vulnerable app](./vuln-web-app/) git submodule:

```bash
cd vuln-web-app
git checkout --track origin/insecure

# Add secrets to Dockerfile
cat >> Dockerfile <<EOF
# Taken from AWS Docs https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds-programmatic-access.html
ENV AWS_KEY=AKIAIOSFODNN7EXAMPLE
ENV AWS_SECRET=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
EOF

cp config/config.inc.php.dist config/config.inc.php

git add Dockerfile config/config.inc.php
git commit -m "Add insecure secrets into the repository to test pull request scanning"
git push

gh repo set-default eti-tme-org/vuln-web-app
gh pr create --title "Demo - PR with secrets added" --body "An example PR that should flag secrets detected."
```

A summary screenshot of the resulting PR tests is shown below:

![PR Scan Summary Results](./images/demo.code.prscan.png)

Feel free to investigate the [detailed scan results in GitHub](https://github.com/eti-tme-org/vuln-web-app/pull/2)

## Pre-requisites

On your local system (assuming MacOS for this demo), you'll need to have these core utilities installed onto your laptop:

- git: Xcode Command Line Tools, initially for Homebrew setup
- [Homebrew](brew.sh)
- jq: [Brewfile.code](./Brewfile.code)

For the brew packages, you can install them by hand or leverage the Brewfiles via:

```bash
brew bundle install --file Brewfile.XXX
```

Additional software and requirements are explained in detail below.

### Software and Artifacts

This demo relies on GitHub code repositories set up for Panoptica in the "eti-tme-org" organization.  Those repositories are git submodules of this repository so, to properly obtain them, you'll need to clone this repository with additional arguments:

```bash
git clone --recurse-submodules https://github.com/eti-tme-org/code-cicd-demo.git
```

Additionally, we rely on the publicly available container image for the latest version of NGINX 

### Panoptica API Key Generation

To be able to upload job results into the Panoptica UI, you'll have to generate an API Key, following the [CI/CD CLI Tool Instructions](https://docs.panoptica.app/docs/cicd-cli-tool). You must ensure to uplevel the default permissions (read only) on the key in order to be able to POST results to Panoptica UI.

### Panoptica CLI Download

You'll need the proper platform and version of the CI/CD CLI binary from the Panoptica UI. The main [CI/CD CLI Tool](https://docs.panoptica.app/docs/cicd-cli-tool) docs list the current versions of the CLI, the latest as of this repo is [CI/CD CLI v1.5.1](https://docs.panoptica.app/docs/cicd-cli-v15). Secret scanning requires version 1.6.0 or newer.

The platform you select is where you will run the CLI, not the platform from which you are fetching the CLI. For example, if you are a MacOS user getting the CLI for use in GitHub Actions, you'll likely need the Linux AMD64 version.

### Panoptica CI/CD Policy Created

For these demo use cases, two CI/CD Policies have been created in the demonstration environment (links to demo environment only work if you have access to the demo environment):

- "Demo - Vulnerable Package Detection": A [Detect with Severity High](https://console.panoptica.app/global-policies/rule/1be9b0c1-e8b2-4dee-8bb8-5ecf3a487e9d) policy to identify 3+ Vulnerabilities of Severity High or Critical in a given package
- "Demo - Block IaC Critical Misconfigurations": A [Block with Severity Critical](https://console.panoptica.app/global-policies/rule/13f91394-2d4e-4349-bec9-759b7c920804) policy to identify 3+ IaC Misconfiguration of Severity Critical in a give file.

These policies will be referenced in the CI/CD examples below. Creation of the policies is documented at the end of this [README.md](./README.md#policy-setup)

### Docker - local socket (optional)

For local container scanning, you'll need to have either Docker Desktop or Rancher Desktop installed and configured to expose the docker socket for the CLI command.

### GitHub Pull Request Scanning (optional)

There is a preloaded pull request already present in the vulnerable application repository. However, if you'd like to generate your own pull requests (on your own repo where you have push privileges), you'll need to generate the pull request via the GitHub web UI or the CLI:

- [gh](./Brewfile.github) cli

### Hashicorp Cloud Platform (optional)

This demo leverages Hashicorp Cloud Platform to store/provide the required credentials via environment variables.  As such, you'll need CLI support for HCP:

```bash
# Install the HCP software
brew bundle install --file Brewfile.hcp

# Authenticate to HCP
hcp auth login

# Create a profile (this assumes simplistic HCP environment)
hcp profile init --vault-secrets
```

Note: for the sake of supporting non-HCP mechanisms of storing keys, the code stored here will manually extract the HCP secrets into the environment variables instead of prefacing commands with the typical **hcp vault-secrets run -- <cmd>** and rely on those environments throughout.

In short, you could choose one of two adventures to populate the required environment variables:

- **source hcp-secrets.sh** - extract secrets from HCP
- Manually set **PANOPTICA_CLI_ACCESS_KEY** and **PANOPTICA_CLI_SECRET_KEY** with values from the Panoptica UI.

## References
- [OWASP](https://owasp.org/www-project-damn-vulnerable-web-sockets/) [Damn Vulnerable Web Socket](https://github.com/interference-security/DVWS.git): no secret or IaC issues.
- [Damn Vulnerable Web App](https://github.com/digininja/DVWA.git): Has secrets and IaC issues.

## Policy Setup

The following screenshots document the policy configuration in the Panoptica UI for the scenarios leveraged by this demo.

### Demo - Vulnerable Package Detection

![Step 1](./images/demo.policy.block-vuln-critical-1.png)

![Step 2](./images/demo.policy.block-vuln-critical-2.png)

### Demo - Block IaC Critical Misconfigurations

![Step 1](./images/demo.policy.block-iac-critical-1.png)

![Step 2](./images/demo.policy.block-iac-critical-2.png)
