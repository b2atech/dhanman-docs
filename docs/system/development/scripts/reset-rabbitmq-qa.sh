#!/bin/bash

set -e

# RabbitMQ container name
CONTAINER_NAME="rabbitmq-qa"

# Credentials
USER="dhanman_qa"
PASSWORD='B@dhi$1234'
VHOST="/"

echo "🛑 Stopping RabbitMQ app..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl stop_app

echo "🧹 Resetting RabbitMQ node (all data will be lost)..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl reset

echo "✅ Starting RabbitMQ app again..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl start_app

echo "📦 Recreating virtual host..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl add_vhost $VHOST

echo "👤 Creating user: $USER"
sudo docker exec -it $CONTAINER_NAME rabbitmqctl add_user $USER "$PASSWORD"

echo "🔑 Granting administrator tag..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl set_user_tags $USER administrator

echo "🔐 Setting full permissions on vhost $VHOST..."
sudo docker exec -it $CONTAINER_NAME rabbitmqctl set_permissions -p $VHOST $USER ".*" ".*" ".*"

echo "✅ RabbitMQ reset and user/vhost recreated successfully."
