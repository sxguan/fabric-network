echo "=========== Explorer start Installing =============="

# remove docker container
docker rm -f explorer.mynetwork.com
docker rm -f explorerdb.mynetwork.com

# remove docker volumes
docker volume rm  artifacts_walletstore
docker volume rm  artifacts_pgdata

# up the docker container
docker-compose up -d


echo "=========== Explorer Successfully installed =============="
echo "=========== http://localhost:8080/ ==============="
echo "username: admin"
echo "password: adminpw"
