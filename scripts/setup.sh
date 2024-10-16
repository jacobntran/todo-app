#!/bin/bash

apt update

apt install apache2 nodejs npm unzip -y

mkdir /opt/todo-app

cd /opt/todo-app

git init

git remote add origin https://github.com/jacobntran/todo-app.git

git sparse-checkout init --cone

git sparse-checkout set code

git pull origin main