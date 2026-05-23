# Securing the Software Delivery Lifecycle Against Unauthorized Modifications

## Zero-Trust CI/CD Security Architecture using GitHub Actions, GPG, OPA, Cosign, in-toto and AWS

![Zero-Trust CI/CD Architecture]
<p align="center">
  <img src="./Workflow-Mechanism/software delivery secure mechanism.png" alt="Zero Trust CI/CD Architecture" width="1000"/>
</p>
---

## 1. Project Overview

This project implements a layered Zero-Trust CI/CD security architecture to protect the software delivery lifecycle against unauthorized modifications.

The pipeline ensures that source code, infrastructure plans, build artifacts, provenance metadata, and deployed AWS resources are verified before they are trusted.

The implementation follows the research idea that CI/CD security should not depend on one single control. Instead, it uses multiple security layers:

- GPG commit signing
- GitHub branch protection
- GitHub Actions workflow validation
- Open Policy Agent policy enforcement
- Terraform infrastructure validation
- Sigstore Cosign artifact signing
- in-toto provenance generation and verification
- AWS CloudTrail audit logging
- AWS Config compliance monitoring
- Amazon CloudWatch metric alarms
- Amazon SNS email notifications

---

## 2. Architecture Explanation

The architecture begins with a developer signing source code commits using a GPG private key. GitHub repository rules then enforce verified commits so that unsigned or untrusted commits cannot enter the protected branch.

After a verified commit is pushed, GitHub Actions triggers the CI/CD pipeline. The pipeline checks out the source code, verifies commit trust, validates Terraform infrastructure, applies OPA policies, signs artifacts using Cosign, and generates provenance metadata using in-toto.

If the infrastructure is valid and all verification stages pass, Terraform deploys the approved AWS resources. After deployment, AWS CloudTrail records API activity, AWS Config checks resource compliance, CloudWatch monitors metrics such as EC2 CPU usage, and SNS sends alerts if suspicious activity or cost-related thresholds are reached.

The attack scenario demonstrates that if an attacker somehow bypasses the CI pipeline and modifies infrastructure manually, for example by making an EC2 instance public or increasing usage, CloudTrail, CloudWatch and SNS provide post-deployment detection and alerting. Terraform state can then be used to roll back the environment to the last known good configuration.

---

## 3. Folder Structure

```text
SSECURE SOFTWARE DELIVERY ARCHITECTURE/
├── .github/
│   └── workflows/
│       └── slsapipeline.yaml
|       ├── intoto/
│            ├── layout.py
│            ├── root.layout
│            ├── keys/
│            │   ├── ci.key
│            │   └── ci.pub
│            └── links/
│
├── terra/
│   ├── backend.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── sg.tf
│   ├── cloudtrail.tf
│   ├── cloudwatch.tf
│   ├── sns.tf
│   └── tf.rego
|
├── workflow-Mechanism/
│   └── software delivery secure mechanism.png
│
├── .gitignore
└── README.md
```

---

## 4. Prerequisites

Install the following tools before running the project:

- Git
- GPG
- Terraform
- Open Policy Agent
- Cosign
- in-toto
- AWS CLI
- GitHub account
- AWS account

Check versions:

```bash
git --version
gpg --version
terraform version
aws --version
cosign version
in-toto-run --version
opa version
```

---

# 5. Step 1 — Configure GPG Commit Signing

## 5.1 Generate a GPG Key

```bash
gpg --full-generate-key
```

Recommended options:

```text
Key type: RSA and RSA
Key size: 4096
Expiry: 0 or suitable expiry
Name: Your Name
Email: your-github-email@example.com
```

---

## 5.2 List GPG Keys

```bash
gpg --list-secret-keys --keyid-format=long
```

Example output:

```text
sec   rsa4096/ABC1234567890000
uid   Your Name <your-github-email@example.com>
```

Copy the long key ID:

```text
ABC1234567890000
```

---

## 5.3 Configure Git to Use the GPG Key

```bash
git config --global user.signingkey ABC1234567890000
git config --global commit.gpgsign true
git config --global user.name "Your Name"
git config --global user.email "your-github-email@example.com"
```

---

## 5.4 Export Public GPG Key

```bash
gpg --armor --export ABC1234567890000
```

Copy the full public key:

```text
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
```

---

## 5.5 Add GPG Key to GitHub

Go to:

```text
GitHub → Settings → SSH and GPG keys → New GPG key
```

Paste the exported public key and save it.

---

## 5.6 Test Signed Commit

```bash
git add .
git commit -S -m "test: verified signed commit"
git log --show-signature -1
```

Push the commit:

```bash
git push origin main
```

GitHub should show the commit as **Verified**.

---

# 6. Step 2 — Enable GitHub Verified Commit Policy

GitHub branch protection ensures only trusted commits can be merged into the main branch.

Go to:

```text
Repository → Settings → Rules → Rulesets → New ruleset
```

Recommended rules:

```text
Target branch: main
Require signed commits: Enabled
Require pull request before merging: Enabled
Require approvals: Enabled
Require status checks: Enabled
Block force pushes: Enabled
Restrict deletions: Enabled
```

This ensures:

- Unsigned commits are blocked
- Unverified commits are rejected
- Direct unsafe changes to main are prevented
- CI/CD checks must pass before merge

---

# 7. Step 3 — Configure AWS Credentials in GitHub Secrets

Create an IAM user or IAM role with minimum required permissions for:

- EC2
- VPC
- S3
- CloudTrail
- CloudWatch
- SNS
- AWS Config
- IAM permissions only if required by Terraform

Add secrets in GitHub:

```text
Repository → Settings → Secrets and variables → Actions → New repository secret
```

Add:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
SNS_EMAIL
```

Recommended region:

```text
ap-southeast-2
```

Do not commit AWS keys into GitHub.

---

# 8. Step 4 — Terraform Infrastructure Setup

Terraform is used to create and manage AWS infrastructure.

Example `provider.tf`:

```hcl
provider "aws" {
  region = var.aws_region
}
```

Example `variables.tf`:

```hcl
variable "aws_region" {
  default = "ap-southeast-2"
}

variable "instance_type" {
  default = "t3.micro"
}
```

Example `ec2.tf`:

```hcl
resource "aws_instance" "secure_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = false

  tags = {
    Name = "secure-cicd-instance"
  }
}
```

The EC2 instance should follow the allowed structure defined by OPA policy. If an attacker or developer changes the instance type or makes the instance public, the pipeline should fail or monitoring should detect it after deployment.

---

# 9. Step 5 — OPA Policy-as-Code

OPA validates Terraform plan JSON before deployment.

Example `tf.rego`:

```rego
package pipeline

deny[msg] {
  resource := input.planned_values.root_module.resources[_]
  resource.type == "aws_instance"
  resource.values.instance_type != "t3.micro"
  msg := sprintf("Denied: EC2 instance type %s is not allowed. Only t3.micro is approved.", [resource.values.instance_type])
}

deny[msg] {
  resource := input.planned_values.root_module.resources[_]
  resource.type == "aws_instance"
  resource.values.associate_public_ip_address == true
  msg := "Denied: EC2 instance must not be publicly exposed."
}
```

Generate Terraform plan JSON:

```bash
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > terraformplan.json
```

Run OPA:

```bash
opa eval --fail-defined -i terraformplan.json -d tf.rego "data.pipeline.deny" | tee opa_result.txt
```

If `deny` returns a result, the pipeline must stop.

---

# 10. Step 6 — GitHub Actions Pipeline

Example `.github/workflows/slsapipeline.yaml`:

```yaml
name: Zero Trust CI/CD Security Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

permissions:
  contents: read
  id-token: write
  actions: read

jobs:
  secure-cicd:
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: terra

    steps:
      - name: Source Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-2

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Install OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
          chmod +x opa
          sudo mv opa /usr/local/bin/

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: |
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > terraformplan.json

      - name: OPA Policy Check
        run: |
          opa eval --fail-defined -i terraformplan.json -d tf.rego "data.pipeline.deny" | tee opa_result.txt
          if grep -q "Denied" opa_result.txt; then
            echo "OPA policy violation detected"
            exit 1
          fi

      - name: Upload Terraform Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: terraform-plan
          path: |
            terra/tfplan.binary
            terra/terraformplan.json
            terra/opa_result.txt
```

---

# 11. Step 7 — Cosign Artifact Signing

Cosign signs the Terraform plan or build artifact so that deployment uses only trusted artifacts.

Generate key pair:

```bash
cosign generate-key-pair
```

This creates:

```text
cosign.key
cosign.pub
```

Sign artifact:

```bash
cosign sign-blob tfplan.binary --key cosign.key --output-signature tfplan.binary.sig
```

Verify artifact:

```bash
cosign verify-blob tfplan.binary \
  --key cosign.pub \
  --signature tfplan.binary.sig
```

Security purpose:

- Prevents artifact tampering
- Confirms artifact authenticity
- Ensures deployment uses the verified Terraform plan

---

# 12. Step 8 — in-toto Provenance

in-toto records evidence of each pipeline step.

Example command:

```bash
in-toto-run \
  --step-name terraform-plan \
  --signing-key ../intoto/keys/ci.key \
  --metadata-directory ../intoto/links \
  --materials provider.tf variables.tf ec2.tf sg.tf tf.rego \
  --products terraformplan.json tfplan.binary opa_result.txt \
  -- terraform plan -out=tfplan.binary
```

Verify layout:

```bash
in-toto-verify \
  --layout ../intoto/root.layout \
  --layout-key ../intoto/keys/ci.pub \
  --metadata-directory ../intoto/links
```

Security purpose:

- Confirms expected pipeline steps were executed
- Verifies materials and products
- Improves software supply chain traceability
- Detects unauthorized workflow manipulation

---

# 13. Step 9 — Terraform Deployment

Deployment should only happen after:

- Commit is verified
- Terraform validation passes
- OPA policy passes
- Cosign verification passes
- in-toto provenance verification passes

Apply the trusted plan:

```bash
terraform apply tfplan.binary
```

This creates only approved AWS resources.

---

# 14. Step 10 — CloudTrail Audit Logging

CloudTrail records AWS API activity.

Example Terraform:

```hcl
resource "aws_cloudtrail" "secure_cicd_trail" {
  name                          = "secure-cicd-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}
```

Security purpose:

- Records who changed infrastructure
- Tracks API calls
- Supports investigation after suspicious changes

---

# 15. Step 11 — CloudWatch CPU and Cost Alerting

CloudWatch monitors EC2 usage. In the research scenario, the expected cost is low, for example around 2 dollars. If an attacker changes infrastructure or causes high usage, CloudWatch can detect abnormal CPU usage.

Example alarm:

```hcl
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "ec2-high-cpu-cost-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alert when EC2 CPU usage is high"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    InstanceId = aws_instance.secure_instance.id
  }
}
```

---

# 16. Step 12 — SNS Email Alert

SNS sends email alerts when a policy failure, attack scenario, or CloudWatch alarm occurs.

Example:

```hcl
resource "aws_sns_topic" "security_alerts" {
  name = "secure-cicd-security-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

After Terraform apply, confirm the SNS subscription from your email inbox.

---

# 17. Attack Scenario Explained

The attack scenario included in this project is:

```text
Attacker bypasses CI gates
        ↓
Unauthorized cloud change
        ↓
EC2 becomes public or expensive usage begins
        ↓
CloudTrail records AWS API activity
        ↓
CloudWatch detects CPU threshold breach
        ↓
SNS sends alert email
        ↓
Investigation and rollback using Terraform state
```

This scenario shows that even if preventive controls fail, detective and corrective controls still help reduce the impact.

---

# 18. Security Layer Mapping

| Security Area | Tool / Service | Protection |
|---|---|---|
| Source Integrity | GPG + GitHub Rules | Blocks unsigned commits |
| IaC Compliance | OPA Rego | Blocks non-approved infrastructure |
| Artifact Integrity | Cosign | Verifies plan/artifact identity |
| Provenance | in-toto | Confirms expected steps |
| Deployment Trust | Terraform Apply | Applies exact verified plan |
| Audit | CloudTrail | Records AWS API activity |
| Monitoring | CloudWatch | Detects abnormal usage |
| Alerting | SNS | Sends email alert |
| Recovery | Terraform State | Supports rollback |

---

# 19. Commands Summary

```bash
# GPG
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
gpg --armor --export KEY_ID

# Git signed commit
git config --global user.signingkey KEY_ID
git config --global commit.gpgsign true
git commit -S -m "secure signed commit"

# Terraform
terraform init
terraform validate
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > terraformplan.json

# OPA
opa eval --fail-defined -i terraformplan.json -d tf.rego "data.pipeline.deny"

# Cosign
cosign sign-blob tfplan.binary --key cosign.key --output-signature tfplan.binary.sig
cosign verify-blob tfplan.binary --key cosign.pub --signature tfplan.binary.sig

# in-toto
in-toto-run --step-name terraform-plan --materials terraformplan.json --products tfplan.binary -- terraform plan -out=tfplan.binary
in-toto-verify --layout root.layout --layout-key ci.pub
```

---

# 20. Research Contribution

This project contributes a practical implementation of a Zero-Trust CI/CD security model for cloud-native infrastructure delivery.

The contribution is that it combines preventive, detective, and corrective controls in one pipeline:

- Preventive: GPG, GitHub rules, OPA, Cosign, in-toto
- Detective: CloudTrail, CloudWatch, AWS Config
- Corrective: SNS alerting and Terraform rollback

This supports the research argument that secure software delivery requires continuous validation across the complete lifecycle rather than isolated security tools.

---

# 21. Conclusion

This implementation shows how CI/CD pipelines can be strengthened against unauthorized modifications using a layered security approach. GPG and GitHub rules protect source integrity, OPA protects infrastructure compliance, Cosign protects artifact integrity, in-toto protects provenance, and AWS monitoring services provide post-deployment visibility.

The architecture improves trust, accountability, traceability, and resilience across the cloud-native software delivery lifecycle.
