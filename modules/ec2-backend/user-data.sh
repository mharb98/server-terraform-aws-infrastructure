#!/bin/bash
# Use this for your user data (script from top to bottom)
yum update -y

# Installation of docker
yum -y install docker
service docker start
chmod 666 /var/run/docker.sock
docker pull marwanharb98/to-do-app

# Installation of node to parse the secrets
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18

# Exporting environment
aws secretsmanager get-secret-value --secret-id to-do-app-secrets --query SecretString --output text > secrets.json
npm install --global convert-json-env
convert-json-env secrets.json --prefix="export " --out=.test.env
eval $(cat .test.env)
rm -rf secrets.json && rm -rf .test.env

docker run -d -it -e DATABASE_URL=$DATABASE_URL -p 80:3000 --name to-do-app marwanharb98/to-do-app
