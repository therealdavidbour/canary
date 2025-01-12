@PHONY: debug
debug:
	helm pull prometheus-community/kube-prometheus-stack && tar -xf kube-prometheus-stack*.tgz

@PHONY: dashboard
dashboard:
	helm upgrade --install \
				 --create-namespace \
				 -f ./kube-prometheus-stack/values.yaml \
				 -f ./kube-prometheus-stack/values.overrides.yaml \
				 -n kube-prometheus-stack \
				 kube-prometheus-stack \
				 ./kube-prometheus-stack

.PHONY: cluster
cluster:
	k3d cluster create practice-cluster --api-port 6550 \
									    --agents-memory 10G \
										--k3s-arg="--disable=traefik@server:0" \
										-p "80:80@loadbalancer"

.PHONY: nginx
nginx:
	helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx --create-namespace

.PHONY: router
router:
	helm upgrade --install \
				 --namespace router \
				 --create-namespace \
				 router ./router

.PHONY: blue
blue:
	helm upgrade --install \
				 --namespace blue-nginx \
				 --create-namespace \
				 blue-nginx ./blue-nginx

.PHONY: green
green:
	helm upgrade --install \
				 --namespace green-nginx \
				 --create-namespace \
				 green-nginx ./green-nginx

.PHONY: canary
canary:
	kubectl create ns nginx-blue || true && \
	kubectl create ns nginx-green || true && \
	kubectl create ns canary-bg-switch || true && \
	kubectl apply -f blue-ingress.yaml || true && \
	kubectl apply -f green-ingress.yaml || true && \
	kubectl apply -f blue-app.yaml || true && \
	kubectl apply -f green-app.yaml || true && \
	kubectl apply -f green-service.yaml || true && \
	kubectl apply -f blue-service.yaml || true

.PHONY: clean
clean:
	helm uninstall blue-nginx --namespace blue-nginx || true && \
	helm uninstall green-nginx --namespace green-nginx || true && \
	helm uninstall router --namespace router || true && \
	kubectl delete ns blue-nginx || true && \
	kubectl delete ns green-nginx || true && \
	kubectl delete ns router || true

.PHONY: clean-all
clean-all: clean
	k3d cluster delete practice-cluster
