# Introduction

Shell scripts that can assist in deploying SoftEther VPN server and client.

- server_deploy: Install Softether VPN Server. 

- client_deploy: Install only the SoftEther Client, users need to specify other server addresses themselves, with the default being the local machine.

# Usage

System requirements: Debian 12 (bookworm)

- ./chatgpt_proxy_access.sh status | install | uninstall | enable | disable

- ./server_deploy.sh status | install | uninstall | enable | disable

- ./client_deploy.sh status | install | uninstall | enable | disable

If necessary, you can modify the global variables in the shell script to make it meet your requirements.