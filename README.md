# Production-Ready 3-Tier Infrastructure Deployment Using Terraform Modules

This project deploys a complete 3-tier web application on AWS using Terraform modules. A user opens a registration form in the browser, submits their details, and the data gets stored in a MySQL database on Amazon RDS. The infrastructure is fully managed through Terraform.



---

## How It Works

The request travels through three layers:

- The Web Server receives the request from the browser. It runs NGINX in a public subnet and forwards the request to the App Server.
- The App Server runs a Flask application in a private subnet. It processes the form data and sends it to the database.
- The Database is an RDS MySQL instance in a private database subnet. It stores the user records and is not accessible from the internet.

---

## Project Structure

```
.
├── html/
│   └── index.html               # Frontend registration form
├── modules/
│   ├── vpc/                     # VPC, subnets, IGW, NAT, route tables
│   ├── web/                     # Web Server EC2 and security group
│   ├── app/                     # App Server EC2 and security group
│   └── rds/                     # RDS instance, subnet group, security group
├── scripts/                     # Setup scripts for web and app servers
├── main.tf                      # Calls all modules
├── provider.tf                  # AWS provider and region
├── variables.tf                 # Input variable declarations
├── terraform.tfvars             # actual variable values
├── outputs.tf                   # Outputs like public IPs and RDS endpoint
├── keypair.tf                   # SSH key pair for EC2 access
├── terraform-key                # Private key (never commit this)
└── terraform-key.pub            # Public key
```

---

## Prerequisites

Before you begin, make sure you have the following installed and configured on your machine:

- Terraform
- AWS CLI
- VS Code with the Terraform and AWS Toolkit extensions

---

## Step 1 — Set Up AWS Credentials

Create an IAM user in the AWS Console named `terraform-user` and attach the `AdministratorAccess` policy to it.

Then go to that user's Security Credentials tab and create an Access Key. Download the CSV file — you will need the Access Key ID and Secret Access Key.

Run `aws configure` in your terminal and enter your Access Key, Secret Key, region, and output format.

---

## Step 2 — Clone the Repository

Clone this repository to your local machine and open the folder in VS Code.

---

## Step 3 — Add Your Variable Values

Open `terraform.tfvars` and fill in your values. This includes things like your AWS region, your local IP address for SSH access, the database password, and the AMI ID you want to use for the EC2 instances.

Do not commit this file if it contains sensitive values like passwords.

---

## Step 4 — Review the Module Structure

This project uses four Terraform modules. Each one handles one layer of the infrastructure:

The `vpc` module creates the VPC, public and private subnets, the Internet Gateway, the NAT Gateway, and all route tables. The web and app layers communicate through this networking setup.

The `web` module creates the Web Server EC2 instance in the public subnet and its security group. The security group allows HTTP on port 80 from the internet and SSH from your IP only.

The `app` module creates the App Server EC2 instance in the private subnet and its security group. The security group only allows traffic on port 5000 from the Web Server and SSH from the Bastion Host.

The `rds` module creates the RDS MySQL instance, the DB subnet group across the database subnets, and the security group that only allows MySQL traffic on port 3306 from the App Server.

All four modules are wired together in the root `main.tf` file.

---

## Step 5 — Deploy the Infrastructure

Open a terminal in the project root folder and run the following commands one by one:

First, run `terraform init` to download the AWS provider and initialize all modules.

Then run `terraform validate` to check that your configuration files have no syntax errors.

Then run `terraform plan` to see a preview of everything Terraform is going to create. Review this carefully before proceeding.

Then run `terraform apply` and type `yes` when prompted. Terraform will now create all the AWS resources. This takes a few minutes.

Once it finishes, the terminal will print the outputs defined in `outputs.tf` — this includes the Web Server's public IP and the RDS endpoint. Save these values.

---

## Step 6 — Set Up the Bastion Host (Manual Step)

The Bastion Host is not created by Terraform. You need to create it manually from the AWS Console.

Launch a new EC2 instance in the same public subnet as the Web Server. Use Amazon Linux 2, a t2.micro instance type, and create a security group that only allows SSH on port 22 from your IP address.

You will use this Bastion Host to SSH into the private App Server.

---

## Step 7 — Configure the Web Server

SSH into the Web Server using its public IP and the terraform-key private key.

Install NGINX on the server. Then edit the NGINX configuration to set up a reverse proxy. The configuration should forward any requests to the `/register` path to the App Server's private IP on port 5000. After updating the config, start and enable the NGINX service.

Copy the `index.html` file from the `html/` folder in the repo to the NGINX web root on the server so the registration form is served to users.

---

## Step 8 — Configure the App Server

SSH into the Bastion Host first, then from there SSH into the App Server using its private IP.

Install Python 3, pip, Flask, and PyMySQL on the server.

Set the database environment variables on the server — the RDS endpoint, database username, password, and database name. These are needed by the Flask app to connect to RDS.

Copy the Flask application script from the `scripts/` folder in the repo to the App Server and run it in the background using nohup so it keeps running after you close the terminal.

---

## Step 9 — Verify the Database

From the App Server, install the MySQL client. Then connect to the RDS instance using the endpoint from the Terraform outputs along with the admin username and password.

Once connected, check that the database and users table exist. After submitting the registration form from the browser, run a query to confirm that the user data was saved correctly.

---

## Step 10 — Test the Application

Open a browser and navigate to the Web Server's public IP address. The registration form should appear.

Fill in the form and submit it. You should see a success message. Then check the database to confirm the record was inserted.

---

## Destroying the Infrastructure

When you are done and want to remove all AWS resources to avoid charges, run `terraform destroy` from the project root and type `yes` to confirm. This removes everything Terraform created.

Note: The Bastion Host was created manually so you need to terminate it manually from the AWS Console as well.

---


## What I Learned From This Project

- How to break Terraform infrastructure into reusable modules for VPC, compute, and database layers
- How AWS VPC networking works including subnets, route tables, Internet Gateway, and NAT Gateway
- How to design security groups so each layer is only reachable from the layer directly above it
- How a 3-tier architecture separates web, application, and database responsibilities
- How to use NGINX as a reverse proxy to forward traffic to a backend
- How to connect a Flask application to a managed RDS MySQL database
- How to securely access private EC2 instances using a Bastion Host
- How to debug and verify a working cloud deployment end to end
