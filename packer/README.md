# Building AMI's for Jenkins (Master & Slave nodes)

```bash
packer validate ami.jenkins_master.json
packer build ami.jenkins_master.json
```

```bash
packer validate ami.jenkins_slave.json
packer build ami.jenkins_slave.json
```
