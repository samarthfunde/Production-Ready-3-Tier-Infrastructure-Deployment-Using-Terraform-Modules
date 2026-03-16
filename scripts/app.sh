#!/bin/bash

sudo yum update -y
sudo yum install python3 -y

pip3 install flask
pip3 install pymysql

# Terraform injected variables
DB_HOST=${db_host}
DB_USER=${db_user}
DB_PASS=${db_pass}

export DB_HOST
export DB_USER
export DB_PASS

cat <<EOF > /home/ec2-user/app.py
from flask import Flask, request
import pymysql
import os

app = Flask(__name__)

connection = pymysql.connect(
    host=os.environ['DB_HOST'],
    user=os.environ['DB_USER'],
    password=os.environ['DB_PASS'],
    database="appdb"
)

cursor = connection.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS users(
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(100),
email VARCHAR(100),
password VARCHAR(100)
)
""")

connection.commit()

@app.route("/register", methods=["POST"])
def register():

    name = request.form["name"]
    email = request.form["email"]
    password = request.form["password"]

    cursor.execute(
        "INSERT INTO users(name,email,password) VALUES(%s,%s,%s)",
        (name,email,password)
    )

    connection.commit()

    return "Registration Successful"

app.run(host="0.0.0.0", port=5000)
EOF

# run flask in background
nohup python3 /home/ec2-user/app.py > /home/ec2-user/app.log 2>&1 &