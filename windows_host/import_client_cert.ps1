# path to the genereated client cert
$pubKeyFilePath = '..\Ansible\ansible_cert.pem'

# Import the public key into Trusted Root Certification Authorities and Trusted People
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\Root'
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
