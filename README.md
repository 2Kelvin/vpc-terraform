# AWS Multi-AZ VPC Infrastructure

# all the AWS resources required for a fully functional VPC:

- subnets (private and public)
- NAT gateway
- internet gateway
- route tables
- 2 AZs for enhanced availability

I took a deep dive into AWS VPC to learn it deeply and build it from the ground up; and that's what I exactly did; creating a VPC using Terraform understanding every single component and what significance it has in the bigger picture.

I built a highly available VPC in two availability zones with each zone having a public and private subnet. In case one availability zone went down, the other AZ is up and running your workloads and applications.

This is the general flow of traffic in the VPC; the public subnet(s) host the public facing side of the app that users interact with e.g. the frontend of a website while the backend side of your app e.g. databases are hosted in the private subnet(s). This ensures enhanced security for the database which contains sensitive data that need not be accessed by everyone on the internet.

The public subnet connects directly to the internet gateway to allow traffic to the internet. If the database needs to connect to the internet, it does so through the NAT gateway. The NAT gateway receives the traffic from the database or any resource hosted in the private subnet, looks at its route table and sees that the traffic destination is not in the subnet's or vpc's CIDR hence it needs to exit this network to another. The NAT masks the database's IP and replaces it with it's own (the public one) for safety and directs the traffic out through the internet gateway. The response justs reverses this process, once it reenters through the gateway destined for the NAT gateway, the NAT gateway remembers the actual source that sent it this traffic/the one that it masked, unmasks its own and places the actual private IP of the database as the destination of the response. This way the database's private IP is never exposed to the public so it protects it from attacks.
Basically, if any resource is hosted in the private subnet, it's traffic to the internet is handled by the NAT gateway while for public subnet resources, the traffic kto the internet is handled by the internet gateway directly. The processing of each of these network traffic is all written down in the route table of either the NAT gateway or the internet gateway.
If any resource needs to talk to other resources in the vpc, they can easily do so since they are in the same VPC network. Their subnets can talk to each other without causing security vulnerabilities. The route table rules direct this internal traffic too.

## Concepts I learnt from the project

1. The NAT gateway is an actual AWS resource that gets provisioned with a public and private IP, since it needs to be a stable IP across restarts and shutdowns it gets assigned an Elastic IP.
2. Although its role is to help the private subnet resources access the internet safely, the NAT gateway is provisioned inside the public subnet so that it can get assigned a public Elastic IP that will be used for masking private subnet IPs during internet access.
3. Tags help easily track related resources that relate together for e.g. analytics, cost checking and optimization and they can be set in the resource block as well as the default tags block. The default tags block makes it easy to assign a tag for all the resources in the terraform file without having to rewrite them in each resource block.
4. When creating multiple similar AWS resources like subnets, NAT gateways, routing tables etc in Terraform, use the `count` meta-argument to reuse code.
5. Creating public subnets connected successfully to the internet gateway and assigned the necessary route table doesnot automatically make the resources created in the subnet have access to the internet/have a public IP. You need to add `map_public_ip_on_launch = true` statement to enable public IPs assignment to public resources.
6. Public IPs and user data scripts are assigned and ran only at instance creation, incase of any said updates when the instance is already running, you can efficiently tear only the instance down and not the whole infrasructure and then replace it with a new instance with the said changes using this command: `terraform apply -replace="aws_instance.instance_name"`
