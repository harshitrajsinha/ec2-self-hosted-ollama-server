# Private, SSM-only EC2 instance on AWS

Terraform that provisions a private, internet-isolated EC2 instance managed
exclusively through AWS Systems Manager (SSM), with an opt-in layer for
short-lived internet access during maintenance.

## Project Overview

- Provisions a private, internet-isolated EC2 instance that is managed
  exclusively through AWS Systems Manager (SSM) — no SSH, no public IP, no
  inbound access.
- Designed for secure-by-default compute that you operate remotely via SSM
  Session Manager, with optional, short-lived internet access for maintenance.

## Network Foundation

- Custom VPC with DNS resolution and DNS hostnames enabled (required for SSM
  private endpoints to resolve).
- One or more private subnets (default: one AZ), none with a route to the
  internet.
- SSM connectivity is delivered privately through VPC interface endpoints
  (ssm, ssmmessages, ec2messages) with private DNS enabled, so the instance
  reaches SSM over AWS's private network instead of the internet.

## Security Model

- Two security groups enforce a closed 443-only path: the instance can talk
  only to the SSM endpoints on 443, and the endpoints accept 443 only from the
  instance.
- No inbound traffic is permitted to the instance at any time.
- The SG-to-SG references are added as separate rule resources to avoid a
  circular Terraform dependency.

## Compute

- Ubuntu 24.04 LTS instance (SSM Agent preinstalled via the AMI), so it
  auto-registers as a managed node with no user data and no internet.
- No public IP, IMDSv2 enforced, 20 GB gp3 root volume.
- `t3.large` by default (configurable via `var.instance_type`).

## IAM

- An EC2 instance role (the "EC2 Role for AWS Systems Manager" use case)
  attached via an instance profile, authorizing the instance as SSM-managed.
- A separate IAM user with full SSM access for you to use locally to start
  sessions. No access keys are created in Terraform — you create them yourself
  and add them to a local AWS profile.

## Optional Internet Access (disabled by default)

- A self-contained module toggled by `enable_internet_access` (default
  `false`).
- When enabled, it adds a public subnet, an internet gateway, a NAT gateway
  with an elastic IP, and the route tables to send the instance's traffic
  through the NAT. The outbound 443/80 rules are added to the instance's
  existing security group (not a separate SG), so toggling off only removes
  rules rather than destroying an attached SG — enough for `apt-get update`
  and package installs.
- SSM keeps working during internet-enabled periods because it uses the private
  VPC endpoints, not the NAT.

## Operating the Stack

- **Connect to the instance:** create access keys for the SSM user, configure a
  local AWS profile with `region = us-east-1`, install the session-manager-plugin,
  then `aws ssm start-session --target <instance_id> --profile <profile>`.
- **Enable internet for maintenance:** `terraform apply -var enable_internet_access=true`
  (the NAT takes a couple of minutes to become available).
- **Disable internet when done:** `terraform apply -var enable_internet_access=false`
  — the network layer is destroyed and the 443/80 egress rules are removed from
  the instance's security group, returning the instance to its fully isolated
  state.
- **Cost note:** a NAT gateway bills hourly even when idle; toggle it off when
  the work is done to stop charges.
