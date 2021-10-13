# ansible-winrm-cert-auth
Certificate authentication for WinRM 

## Steps that needs to be followed to setup Connection between Ansible controller (RHEL 8) and target hosts (Windows Server 2016)

####  Step-1
`sudo yum -y install @development`

####  Step-2
`pip3 install --user --upgrade setuptools`

####  Step-3
`pip3 install --user ansible  -  Step-3 `

`ansible --version`

`ansible --version | grep "python version"`

####  Step-4
`sudo yum -y install gcc openssl-devel bzip2-devel libffi-devel`

####  Step-5
`pip3 install --user "pywinrm>=0.3.0"`

####  Step-6
Create new hosts.yml or add following entries in existing hosts file:

    #/**** hosts.yml to establish connection using Basic Authentication*******************************
    all:
      hosts:
        localhost:
      children:
        windowserver:
           hosts:
             10.1.1.1.1:
                ansible_user: ansible
                ansible_password: ansible-user-password-for-windows
                ansible_connection: winrm
                ansible_winrm_transport: basic
                ansible_winrm_port: 5985
                ansible_winrm_server_cert_validation: ignore

    #/**** hosts.yml *******************************	
    
    Create new hosts.yml or add following entries in existing hosts file cert-auth-hosts.yml:
    
    #/**** cert-auth-hosts.yml *******************************	
    all:
      hosts:
        localhost:
      children:
        windowserver:
           hosts:
             10.198.169.10:
                ansible_user: ansible          
                ansible_connection: winrm          
                ansible_winrm_port: 5986
                ansible_winrm_server_cert_validation: ignore
                ansible_winrm_cert_pem: /opt/ansible/ansible_cert.pem
                ansible_winrm_cert_key_pem: /opt/ansible/ansible_key.pem
                ansible_winrm_transport: certificate
                ansible_winrm_scheme: https
    #/**** cert-auth-hosts.yml *******************************


## WinRm setup On Windows Machine:

Step 1: Create ansible user manually and given him an administrator role .

**`Note`** : ***Before executing any PS scrips, you should update those as per your need.***

Step 2: Execute the Powershell scripts provided in the following sequence:

Download the required PS scripts from https://github.com/sandipsable111/ansible-winrm-cert-auth  
1. enable_winrm.ps1 
         - Script will not work you need to manually edit Local Group Policy 
           Administrative Templates-> Windows Components - > Windows Remote Management (WinRM) -> WinRM Service - > edit "Allow remote server management through WinRM" and enable it, and enter the "*" as a values for IPv4 & IPv6 Filter.	

2. For Setting up Basic Authentication (using username and password) enable following WinRM properties:
  
  `winrm set winrm/config/service '@{AllowUnencrypted="true"}'`
  
  `winrm set WinRM/Config/service/Auth '@{Basic="true"}'`

  You are done , you are all set to establish connection using basic authentication for ansible user.

***You must perform following steps in order to establish certificate authentication*** 

2. Generate Self-signed certs using following command with OPENSSL on Ansible Controller machine   
	
    cat > openssl.conf << EOL
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    [v3_req_client]
    extendedKeyUsage = clientAuth
    subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:ansible
    EOL

    export OPENSSL_CONF=openssl.conf

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -outansible_cert.pem -outform PEM -keyout ansible_key.pem -subj "/CN=ansible" -extensions v3_req_client

    rm openssl.conf
  
4. import_client_cert.ps1 - Copied from ansible machine (RHEL) created for ansible 
                        user ansible_cert.pem (Public key) 
3. create_ansible_user.ps1
4. create_winrm_listener.ps1
5. update_firewall.ps1
		
**`Note`** : We can change listening HTTPS and HTTP ports from default to any other refer below links :
        https://adamtheautomator.com/winrm-port/
        

After completing all the setup execute following ansible command to test the connectivity with window host machine:

  `"$ ansible windowserver -i hosts.yml -m win_ping"`




#### Refere below Optional steps if required :

#sudo yum install python36  - Can be Skip

#sudo yum install python-pip  - Can be Skip

python3 -m ensurepip --upgrade - - Can be Skip

sudo yum install python-pip python-wheel

sudo yum upgrade python-setuptools     - Can be Skip

pip3 install --user -U setuptools - Can be Skip

pip3 install --user --upgrade setuptools  - Step-2

pip3 install --user ez_setup  - Can be Skip

 python3 -m pip install --user --upgrade pip  - Can be Skip

pip3 install --user ansible  -  Step-3 

ansible --version	  
 
ansible --version | grep "python version"

#Install Python 3.8 + https://tecadmin.net/install-python-3-8-centos/

sudo yum -y install gcc openssl-devel bzip2-devel libffi-devel     - Step-4

pip3 install --user "pywinrm>=0.3.0"   - Step-5


###Install Ansible collection for core Windows plugins using following command 
      
	"ansible-galaxy collection install ansible.windows"
	
			OR 
    Doenload "ansible-windows-1.7.2.tar.gz" tarball file from https://galaxy.ansible.com/ansible/windows 
	   and Install using following command.

    "$ansible-galaxy collection install ansible-windows-1.7.2.tar.gz"	

Attach IAM policy to get accesss of EC2 target host machines In case of Dynamic Inventory.
        


## WinRM Commands

    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm enumerate winrm/config/Listener

    winrm get winrm/config/Service

    winrm get winrm/config/Winrs

    # Update WinRM service configs :

    #Service *Required
    winrm get winrm/config/service
    winrm get WinRM/Config/service/Auth

    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set WinRM/Config/service/Auth '@{Basic="true"}'


    ##Client Optional
    winrm set winrm/config/client/auth @{Basic="true"} 

        OR
    winrm set WinRM/Config/service/Auth
     '@{Basic="true";Kerberos="false";Negotiate="false";Certificate="false";CredSSP="false"}'


    #If above two are set to false you will get following error :

      fatal: [10.198.169.5]: UNREACHABLE! => {"changed": false, "msg": "basic: the specified credentials were rejected by the server", "unreachable": true}

    ## To remove a WinRM listener:  If required

    # Remove all listeners
       Remove-Item -Path WSMan:\localhost\Listener\* -Recurse -Force

    # Only remove listeners that are run over HTTPS
       Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTPS" } | Remove-Item -Recurse -Force

    # Remove all ClientCertificates
      Remove-Item -Path WSMan:\localhost\ClientCertificate\* -Recurse -Force
      
      winrm set winrm/config/service '@{AllowUnencrypted="false"}'
      winrm set winrm/config/service/auth '@{Basic="false"}'
      winrm set winrm/config/service/auth '@{Negotiate="true"}'
      winrm set WinRM/Config/Client/Auth '@{Basic="false";Digest="false";Kerberos="false";Negotiate="true";Certificate="true";CredSSP="false"}'

################################################################################

Enable / Open ports 5985 and 5986 at window firewall level or network WAF level.
  
 

## Issue Faced :
    Never set Negotiate="false" for /server/auth winrm confguration , it restricts you from accessing winrm service.
	
	Resolution: Computer > Policies > Administrative Templates > Windows Components > Windows Remote Management > WinRM Service:
		  Disallow Negotiate Authentication: Disabled	
####	
