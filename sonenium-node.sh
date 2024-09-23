#!/bin/bash

# Function to print in green
print_green() {
    echo -e "\e[32m$1\e[0m"
}

# Print logo from external source
curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
sleep 5

# Check Docker installation
if ! command -v docker &> /dev/null
then
    print_green "Docker not installed. Installing Docker..."

    # Detect OS distribution and install Docker accordingly
    if [[ -f /etc/debian_version ]]; then
        sudo apt update
        sudo apt install -y docker.io
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum install -y docker
    elif [[ -f /etc/arch-release ]]; then
        sudo pacman -S docker
    else
        print_green "Unsupported OS. Please install Docker manually."
        exit 1
    fi
    sudo systemctl start docker
    sudo systemctl enable docker
else
    print_green "Docker is already installed."
fi

# Check and install Docker Compose
if ! docker compose version &> /dev/null; then
    print_green "Docker Compose not installed. Installing Docker Compose..."

    # Install Docker Compose based on OS distribution
    if [[ -f /etc/debian_version ]]; then
        sudo apt-get update
        sudo apt-get install -y docker-compose-plugin
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum update
        sudo yum install -y docker-compose-plugin
    else
        print_green "Unsupported OS for automatic Docker Compose installation."
        exit 1
    fi
else
    print_green "Docker Compose is already installed."
fi

# Create and navigate to the directory
if [[ ! -d "sonenium-node-by-winsnip" ]]; then
    mkdir sonenium-node-by-winsnip
    print_green "Directory 'sonenium-node-by-winsnip' created."
fi
cd sonenium-node-by-winsnip

# Download files
curl -o jwt.txt https://docs.soneium.org/assets/files/jwt-31d6cfe0d16ae931b73c59d7e0c089c0.txt
curl -o docker-compose.yaml https://docs.soneium.org/assets/files/docker-compose-003749bd470bb0677fb5b8e2a82103ed.yml
curl -o minato-genesis.json https://docs.soneium.org/assets/files/minato-genesis-5e5db79442a6436778e9c3c80a9fd80d.json
curl -o minato-rollup.json https://docs.soneium.org/assets/files/minato-rollup-6d00cc672bf6c8e9c14e3244e36a2790.json
curl -o sample.env https://docs.soneium.org/assets/files/sample-4ab2cad1f36b3166b45ce4d8fed821ab.env

# Generate a JWT
print_green "Generating JWT..."
openssl rand -hex 32 > jwt.txt

# Move sample.env to .env
mv sample.env .env

# Ask user if they already created RPC
read -p "Did you already create your RPC? (yes/no): " rpc_answer

if [[ "$rpc_answer" != "yes" ]]; then
    echo "Please register your RPC at https://drpc.org?ref=db24c0"
    echo "Script aborted."
    exit 1
fi

# Installation animation
echo -n "installing"
for i in {1..6}; do
    echo -n "."
    sleep 0.5
done
echo

# Read inputs from the user
read -p "Input your RPC ETH SEPOLIA: " L1_URL
read -p "Input your RPC ETH SEPOLIA BEACON: " L1_BEACON

# Update .env with user input
sed -i "s|L1_URL=https://sepolia-l1.url|L1_URL=$L1_URL|g" .env
sed -i "s|L1_BEACON=https://beacon-l1.url|L1_BEACON=$L1_BEACON|g" .env

# Get public IP and update P2P_ADVERTISE_IP
var_ip_pub=$(curl -s ifconfig.me)
sed -i "s|P2P_ADVERTISE_IP=<Node Public IP>|P2P_ADVERTISE_IP=$var_ip_pub|g" .env

# Update Docker Compose with public IP
sed -i "s|--nat=extip:<your_node_public_ip>|--nat=extip:$var_ip_pub|g" docker-compose.yaml

# Run Docker Compose
if command -v docker-compose &> /dev/null
then
    docker-compose up -d
else
    docker compose up -d
fi
