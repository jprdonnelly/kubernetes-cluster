# Keycloak on Kubernetes
Simple notes for deploying customized realm and keycloak into K8s

### Pre-requisites

Running K8s with Ingress (not the service deployed by QSEoK)

### Create the secret

Run the following commands to create the "idp" namespace and upload the secret (the entire realm.json file)
```bash
kubectl create namespace idp
```
This command below utilizes a "realm.json" file located in current path.
```bash
kubectl create secret --namespace idp generic realm-secret --from-file=./realm.json
```

Create namespace and deploy nginx-ingress

```bash
kubectl create namespace ingress
```

```bash
helm install -n ingress --namespace ingress stable/nginx-ingress
 ```

### Deploy Keycloak

```bash
helm install -n keycloak --namespace idp codecentric/keycloak -f ./keycloak-values.yaml
```
Update /etc/hosts to point "keycloak.local" to 192.168.205.91 (second address dealt from MetalLB)

##### Licensing

[Apache License, Version 2.0](http://opensource.org/licenses/Apache-2.0).
