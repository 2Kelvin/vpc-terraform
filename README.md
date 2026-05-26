explain why:

- nat, internet gateway, route tables, cidr (vpc + subnets), and public & private subnets
- nat is connected to public subnet
- nat & internet gateway is only one in a multi-azs vpc
- 2 azs instead of one
- NAT gateway needs a created EIP assigned to it
- tags: help manage and track resources 
- reusable tf code -> in resume: reduced repetitive code by 50%
- map_public_ip_on_launch = true
- terraform apply -replace="aws_instance.test_vpc_instance" --> saved time from recreating the whole infrastructure. also learnt that Ips are assigned on instance creation not while the instance is already running. same as user_data script; it runs only once during instance creation
