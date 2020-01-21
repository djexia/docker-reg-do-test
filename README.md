# End Goal
To build a docker registry with 1. DNS, 2. certs and 3. netfilters 4. Using S3
* [DigitalOcean cert manager doc](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes)

<hr>

## The Processes
1. Configure the configure files
    ``` bash
    make EMAIL='your\\@email' DOMAIN=yourdomain.com config
    ```
1. Create ingress infra
    ``` bash
    kubectl create namespace ingress-nginx
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml
    kubectl apply -f mandatory.yaml
    kubectl apply -f cloud-generic.yaml
    ```
1. Create cert-manager infra
    ``` bash
    #
    kubectl create namespace cert-manager  
    wget https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
    kubectl apply --validate=false -f cert-manager.yaml
    helm install external-dns  helm/stable/external-dns -f externaldns-values.yaml  
    ```
1. Create echo application
    ``` bash
    # make echo
    kubectl apply -f 01_echo.yaml -n default
    kubectl apply -f 04_echo.yaml
    #  This should create both the DNS and a cert  
    kubectl apply -f 05_echo.yaml -n default
    ```
### Test
1. Check the cert issuer
    ``` bash
    echo hello | openssl s_client  -servername ${FQDN} -connect ${FQDN}:443 2>/dev/null | openssl x509  -noout -subject -issuer || echo '\n'
    ```
1. Check cert issuer status
    ``` bash
      kubectl get certificate  -n default -o json | jq .items[].status.conditions[].message
    ```
1. Check headers with wget
    ``` bash
      wget --save-headers -O- ${FQDN} || 	echo '\n'
    ```
1. Check if app works
    ``` bash
      curl https://${FQDN} || 	echo '\n'
    ```
<hr>



## PREREQ

To run this example you will require the folloing

1. make, helm and kubectl installed
1. A working configuration for a DigitalOcean kubernetes cluster
1. An API key with rw permissions [here](https://cloud.digitalocean.com/account/api/tokens)
1. A copy of https://github.com/helm/helm/ in soft-linked in this repo as ./helm (else modify the Makefile)

##  Processes
To emulate the process used in attempting to create the stack, by typing the following you will create an echo app (not a docker registry yet)

1. Modify `externaldns-values.yaml`: Update the API key with once that has rw permissions so you can create DNS entries.
1. Automatically, fetch and install `cloud-generic.yaml` `mandatory.yaml` and `cert-manager.yaml` with this command
    ``` bash
    make infra
    ```
1. Create the echo app with DNS and cert. (or to cheat just type `make service` and build everything at once)
    ``` bash
    make echo
    ```
1. The the following to get a rather verbose out put of most of the things effected by these commands
    ``` bash
    make get
    ```

### Question: why the `|| echo`

This is just a cheap trick to allow you to run the commands several times.


### The Processes ( long form equivalent )
The following is the effect of typing those two commands above  
``` bash
# make infra
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml
kubectl create namespace ingress-nginx  
kubectl apply -f cloud-generic.yaml
kubectl apply -f mandatory.yaml
wget https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
kubectl create namespace cert-manager   
kubectl apply --validate=false -f cert-manager.yaml
kubectl get pods --namespace cert-manager
helm install external-dns  helm/stable/external-dns -f externaldns-values.yaml  

# make echo
kubectl apply -f 01_echo.yaml -n default
kubectl apply -f 02_echo.yaml -n default
kubectl apply -f 04_echo.yaml   
kubectl apply -f 05_echo.yaml -n default
echo -e "\n\nWARNING THE NEXT LINE SHOULD FAIL\n\tBut once the cert has been generated manually test"
curl https://do-testing-echo1.${DOMAIN}
```

### To debug
``` bash
	# Get the apparent status of the cert
	kubectl get certificate  -n ${NAMESPACE} -o json | jq .items[].status.conditions[].message
	# Get the subject and issuer from the cert
	echo hello | openssl s_client  -servername ${FQDN} -connect ${FQDN}:443 2>/dev/null | openssl x509  -noout -subject -issuer || echo '\n'
	# check if the cert works with the name
	curl https://${FQDN}  
	# Check headers, kinda redundant
	wget --save-headers -O- ${FQDN}  
```
