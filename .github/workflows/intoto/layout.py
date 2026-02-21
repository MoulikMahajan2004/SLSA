#These are the above libraries which are used to create the layout of the pipeline it is the document which is a preplan how the pipeline will be created and this fill when run creates the json file which help us in comparing the recorded file and the layout which we defined already

from in_toto.models.layout import Layout, Step, Inspection
from in_toto.models.metadata import Metablock
from in_toto.models._signer import load_public_key_from_file
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from securesystemslib.signer import CryptoSigner
#loading the public key of the functionaries from the file
pubkey_dict = load_public_key_from_file("./keys/ci.pub")

cryo_signer = CryptoSigner(load_pem_private_key(open("./keys/ci.key", "rb").read(), password=None))

# Create layout
layout = Layout()
#setting the expiration date for the layout to 4 months from the time of creation, which means that the layout will be considered valid for 4 months and after that it will expire and need to be renewed or updated. This is a security measure to ensure that the layout is not used indefinitely and that it is regularly reviewed and updated as needed.
layout.set_relative_expiration(months=4)


#each part which is to be compared is reffered as step

# --- terraform-init ---
s_init = Step(name="terraform-init")
s_init.pubkeys = [pubkey_dict["keyid"]]
s_init.add_material_rule_from_string("ALLOW *")
s_init.add_product_rule_from_string("CREATE .terraform/*")
s_init.add_product_rule_from_string("CREATE .terraform.lock.hcl")
s_init.add_product_rule_from_string("DISALLOW *")

# --- terraform-plan ---
s_plan = Step(name="terraform-plan")
s_plan.pubkeys = [pubkey_dict["keyid"]]
s_plan.add_material_rule_from_string("MATCH * WITH PRODUCTS FROM terraform-init")
s_plan.add_material_rule_from_string("DISALLOW *")
s_plan.add_product_rule_from_string("CREATE tfplan.binary")
s_plan.add_product_rule_from_string("DISALLOW *")

# --- sigstore-sign ---
s_sig_sign = Step(name="sigstore-sign")
s_sig_sign.pubkeys = [pubkey_dict["keyid"]]
s_sig_sign.add_material_rule_from_string("MATCH tfplan.binary WITH PRODUCTS FROM terraform-plan")
s_sig_sign.add_material_rule_from_string("DISALLOW *")
s_sig_sign.add_product_rule_from_string("CREATE tfplan.binary.sigstore.json")
s_sig_sign.add_product_rule_from_string("DISALLOW *")

# --- sigstore-verify ---
s_sig_verify = Step(name="sigstore-verify")
s_sig_verify.pubkeys = [pubkey_dict["keyid"]]
s_sig_verify.add_material_rule_from_string("MATCH tfplan.binary WITH PRODUCTS FROM terraform-plan")
s_sig_verify.add_material_rule_from_string("MATCH tfplan.binary.sigstore.json WITH PRODUCTS FROM sigstore-sign")
s_sig_verify.add_material_rule_from_string("DISALLOW *")
s_sig_verify.add_product_rule_from_string("CREATE sigstore_verify.txt")
s_sig_verify.add_product_rule_from_string("DISALLOW *")

# --- create-terraformplan-json ---
s_json = Step(name="create-terraformplan-json")
s_json.pubkeys = [pubkey_dict["keyid"]]
s_json.add_material_rule_from_string("MATCH tfplan.binary WITH PRODUCTS FROM terraform-plan")
s_json.add_material_rule_from_string("DISALLOW *")
s_json.add_product_rule_from_string("CREATE terraformplan.json")
s_json.add_product_rule_from_string("DISALLOW *")

# --- opa-policy ---
s_opa = Step(name="opa-policy")
s_opa.pubkeys = [pubkey_dict["keyid"]]
s_opa.add_material_rule_from_string("MATCH terraformplan.json WITH PRODUCTS FROM create-terraformplan-json")
s_opa.add_material_rule_from_string("ALLOW tf.rego")
s_opa.add_material_rule_from_string("MATCH tfplan.binary WITH PRODUCTS FROM terraform-plan")
s_opa.add_material_rule_from_string("DISALLOW *")
s_opa.add_product_rule_from_string("CREATE opa_result.txt")
s_opa.add_product_rule_from_string("DISALLOW *")

inspection = Inspection(name="verify-json")
inspection.set_run_from_string("terraform show -json tfplan.binary")
inspection.add_material_rule_from_string(
    "MATCH tfplan.binary WITH PRODUCTS FROM terraform-plan"
)

sigstoreinspection = Inspection(name="sigstore-verify-inspection")
sigstoreinspection.set_run_from_string("cat sigstore_verify.txt")

# Add steps and inspections to layout
layout.steps = [s_init, s_plan, s_sig_sign, s_sig_verify, s_json, s_opa]
layout.inspect = [inspection, sigstoreinspection]


metablock = Metablock(signed=layout)
metablock.create_signature(cryo_signer)
metablock.dump("root.layout")
