# Terraform
==============

##### Example of IaC

## Run
```
terraform init
```
Then:
```
terraform validate
```
Then:
```
terraform apply -target ""
```
Then:
```
terraform apply 
```

## Check
As a result it should return webpage with `Server: <hostname>` as a proof that loadbalancer works fine.
After last apply there should be dns URL of loadbalancer.

## Warning
First connection to loadbalancer may last a little bit longer.

