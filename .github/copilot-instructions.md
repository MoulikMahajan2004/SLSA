<!-- Copilot / AI agent instructions for SLSA Terraform repo -->
# Purpose
Short, actionable guidance to help an AI coding agent be productive in this repository.

# Big picture
- **What:** This repo manages AWS infrastructure via Terraform under the `terra/` directory and implements SLSA/Supply-chain checks in GitHub Actions.
- **Pipeline:** GitHub Actions implement a three-stage flow: `plan` (create binary plan + OPA policy check + sigstore signing), `provenance` (SLSA generator), and `apply` (verify provenance then apply plan).
- **Policy & signing:** Policies live as `terra/tf.rego` (OPA). The plan binary is `terra/tfplan.binary` and `terraform show -json` produces `terraformplan.json` used by OPA. Sigstore is used to sign the binary in the workflow.

# Key files (inspect first)
- [azurepipeline.yml](azurepipeline.yml)
- [\.github/workflows/terraformpipeline.yaml](.github/workflows/terraformpipeline.yaml)
- [\.github/workflows/slsapipeline.yaml](.github/workflows/slsapipeline.yaml)
- [terra/provider.tf](terra/provider.tf) (AWS provider, `var.tfregion`)
- [terra/tf.rego](terra/tf.rego) (OPA policy used by the workflows)
- [terra/vpc.tf](terra/vpc.tf), [terra/ec2.tf](terra/ec2.tf), [terra/sg.tf](terra/sg.tf) (infra examples)
- [.github/workflows/intotokeys/in-toto/keys/intoto.yaml](.github/workflows/intotokeys/in-toto/keys/intoto.yaml) and [\.github/workflows/intoto/root.layout](.github/workflows/intoto/root.layout) (in-toto layout/keys)

# Developer workflows & exact commands
Use the `terra/` directory for Terraform commands and produce the JSON plan for OPA checks.

Local reproduce of the pipeline plan step:

```
cd terra
terraform init -input=false
terraform plan -out=tfplan.binary -input=false
terraform show -json tfplan.binary > terraformplan.json
opa eval -i terraformplan.json -d tf.rego 'data.pipeline'
sha256sum tfplan.binary | base64 -w0   # produces base64_subjects used by SLSA generator
```

To run the apply verification locally (verify SLSA provenance): install `slsa-verifier` and run `slsa-verifier verify-artifact --artifact-path tfplan.binary --source "github.com/<owner>/<repo>" --branch "main"` as in the workflow.

# Project-specific conventions
- Terraform plan must be produced as a *binary* at `terra/tfplan.binary` and then converted to JSON for OPA checks.
- OPA policy filename is `tf.rego` in `terra/` and workflows call `opa eval -i terraformplan.json -d tf.rego 'data.pipeline'`.
- Pipelines sign the exact binary plan (sigstore) and the apply job downloads that artifact—do not re-run `terraform plan` in apply.
- AWS creds are expected in repository secrets: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
- Terraform provider pinned via `terra/provider.tf` (aws ~> 6.0).

# Typical agent tasks & examples
- When adding resources, update `terra/tf.rego` if new checks are needed (look at existing rule that denies unmanaged `aws_instance`).
- For CI changes, update [\.github/workflows/terraformpipeline.yaml](.github/workflows/terraformpipeline.yaml). Preserve the `plan -> provenance -> apply` ordering and signing/verification steps.
- When referencing the pipeline subject or SLSA inputs, compute `sha256sum terra/tfplan.binary | base64 -w0` to match the workflow's `base64_subjects` output.

# When uncertain
- Prefer minimal, non-destructive changes; run the local plan + OPA steps above before changing apply behavior.
- If you need to update signing/verification, inspect the sigstore usage in [\.github/workflows/terraformpipeline.yaml](.github/workflows/terraformpipeline.yaml) and in-toto keys under `.github/workflows/intotokeys/`.

# Ask
If any of these file links are missing or you want the agent to modify pipelines, tell me which area to prioritize (policy, CI, or Terraform).  