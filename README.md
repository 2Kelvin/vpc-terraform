# Building a Multi-AZ AWS VPC with Terraform

## Architecture Overview

To learn AWS networking from the ground up, I built a highly available Virtual Private Cloud (VPC) using Terraform.
The infrastructure spans two Availability Zones (AZs) for fault tolerance and includes:

- **Public & Private Subnets** (split across both AZs)
- **Internet Gateway (IGW)** for public internet access
- **NAT Gateway** for secure private outbound traffic
- **Route Tables** to direct internal and external traffic

## Network Traffic Flow & Security

I separated the infrastructure via subnets to keep the frontend accessible and the backend secure.

- The **public Subnet** hosts public-facing resources like web frontends. It connects directly to the `Internet Gateway` to allow two-way public traffic.
- The **private Subnet**: Hosts backend resources and databases holding sensitive data. It has no direct internet exposure.

  If a private resource needs internet access, maybe for upgrades or patches, it routes traffic through a `NAT Gateway` in the public subnet. **The NAT masks the resource's private IP with its own Elastic IP**, fetches the data via the `Internet Gateway`, and safely routes the response back.

Resources within the same VPC can natively communicate with each other securely, guided by local `route table` rules.

## 6 Key Takeaways From This Project

1. **NAT Gateway Placement**: A NAT Gateway must be provisioned inside a public subnet because it requires a public Elastic IP to mask private traffic.
2. **Global Tagging**: Instead of tagging resources individually, use Terraform’s `default_tags` block in the provider configuration to simplify cost tracking and organization.
3. **DRY Code with Count**: Use the Terraform `count` meta-argument to avoid rewriting code when deploying multiple identical resources like subnets or route tables.
4. **Public IP Automation**: Creating a public subnet doesn't automatically grant public IPs to instances. You must explicitly set `map_public_ip_on_launch = true`.
5. **Targeted Recreation**: If you update an EC2 instance's User Data or Public IP configurations, you don't need to tear down the whole infrastructure. Use `terraform apply -replace="aws_instance.instance_name"` to recreate just that resource.
