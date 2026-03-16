#!/bin/bash

sudo yum update -y
sudo yum install nginx -y

sudo systemctl start nginx
sudo systemctl enable nginx

APP_IP=${app_private_ip}

cat <<EOF > /etc/nginx/conf.d/app.conf
server {

    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /register {

        proxy_pass http://$APP_IP:5000;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;

    }

}
EOF

cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>User Registration</title>

<style>

body{
font-family: Arial;
background: linear-gradient(to right,#667eea,#764ba2);
display:flex;
justify-content:center;
align-items:center;
height:100vh;
}

.container{
background:white;
padding:30px;
border-radius:10px;
width:350px;
box-shadow:0px 0px 10px rgba(0,0,0,0.3);
}

h2{
text-align:center;
}

input{
width:100%;
padding:10px;
margin:10px 0;
border-radius:5px;
border:1px solid #ccc;
}

button{
width:100%;
padding:10px;
background:#667eea;
border:none;
color:white;
font-size:16px;
border-radius:5px;
cursor:pointer;
}

</style>
</head>

<body>

<div class="container">

<h2>User Registration</h2>

<form action="/register" method="POST">

<input type="text" name="name" placeholder="Full Name" required>

<input type="email" name="email" placeholder="Email" required>

<input type="password" name="password" placeholder="Password" required>

<button type="submit">Register</button>

</form>

</div>

</body>
</html>
EOF

sudo systemctl restart nginx