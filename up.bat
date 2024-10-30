docker stop php83
docker rm php83

docker run -d --name php83 -v d:/dev/:/var/www/  -p 9083:9000 php83

pause