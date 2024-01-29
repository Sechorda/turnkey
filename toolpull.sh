# Pull down tools

# -
sudo apt update
sudo apt upgrade

# - Stage Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm ./get-docker.sh

# - OWASP ZAP 
echo 'deb http://download.opensuse.org/repositories/home:/cabelo/xUbuntu_22.10/ /' | sudo tee /etc/apt/sources.list.d/home:cabelo.list
curl -fsSL https://download.opensuse.org/repositories/home:cabelo/xUbuntu_22.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_cabelo.gpg > /dev/null
sudo apt update
sudo apt install owasp-zap

docker pull caido/caido
docker run --rm -p 7000:8080 caido/caido:latest
