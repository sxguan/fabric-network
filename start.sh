
docker rm -f $(docker ps -aq)

docker volume prune

docker-compose up -d

sleep 10
./createChannel.sh

sleep 2
./deployChaincode.sh