##
## IAM General Setup
##

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 18
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}

# Making IAM user to sync files to s3
resource "aws_iam_user" "freenas-backup" {
  name = "freenas-backup"

  tags = {
    name        = "freenas-backup"
    terraform   = "true"
    description = "This programatic user will have access to S3 only"
  }
}

# Make AWS credentials for the user
resource "aws_iam_access_key" "freenas-backup" {
  user = "${aws_iam_user.freenas-backup.name}"
}

# Output the access key
output "freenas-backup-access" {
  description = "This is the access key for the freenas-bacup user."
  value       = "${aws_iam_access_key.freenas-backup.id}"
}

# Output the secret key
output "freenas-backup-secret" {
  description = "This is the secret key for the freenas-bacup user."
  value       = "${aws_iam_access_key.freenas-backup.secret}"
}

# Make a group to stick S3 access only users in
resource "aws_iam_group" "S3-freenas-group" {
  name = "freenas-bucket-only"
}

# Put the freenas-backup user in the group
resource "aws_iam_group_membership" "freenas-backup-membership" {
  name = "freenas-backup-membership"

  users = [
    "${aws_iam_user.freenas-backup.name}",
  ]

  group = "${aws_iam_group.S3-freenas-group.name}"
}

# Make a policy to only access the S3 bucket that we create
resource "aws_iam_policy" "freenas-bucket-only-policy" {
  name        = "freenas-bucket-only"
  description = "This policy will only allow you to read/write in the freenas-backup bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.freenas-backups-bucket.id}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${aws_s3_bucket.freenas-backups-bucket.id}/*"]
    }
  ]
}
EOF
}

# Attach the policy to the group we created earlier
resource "aws_iam_group_policy_attachment" "attach-freenas-bucket-only" {
  group      = "${aws_iam_group.S3-freenas-group.name}"
  policy_arn = "${aws_iam_policy.freenas-bucket-only-policy.arn}"
}

# Create the S3 bucket for freenas backups
# This has the lifecycle policy settings to keep the objects
resource "aws_s3_bucket" "freenas-backups-bucket" {
  bucket = "freenas-backups-${var.name_suffix}"
  acl    = "private"
  region = "${var.region}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = "${var.standard_ia_transition}"
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = "${var.noncurrent_version_transition}"
      storage_class = "GLACIER"
    }
  }
}

output "s3_bucket_name" {
  description = "This will be the backup bucket name to use in the cloud sync task."
  value       = "${aws_s3_bucket.freenas-backups-bucket.id}"
}
