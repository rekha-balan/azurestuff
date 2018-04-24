ANSIBLE_HOST_KEY_CHECKING=False 
ansible_winrm_transport=basic 
ansible_connection=winrm 
ansible_ssh_user=testadmin
ansible_ssh_pass=Password1234!
ansible_ssh_port=5986
ansible_winrm_server_cert_validation=ignore
echo ansible_connection=$ansible_connection
ansible -i azure_rm.py winacctestrg -m ping 
