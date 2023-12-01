
# Enable PowerShell Remoting
Enable-PSRemoting -Force

# Set WinRM service startup type to automatic
Set-Service WinRM -StartupType 'Automatic'

# Configure WinRM settings
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $true
Set-Item -Path 'WSMan:\localhost\Service\Auth\Basic' -Value $true
Set-Item -Path 'WSMan:\localhost\Service\Auth\CredSSP' -Value $true

# Replace the IP address with your hostname or DNS
$hostnameOrDNS = "ec2-52-55-101-89.compute-1.amazonaws.com"
$cert = New-SelfSignedCertificate -DnsName $hostnameOrDNS -CertStoreLocation "cert:\LocalMachine\My"
$listenerParams = @{
    Address = '*'
    Transport = 'HTTPS'
    Hostname = $hostnameOrDNS
    CertificateThumbprint = $cert.Thumbprint
}
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@$listenerParams"

# Create a firewall rule to allow WinRM HTTPS inbound
New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow

# Configure trusted hosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Allow Local Account Token Filter Policy
New-ItemProperty -Name LocalAccountTokenFilterPolicy -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -PropertyType DWord -Value 1 -Force

# Set Execution Policy
Set-ExecutionPolicy Unrestricted -Force

# Restart WinRM service
Restart-Service WinRM

# Verify WinRM listener configuration
winrm enumerate winrm/config/Listener

Set-Item WSMan:\localhost\Service\auth\Basic $true
winrm get winrm/config
New-SelfSignedCertificate -DnsName "ec2-52-55-101-89.compute-1.amazonaws.com" -CertStoreLocation Cert:\LocalMachine\My



Step1: Create Certificate
New-SelfSignedCertificate -DnsName "DNS Name" -CertStoreLocation Cert:\LocalMachine\My

Step2:
Whitelist port 5985(winrm-http) and 5986(winrm-https) in the security group of the the windows server.

Step3: Create HTTPS Listener
winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname="ec2-52-55-101-89.compute-1.amazonaws.com"; CertificateThumbprint="92DCCC2D346B0DDCD86DD50DEB8B7DFB1B172A4A"}'


Step4:Add  new firewall rule for 5986

netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986


Step5: Check the listener and make sure https listener is there.
winrm e winrm/config/Listener

Check The Service
winrm get winrm/config
Make sure the Basic Auth is set to true, if not then execute below commands.
Set-Item -Force WSMan:\localhost\Service\auth\Basic $true


******************************************************************


[mmanoj@project308 ansible]$ ansible-playbook -i inventory_file.ini git.yml -vvvv
ansible-playbook [core 2.15.6]
  config file = /home/mmanoj/projects/devops-assessment-1/ansible/ansible.cfg
  configured module search path = ['/home/mmanoj/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/mmanoj/.local/lib/python3.9/site-packages/ansible
  ansible collection location = /home/mmanoj/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/mmanoj/.local/bin/ansible-playbook
  python version = 3.9.18 (main, Sep  7 2023, 00:00:00) [GCC 11.4.1 20230605 (Red Hat 11.4.1-2)] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
Using /home/mmanoj/projects/devops-assessment-1/ansible/ansible.cfg as config file
setting up inventory plugins
Loading collection ansible.builtin from 
host_list declined parsing /home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini as it did not pass its verify_file() method
script declined parsing /home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini as it did not pass its verify_file() method
auto declined parsing /home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini as it did not pass its verify_file() method
yaml declined parsing /home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini as it did not pass its verify_file() method
Parsed /home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini inventory source with ini plugin
redirecting (type: modules) ansible.builtin.win_file to ansible.windows.win_file
Loading collection ansible.windows from /home/mmanoj/.local/lib/python3.9/site-packages/ansible_collections/ansible/windows
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
Loading callback plugin default of type stdout, v2.0 from /home/mmanoj/.local/lib/python3.9/site-packages/ansible/plugins/callback/default.py
Skipping callback 'default', as we already have a stdout callback.
Skipping callback 'minimal', as we already have a stdout callback.
Skipping callback 'oneline', as we already have a stdout callback.

PLAYBOOK: git.yml ****************************************************************************************************************************************************************************************************************************
Positional arguments: git.yml
verbosity: 4
connection: winrm
timeout: 10
become_method: sudo
tags: ('all',)
inventory: ('/home/mmanoj/projects/devops-assessment-1/ansible/inventory_file.ini',)
forks: 5
1 plays in git.yml

PLAY [Clone Private Git Repository on Windows] ***********************************************************************************************************************************************************************************************

TASK [Ensure temporary folder exists] ********************************************************************************************************************************************************************************************************
task path: /home/mmanoj/projects/devops-assessment-1/ansible/git.yml:15
redirecting (type: modules) ansible.builtin.win_file to ansible.windows.win_file
redirecting (type: modules) ansible.builtin.win_file to ansible.windows.win_file
Using module file /home/mmanoj/.local/lib/python3.9/site-packages/ansible_collections/ansible/windows/plugins/modules/win_file.ps1
Pipelining is enabled.
<52.55.101.89> ESTABLISH WINRM CONNECTION FOR USER: Administrator on PORT 5986 TO 52.55.101.89
EXEC (via pipeline wrapper)
changed: [52.55.101.89] => {
    "changed": true
}

TASK [Clone private Git repository] **********************************************************************************************************************************************************************************************************
task path: /home/mmanoj/projects/devops-assessment-1/ansible/git.yml:19
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
Using module file /home/mmanoj/.local/lib/python3.9/site-packages/ansible_collections/ansible/windows/plugins/modules/win_shell.ps1
Pipelining is enabled.
<52.55.101.89> ESTABLISH WINRM CONNECTION FOR USER: Administrator on PORT 5986 TO 52.55.101.89
EXEC (via pipeline wrapper)
changed: [52.55.101.89] => {
    "changed": true,
    "cmd": "# if (Test-Path -Path \"C:\\temp\\225\") {\n#     Remove-Item -Path \"C:\\temp\\225\" -Recurse -Force\n# }\n    git clone \"https://ghp_Cg1b9id9ewKSNIL2EXkO7@github.com/movvamanoj/win-powershell.git\" \"C:\\temp\\225\"",
    "delta": "0:00:01.859372",
    "end": "2023-12-01 18:56:13.232694",
    "rc": 0,
    "start": "2023-12-01 18:56:11.373322",
    "stderr": "Cloning into 'C:\\temp\\225'...\n",
    "stderr_lines": [
        "Cloning into 'C:\\temp\\225'..."
    ],
    "stdout": "",
    "stdout_lines": []
}

TASK [Copy win-ebs.ps1 to temp] **************************************************************************************************************************************************************************************************************
task path: /home/mmanoj/projects/devops-assessment-1/ansible/git.yml:28
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
Using module file /home/mmanoj/.local/lib/python3.9/site-packages/ansible_collections/ansible/windows/plugins/modules/win_shell.ps1
Pipelining is enabled.
<52.55.101.89> ESTABLISH WINRM CONNECTION FOR USER: Administrator on PORT 5986 TO 52.55.101.89
EXEC (via pipeline wrapper)
changed: [52.55.101.89] => {
    "changed": true,
    "cmd": "Copy-Item -Path \"C:\\temp\\225/ansible/win-ebs.ps1\" -Destination \"C:\\temp\\225\" -Force",
    "delta": "0:00:00.459105",
    "end": "2023-12-01 18:56:17.452737",
    "rc": 0,
    "start": "2023-12-01 18:56:16.993632",
    "stderr": "",
    "stderr_lines": [],
    "stdout": "",
    "stdout_lines": []
}

TASK [Execute PowerShell script] *************************************************************************************************************************************************************************************************************
task path: /home/mmanoj/projects/devops-assessment-1/ansible/git.yml:38
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
redirecting (type: modules) ansible.builtin.win_shell to ansible.windows.win_shell
Using module file /home/mmanoj/.local/lib/python3.9/site-packages/ansible_collections/ansible/windows/plugins/modules/win_shell.ps1
Pipelining is enabled.
<52.55.101.89> ESTABLISH WINRM CONNECTION FOR USER: Administrator on PORT 5986 TO 52.55.101.89
EXEC (via pipeline wrapper)
changed: [52.55.101.89] => {
    "changed": true,
    "cmd": "Set-ExecutionPolicy Bypass -Scope Process -Force\n. \"C:\\temp\\225/win-ebs.ps1\"",
    "delta": "0:00:13.281689",
    "end": "2023-12-01 18:56:34.549590",
    "rc": 0,
    "start": "2023-12-01 18:56:21.267901",
    "stderr": "",
    "stderr_lines": [],
    "stdout": "Disk 1 is already initialized. Skipping initialization.\n\r\n\r\n   DiskPath: \\\\?\\scsi#disk&ven_aws&prod_pvdisk#5&445a993&0&000500#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}\r\n\r\nPartitionNumber  DriveLetter Offset                                        Size Type                                   \r\n---------------  ----------- ------                                        ---- ----                                   \r\n2                P           16777216                                   4.98 GB Basic                                  \r\nPartition on Disk 1 created with drive letter P.\n\r\nObjectId             : {1}\\\\EC2AMAZ-Q2LT6T9\\root/Microsoft/Windows/Storage/Providers_v2\\WSP_Volume.ObjectId=\"{f5c4184b-\r\n                       8f94-11ee-ba4d-806e6f6e6963}:VO:\\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\\"\r\nPassThroughClass     : \r\nPassThroughIds       : \r\nPassThroughNamespace : \r\nPassThroughServer    : \r\nUniqueId             : \\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\\r\nAllocationUnitSize   : 65536\r\nDedupMode            : NotAvailable\r\nDriveLetter          : P\r\nDriveType            : Fixed\r\nFileSystem           : NTFS\r\nFileSystemLabel      : SC1CALLS\r\nFileSystemType       : NTFS\r\nHealthStatus         : Healthy\r\nOperationalStatus    : OK\r\nPath                 : \\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\\r\nSize                 : 5350817792\r\nSizeRemaining        : 5324865536\r\nPSComputerName       : \r\n\r\n\r\n\r\n",
    "stdout_lines": [
        "Disk 1 is already initialized. Skipping initialization.",
        "",
        "",
        "   DiskPath: \\\\?\\scsi#disk&ven_aws&prod_pvdisk#5&445a993&0&000500#{53f56307-b6bf-11d0-94f2-00a0c91efb8b}",
        "",
        "PartitionNumber  DriveLetter Offset                                        Size Type                                   ",
        "---------------  ----------- ------                                        ---- ----                                   ",
        "2                P           16777216                                   4.98 GB Basic                                  ",
        "Partition on Disk 1 created with drive letter P.",
        "",
        "ObjectId             : {1}\\\\EC2AMAZ-Q2LT6T9\\root/Microsoft/Windows/Storage/Providers_v2\\WSP_Volume.ObjectId=\"{f5c4184b-",
        "                       8f94-11ee-ba4d-806e6f6e6963}:VO:\\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\\"",
        "PassThroughClass     : ",
        "PassThroughIds       : ",
        "PassThroughNamespace : ",
        "PassThroughServer    : ",
        "UniqueId             : \\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\",
        "AllocationUnitSize   : 65536",
        "DedupMode            : NotAvailable",
        "DriveLetter          : P",
        "DriveType            : Fixed",
        "FileSystem           : NTFS",
        "FileSystemLabel      : SC1CALLS",
        "FileSystemType       : NTFS",
        "HealthStatus         : Healthy",
        "OperationalStatus    : OK",
        "Path                 : \\\\?\\Volume{e377f39c-311b-4f23-b516-b8cf2c19d7d6}\\",
        "Size                 : 5350817792",
        "SizeRemaining        : 5324865536",
        "PSComputerName       : ",
        "",
        "",
        ""
    ]
}

PLAY RECAP ***********************************************************************************************************************************************************************************************************************************
52.55.101.89               : ok=4    changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[mmanoj@project308 ansible]$ 

