# Create an S3 bucket for Terraform state
export BUCKET_NAME="jamf-eks-hw-terraform-state"
aws s3 mb s3://${BUCKET_NAME} --region us-east-2

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Save bucket name for later
echo "export TERRAFORM_STATE_BUCKET=${BUCKET_NAME}" >> ~/.zshrc