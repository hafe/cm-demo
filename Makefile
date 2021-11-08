CM_VERSION="v1.6.1"

all: app

/usr/local/bin/kind:
	curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
	chmod +x ./kind
	sudo mv ./kind /usr/local/bin/kind

/usr/local/bin/cmctl:
	OS=$$(go env GOOS); ARCH=$$(go env GOARCH); curl -L -o cmctl.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/cmctl-$$OS-$$ARCH.tar.gz
	tar xzf cmctl.tar.gz
	sudo mv cmctl /usr/local/bin
	rm cmctl.tar.gz

/usr/local/bin/helm:
	curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

.PHONY: cmctl
cmctl: /usr/local/bin/cmctl

.PHONY: helm
helm: /usr/local/bin/helm

.PHONY: kind
kind: /usr/local/bin/kind

.PHONY: kubectl
kubectl: /usr/local/bin/kubectl

.PHONY: install
install: cmctl kind helm kubectl

.PHONY: force-install
force-install: /usr/local/bin/cmctl /usr/local/bin/helm /usr/local/bin/kind /usr/local/bin/kind

.PHONY: cluster
cluster:
	@echo ">>> Creating kind cluster 'cm-demo' (if needed)"
	@kind get clusters -q | grep -q cm-demo || kind create cluster --wait=4m --name="cm-demo" --config=config/kind/config.yaml
	@echo ">>> done"

.PHONY: helm-repo
helm-repos:
	@echo ">>> Adding helm repo jetstack"
	@helm repo add jetstack https://charts.jetstack.io > /dev/null
	@echo ">>> done"

.PHONY: cert-manager
cert-manager: cluster helm helm-repo
	@echo ">>> Installing cert-manager using helm"
	@helm status -n cert-manager cert-manager || helm upgrade --install --wait \
		cert-manager jetstack/cert-manager \
		--namespace cert-manager \
		--create-namespace \
		--version $(CM_VERSION) \
		--set installCRDs=true
	@echo ">>> done"

.PHONY: cluster-ca
cluster-ca: cert-manager
	@echo ">>> Creating cluster CA"
	@kubectl apply -f config/cm-bootstrap.yaml
	@echo ">>> done"

.PHONY: cmctl-inspect
cmctl-inspect:
	@cmctl inspect secret mycert

.PHONY: cert-inspect
cert-inspect:
	@echo ">>> Inspecting certificate from inside container"
	$(eval name=$(shell kubectl get pod -l app=nginx -ojson | jq -r .items[0].metadata.name))
	@kubectl exec -it ${name} -- openssl x509 -text -in /mnt/mycert/tls.crt | grep -A 10 ^Certificate
	@echo ">>> done"

.PHONY: app
app: cluster-ca
	@echo ">>> Deploying nginx app"
	kubectl apply -f ./config/nginx
	kubectl wait --timeout=60s --for=condition=ready pod -l app=nginx
	@echo ">>> done"
	make cert-inspect

.PHONY: renew
cert-renew: cmctl
	@make cert-inspect
	@echo ">>> Renewing certificate"
	@cmctl renew mycert
	@echo ">>> done"
	sleep 30
	@make cert-inspect
	@echo ">>> done"

.PHONY: clean
clean:
	@echo ">>> Deleting cluster 'cm-demo'"
	kind delete clusters cm-demo
	@echo ">>> done"
