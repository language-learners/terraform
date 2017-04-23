# Terraform module: Single-server ECS cluster

This module defines a single server that attaches an EBS volume at boot
and registers itself with an ECS cluster.  The ECS cluster, in turn, tells
it what Docker containers to run.  We run nothing on the server except what
ECS tells us to run, so there's _nothing_ we need to install!

See `variables.tf` for this module's input variables, and `outputs.tf` for
the values that we define and export.
