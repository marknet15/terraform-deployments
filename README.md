# HomeLab Terraform Configuration

## Overview

Repo for my Terraform testing, learning and internal home lab.

## Requirements

At least Terraform v0.12.24 is required.

## Usage

**Raspberry Pi**

- raspberrypi (Bootstrapping cluster setup)


**Commands:**

```
terraform init ./raspberrypi
terraform plan --var-file required.tfvars ./raspberrypi
terraform apply --var-file required.tfvars ./raspberrypi
```
