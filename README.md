# Production-Ready 3-Tier Infrastructure Deployment Using Terraform Modules

A 3-tier web application deployed on AWS using Terraform. Users fill out a registration form in the browser, and the data moves through three layers — web, application, and database — before being stored in a managed MySQL database on RDS.

GitHub: https://github.com/samarthfunde/Production-Ready-3-Tier-Infrastructure-Deployment-Using-Terraform-Modules.git

---

## How the Application Works

1. User opens the browser and types the Web Server's public IP.
2. A registration form appears.
3. User fills in the form and submits it.
4. NGINX on the Web Server receives the request and forwards it to the App Server.
5. Flask on the App Server processes the data.
6. Flask connects to the RDS MySQL database and saves the user's record.
7. A success message is sent back to the user.

---

## Architecture

```
Internet
    |
Internet Gateway
    |
Public Subnet
    |-- Web Server (EC2 + NGINX)
    |-- Bastion Host (EC2, for SSH access only)
         |
    Private Subnet
         |-- App Server (EC2 + Flask)
              |
         Database Subnet
              |-- RDS MySQL
```

---

## Project Folder Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── subnets/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security_groups/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── rds/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Step 1 — AWS Account Setup

### Create an IAM User

Go to AWS Console → IAM → Users → Create user

- Name: `terraform-user`
- Attach policy: `AdministratorAccess`

### Create Access Keys

Go to IAM → Users → `terraform-user` → Security credentials → Create access key

Download the `.csv` file. You will need the Access Key ID and Secret Access Key in the next step.

---

## Step 2 — Install Required Tools

### Terraform

Download from https://developer.hashicorp.com/terraform/downloads, extract it, and add the binary to your system PATH.

```bash
terraform -version
```

### AWS CLI

Download from https://aws.amazon.com/cli/ and install it.

```bash
aws --version
```

Configure it with your IAM credentials:

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, region (e.g. us-east-1), output format (json)
```

### VS Code Extensions

Install these two extensions in VS Code:
- Terraform
- AWS Toolkit

---

## Step 3 — Terraform Infrastructure

### AWS Provider (main.tf)

```hcl
provider "aws" {
  region = var.aws_region
}
```

### VPC Module

```hcl
module "vpc" {
  source               = "./modules/vpc"
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  name                 = "my-vpc"
}
```

**modules/vpc/main.tf**

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}
```

### Subnets Module

```hcl
module "subnets" {
  source = "./modules/subnets"
  vpc_id = module.vpc.vpc_id

  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets     = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnets    = ["10.0.5.0/24", "10.0.6.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b"]
  internet_gateway_id = module.vpc.igw_id
}
```

**modules/subnets/main.tf**

```hcl
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "private-subnet-${count.index + 1}" }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnets)
  vpc_id            = var.vpc_id
  cidr_block        = var.database_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "db-subnet-${count.index + 1}" }
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

### Security Groups Module

```hcl
module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
  my_ip  = var.my_ip
}
```

**modules/security_groups/main.tf**

```hcl
# Web Server - allows HTTP from internet and SSH from your IP
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# App Server - allows port 5000 from Web Server and SSH from Bastion
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Database - allows MySQL only from App Server
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### EC2 Module

```hcl
module "web_server" {
  source            = "./modules/ec2"
  ami               = var.ami_id
  instance_type     = "t2.micro"
  subnet_id         = module.subnets.public_subnet_ids[0]
  security_group_id = module.security_groups.web_sg_id
  key_name          = var.key_name
  name              = "web-server"
}

module "app_server" {
  source            = "./modules/ec2"
  ami               = var.ami_id
  instance_type     = "t2.micro"
  subnet_id         = module.subnets.private_subnet_ids[0]
  security_group_id = module.security_groups.app_sg_id
  key_name          = var.key_name
  name              = "app-server"
}
```

**modules/ec2/main.tf**

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  tags = {
    Name = var.name
  }
}
```

### RDS Module

```hcl
module "rds" {
  source            = "./modules/rds"
  db_name           = "mydb"
  username          = "admin"
  password          = var.db_password
  instance_class    = "db.t3.micro"
  subnet_ids        = module.subnets.database_subnet_ids
  security_group_id = module.security_groups.db_sg_id
}
```

**modules/rds/main.tf**

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "main" {
  identifier             = "mydb-instance"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}
```

---

## Step 4 — Deploy the Infrastructure

Run these commands from your project root folder:

```bash
# Download providers and initialize modules
terraform init

# Check for any errors in your configuration
terraform validate

# See what Terraform will create before actually doing it
terraform plan

# Create everything on AWS
terraform apply

# When you are done and want to remove everything
terraform destroy
```

---

## Step 5 — Bastion Host Setup (Manual)

The Bastion Host is created manually from the AWS Console. It sits in the public subnet and is used only to SSH into the private App Server.

Create an EC2 instance with:
- AMI: Amazon Linux 2
- Subnet: any public subnet
- Security Group: allow SSH (port 22) from your IP only

To reach the App Server through the Bastion:

```bash
# First SSH into the Bastion
ssh -i your-key.pem ec2-user@<BASTION_PUBLIC_IP>

# Then from the Bastion, SSH into the App Server
ssh -i your-key.pem ec2-user@<APP_SERVER_PRIVATE_IP>
```

---

## Step 6 — Web Server Configuration (NGINX)

SSH into the Web Server and run:

```bash
sudo yum update -y
sudo yum install nginx -y
```

Create the NGINX config file:

```bash
sudo nano /etc/nginx/conf.d/app.conf
```

Paste this configuration and replace `APP_SERVER_PRIVATE_IP` with the actual private IP of your App Server:

```nginx
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /register {
        proxy_pass http://<APP_SERVER_PRIVATE_IP>:5000/register;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Start NGINX:

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## Step 7 — App Server Configuration (Flask)

SSH into the App Server via the Bastion Host, then run:

```bash
sudo yum update -y
sudo yum install python3-pip -y
pip3 install flask pymysql
```

Set environment variables so Flask knows how to connect to the database:

```bash
export DB_HOST=<RDS-ENDPOINT>
export DB_USER=admin
export DB_PASSWORD=<your-password>
export DB_NAME=mydb
```

Create the Flask application file:

```bash
nano app.py
```

Paste this code:

```python
from flask import Flask, request, jsonify
import pymysql
import os

app = Flask(__name__)

def get_db_connection():
    return pymysql.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD'],
        database=os.environ['DB_NAME']
    )

@app.route('/register', methods=['POST'])
def register():
    data = request.form
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO users (name, email) VALUES (%s, %s)",
        (data['name'], data['email'])
    )
    conn.commit()
    cursor.close()
    conn.close()
    return jsonify({"message": "User registered successfully"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Run the application in the background so it keeps running after you close the terminal:

```bash
nohup python3 app.py &
```

---

## Step 8 — Database Access from App Server

Install the MySQL client:

```bash
sudo yum install mariadb105-server -y
```

Connect to the RDS database:

```bash
mysql -h <RDS-ENDPOINT> -u admin -p
```

Once connected, run these SQL commands to verify everything is working:

```sql
SHOW DATABASES;
USE mydb;
SHOW TABLES;
SELECT * FROM users;
```

---

## Troubleshooting

Check if the Flask application is running:

```bash
ps aux | grep python
```

View Flask logs:

```bash
cat nohup.out

# Watch logs live
tail -f nohup.out
```

Confirm the DB_HOST variable is set correctly:

```bash
echo $DB_HOST
```

Test that the RDS endpoint resolves:

```bash
nslookup <RDS-ENDPOINT>
```

Test MySQL connection manually:

```bash
mysql -h <RDS-ENDPOINT> -u admin -p
```

Restart MariaDB if needed:

```bash
sudo systemctl start mariadb
```

---

## What I Learned From This Project

- How to structure Terraform code using reusable modules
- AWS VPC networking: subnets, route tables, and internet gateways
- How to design security groups so each layer only talks to the layer directly below it
- How a 3-tier architecture keeps web, application, and database concerns separated
- How to configure NGINX as a reverse proxy to forward requests to a backend
- How to build a Flask backend that accepts form data and writes it to MySQL
- How to access private resources securely using a Bastion Host
- How to debug cloud infrastructure using logs, CLI tools, and environment variables
