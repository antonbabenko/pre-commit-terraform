# Wrapper for the root module

The configuration in this directory contains an implementation of a single module wrapper pattern, which allows managing several copies of a module in places where using the native Terraform 0.13+ `for_each` feature is not feasible (e.g., with Terragrunt).

You may want to use a single Terragrunt configuration file to manage multiple resources without duplicating `terragrunt.hcl` files for each copy of the same module.

This wrapper does not implement any extra functionality.

## Usage with Terragrunt

`terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//wrappers"
  # Alternative source:
  # source = "git::git@github.com:terraform-aws-modules/terraform-aws-s3-bucket.git//wrappers?ref=master"
}

inputs = {
  defaults = { # Default values
    create = true
    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```

## Usage with Terraform

```hcl
module "wrapper" {
  source = "terraform-aws-modules/s3-bucket/aws//wrappers"

  defaults = { # Default values
    create = true
    tags = {
      Terraform   = "true"
      Environment = "dev"
    }
  }

  items = {
    my-item = {
      # omitted... can be any argument supported by the module
    }
    my-second-item = {
      # omitted... can be any argument supported by the module
    }
    # omitted...
  }
}
```

## Example: Manage multiple S3 buckets in one Terragrunt layer

`eu-west-1/s3-buckets/terragrunt.hcl`:

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//wrappers"
  # Alternative source:
  # source = "git::git@github.com:terraform-aws-modules/terraform-aws-s3-bucket.git//wrappers?ref=master"
}

inputs = {
  defaults = {
    force_destroy = true

    attach_elb_log_delivery_policy        = true
    attach_lb_log_delivery_policy         = true
    attach_deny_insecure_transport_policy = true
    attach_require_latest_tls_policy      = true
  }

  items = {
    bucket1 = {
      bucket = "my-random-bucket-1"
    }
    bucket2 = {
      bucket = "my-random-bucket-2"
      tags = {
        Secure = "probably"
      }
    }
  }
}
```
