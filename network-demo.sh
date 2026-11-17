#!/usr/bin/env bash
# Assignment 2 - Part 1: Docker Networking
# Re-runs every step of the assignment in order and saves the output of each
# command into logs/. Usage:  ./network-demo.sh
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p logs

# run <logfile> <command>  -> prints "$ command" followed by its output, and appends both to logs/<logfile>
run() { local f="logs/$1"; shift; { echo "\$ $*"; eval "$@" 2>&1; echo; } | tee -a "$f"; }

echo "== 1. Create a bridge network =="
run 01-create-network.log "docker network create --driver bridge my_network"
run 01-create-network.log "docker network ls --filter name=my_network"

echo "== 2. nginx_container on my_network, published on 8080 =="
run 02-nginx-container.log "docker run -d --name nginx_container --network my_network -p 8080:80 nginx"
sleep 2
run 02-nginx-container.log "docker ps --filter name=nginx_container"
run 02-nginx-container.log "docker logs nginx_container"

echo "== 3. Verify http://localhost:8080 =="
run 03-verify-8080.log "curl -s -o /dev/null -w 'HTTP status: %{http_code}\n' http://localhost:8080"
run 03-verify-8080.log "curl -s http://localhost:8080 | grep -i '<title>\|<h1>'"

echo "== 4. httpd_container on my_network, published on 8081 =="
run 04-httpd-container.log "docker run -d --name httpd_container --network my_network -p 8081:80 httpd"
sleep 2
run 04-httpd-container.log "docker ps --filter name=httpd_container"
run 04-httpd-container.log "docker logs httpd_container"

echo "== 5. Verify http://localhost:8081 =="
run 05-verify-8081.log "curl -s -o /dev/null -w 'HTTP status: %{http_code}\n' http://localhost:8081"
run 05-verify-8081.log "curl -s http://localhost:8081"

echo "== 6. Inspect my_network + container-to-container DNS =="
run 06-network-inspect.log "docker network inspect my_network"
run 06-network-inspect.log "docker network inspect my_network --format '{{range .IPAM.Config}}Subnet={{.Subnet}} Gateway={{.Gateway}}{{end}}'"
run 06-network-inspect.log "docker network inspect my_network --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}'"
run 06-dns-test.log "docker exec nginx_container curl -s http://httpd_container"
run 06-dns-test.log "docker exec nginx_container getent hosts httpd_container"

echo "== 7. Stop and remove nginx_container =="
run 07-remove-nginx.log "docker stop nginx_container"
run 07-remove-nginx.log "docker rm nginx_container"
run 07-remove-nginx.log "docker ps -a --filter name=nginx_container"
run 07-remove-nginx.log "docker network inspect my_network --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}'"
run 07-remove-nginx.log "curl -s -o /dev/null -w 'HTTP status: %{http_code}\n' http://localhost:8080 || echo 'Connection refused - port 8080 no longer served'"

echo "== 8. nginx_container_2 on my_network, published on 8082 =="
run 08-nginx-container-2.log "docker run -d --name nginx_container_2 --network my_network -p 8082:80 nginx"
sleep 2
run 08-nginx-container-2.log "docker ps --filter name=nginx_container_2"
run 08-nginx-container-2.log "docker network inspect my_network --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{println}}{{end}}'"

echo "== 9. Verify http://localhost:8082 =="
run 09-verify-8082.log "curl -s -o /dev/null -w 'HTTP status: %{http_code}\n' http://localhost:8082"
run 09-verify-8082.log "curl -s http://localhost:8082 | grep -i '<title>\|<h1>'"

echo "== 10. List running containers =="
run 10-container-ls.log "docker container ls"
run 10-container-ls.log "docker container ls --filter network=my_network --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}'"

echo "== 11. Stop and remove all assignment containers =="
run 11-cleanup-containers.log "docker stop nginx_container_2 httpd_container"
run 11-cleanup-containers.log "docker rm nginx_container_2 httpd_container"

echo "== 12. Remove my_network =="
run 12-remove-network.log "docker network rm my_network"
run 12-remove-network.log "docker network ls"
