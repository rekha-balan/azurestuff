cat ~/.ssh/id_rsa.pub | ssh testadmin@52.151.31.193 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >>  ~/.ssh/authorized_keys"
