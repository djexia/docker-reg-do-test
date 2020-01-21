NAMESPACE=default
DOMAIN=jexia.app
FQDN=do-testing-echo1.${DOMAIN}
SHELL=bash
TOKEN=$(shell pass t/do.rw)


A list of things you can make:
	@grep : Makefile | grep -v http | cut -d: -f1
	@echo
	@echo USAGE make [get_files, infra, service]
	@echo
	@echo USAGE \"make service\" will do everything
	@echo






prereq:
	wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml
	wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml
	wget https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

cheznous:
	kubectl create namespace ingress-nginx
	kubectl create namespace cert-manager

	kubectl apply -f cheznous.lb.yaml
	kubectl apply -f mandatory.yaml

	kubectl apply --validate=false -f cert-manager.yaml

	kubectl apply -f  01_echo.yaml
	kubectl apply -f  04_echo.yaml
	kubectl apply -f  05_echo.yaml


scrapit:
	kubectl delete -f cheznous.lb.yaml
	kubectl delete -f mandatory.yaml

	kubectl delete --validate=false -f cert-manager.yaml

	kubectl delete -f  01_echo.yaml
	kubectl delete -f  04_echo.yaml
	kubectl delete -f  05_echo.yaml




status:
	kubectl get all --all-namespaces
	#kubectl get secrets                    --all-namespaces || echo not present
	#kubectl get customresourcedefinitions  --all-namespaces || echo not present
	#kubectl get configmaps                 --all-namespaces
	helm ls
	kubectl get ClusterIssuer              --all-namespaces || echo not present
	kubectl get ingress                    --all-namespaces || echo not present
	kubectl get certificate                --all-namespaces || echo not present
	kubectl get certificate  -n ${NAMESPACE} -o json | jq .items[].status.conditions[].message

cloud-generic.yaml:
	wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/provider/cloud-generic.yaml

mandatory.yaml:
	wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.26.1/deploy/static/mandatory.yaml

cert-manager.yaml:
	wget https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml

ingress:  cloud-generic.yaml mandatory.yaml
	kubectl create namespace ingress-nginx || echo ingress-nginx already created

	kubectl apply -f cloud-generic.yaml
	kubectl apply -f mandatory.yaml

cert-manager: cert-manager.yaml
	kubectl create namespace cert-manager  || echo cert-manager already created
	kubectl apply --validate=false -f cert-manager.yaml
	kubectl get pods --namespace cert-manager

dns:
	@echo if this fails you need to add helm to your local repo
	helm install external-dns  helm/stable/external-dns -f externaldns-values.yaml || echo external-dns installed

delete_all: delete_configs
	helm delete external-dns  || echo external-dns deleted
	kubectl delete -f cloud-generic.yaml || echo cloud-generic deleted
	kubectl delete -f mandatory.yaml     || echo mandatory deleted
	kubectl delete -f cert-manager.yaml  || echo cert-manager deleted
	kubectl delete namespace mytest          || echo mytest deleted
	kubectl delete namespace cert-manager    || echo  cert-manager deleted
	kubectl delete namespace ingress-nginx   || echo ingress-nginx deleted

delete_echo:
	kubectl delete -f 01_echo.yaml -n ${NAMESPACE} || echo not present
	#kubectl delete -f 02_echo.yaml -n ${NAMESPACE} || echo not present
	#kubectl delete -f 03_echo.yaml  || echo not present
	kubectl delete -f 04_echo.yaml  || echo not present
	kubectl delete -f 05_echo.yaml -n ${NAMESPACE} || echo not present

delete_configs: delete_echo
	kubectl delete configmaps cert-manager-cainjector-leader-election -n kube-system || echo not present
	kubectl delete configmaps cert-manager-cainjector-leader-election-core -n kube-system || echo not present
	kubectl delete configmaps cert-manager-controller -n kube-system || echo not present
	kubectl delete secrets letsencrypt-staging -n default || echo not present
	kubectl delete secrets letsencrypt-staging -n cert-manager || echo not present

echo:
	kubectl apply -f 01_echo.yaml -n ${NAMESPACE}
	#kubectl apply -f 02_echo.yaml -n ${NAMESPACE} # only used to test ingress
	#kubectl apply -f 03_echo.yaml  # This is just to test if the cert-manager is working
	kubectl apply -f 04_echo.yaml  # staging_issuer.yaml
	kubectl apply -f 05_echo.yaml -n ${NAMESPACE}

test:
	echo hello | openssl s_client  -servername ${FQDN} -connect ${FQDN}:443 2>/dev/null | openssl x509  -noout -subject -issuer || echo '\n'
	curl https://${FQDN} || 	echo '\n'
	wget --save-headers -O- ${FQDN} || 	echo '\n'
	kubectl get certificate  -n ${NAMESPACE} -o json | jq .items[].status.conditions[].message

get_files: cloud-generic.yaml mandatory.yaml cert-manager.yaml

infra: ingress cert-manager dns

service:   infra echo

config:
	perl -pi -e "s/EMAIL.com/${EMAIL}/g"       0*.yaml
	perl -pi -e "s/example.com/${DOMAIN}/g"            0*.yaml externaldns-values.yaml
	perl -pi -e "s/\<\<YOUR TOKEN HERE\>\>/${TOKEN}/g" externaldns-values.yaml

anon:
	perl -pi -e "s/${EMAIL}/EMAIL.com/g"    0*.yaml
	perl -pi -e "s/${DOMAIN}/example.com/g"        0*.yaml externaldns-values.yaml
	perl -pi -e "s/${TOKEN}/<<YOUR TOKEN HERE>>/g" externaldns-values.yaml
