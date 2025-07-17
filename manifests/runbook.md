
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.allowSnippetAnnotations=true


helm repo list

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

helm search repo ingress-nginx
NAME                            CHART VERSION   APP VERSION     DESCRIPTION                                       
ingress-nginx/ingress-nginx     4.13.0          1.13.0          Ingress controller for Kubernetes using NGINX a...

#####

helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.admissionWebhooks.enabled=false \
  --set controller.allowSnippetAnnotations=true

######

kubectl get all  -n ingress-nginx

NAME                                                          READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-ingress-nginx-controller-7ff7d99ff4-sx69z   1/1     Running   0          3m4s

NAME                                             TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
service/nginx-ingress-ingress-nginx-controller   LoadBalancer   10.132.141.57   172.18.255.180   80:30258/TCP,443:30615/TCP   3m4s

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-ingress-nginx-controller   1/1     1            1           3m4s

NAME                                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-ingress-nginx-controller-7ff7d99ff4   1         1         1       3m4s

######

kubectl apply -f ingress.yml 
ingress.networking.k8s.io/flextrack-ingress configured

######

kubectl logs -n ingress-nginx nginx-ingress-ingress-nginx-controller-7ff7d99ff4-sx69z

E0717 01:04:19.904232      14 store.go:941] annotation group ServerSnippet contains risky annotation based on ingress configuration

######

kubectl get configmap -n ingress-nginx
NAME                                     DATA   AGE
kube-root-ca.crt                         1      9h
nginx-ingress-ingress-nginx-controller   1      7m34s

######

kubectl edit configmap nginx-ingress-ingress-nginx-controller -n ingress-nginx

apiVersion: v1
data:
  allow-snippet-annotations: "true"
  annotations-risk-level: Critical  # add this line
kind: ConfigMap

######

kubectl rollout restart deployment/nginx-ingress-ingress-nginx-controller -n ingress-nginx
deployment.apps/nginx-ingress-ingress-nginx-controller restarted

######

kubectl get all -n ingress-nginx
NAME                                                          READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-ingress-nginx-controller-78847d4c77-w4fcp   1/1     Running   0          2m13s

NAME                                             TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
service/nginx-ingress-ingress-nginx-controller   LoadBalancer   10.132.141.57   172.18.255.180   80:30258/TCP,443:30615/TCP   12m

NAME                                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-ingress-nginx-controller   1/1     1            1           12m

NAME                                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-ingress-nginx-controller-78847d4c77   1         1         1       2m13s
replicaset.apps/nginx-ingress-ingress-nginx-controller-7ff7d99ff4   0         0         0       12m

######

lua block to handle rate limiting & throttling & user will first encounter this

######

kubectl apply -f ingress.yml 
ingress.networking.k8s.io/flextrack-ingress configured

######

curl http://172.18.255.180/throttle/v1/ratelimit
{"status":true}

curl http://172.18.255.180/throttle/v1/ratelimit
{"error":"Rate limit exceeded."}

curl http://172.18.255.180/throttle/v1/healthcheck
{"status":true,"time":"2025-07-17T01:42:37.194006789Z"}

######

kubectl get ingress
NAME                CLASS   HOSTS   ADDRESS          PORTS   AGE
flextrack-ingress   nginx   *       172.18.255.180   80      9h

######

kubectl apply -f ingress-hostbased.yml

######

sudo vim /etc/hosts

172.18.255.180 flextrack.com

######

curl http://flextrack.com/throttle/v1/ratelimit
{"status":true}

###### check the ingress in ingress controller deployment 

kubectl get deployment.apps/nginx-ingress-ingress-nginx-controller -n ingress-nginx -o json | jq .spec.template.spec.containers[0].args[4]
"--ingress-class=nginx"

###### 

ingress-hostbased.yml

spec:
  ingressClassName: "nginx" # Ingress Contoller --> Ingress Class --> Ingress Resource

###### secure ingrss configuration #########3

./certs.sh 
Directory './nginx-certs' not found — creating it now.
Directory './nginx-certs' created.
Generating self-signed certificate and key in ./nginx-certs
.+.+......+..+......+.......+..+.+..+...+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.....+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*..+...+..+.............+...+.....+...+......+...+..................+...+.+......+.........+...+..+......+.......+..+...+.+.........+..+...+......+....+...+.................+......+.+...........+.........+.+.....+...+.......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
.+............+...........+...+.......+.................+.+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*.+..+.+.....+...+.......+...+..+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*...+...+...+............+....+.....+....+..+.........+....+......+.....+...+......+.+...+...+.....+....+......+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----
Generated ssl certificates successfully.

###### create tls secret 

./secret-generate.sh

###### create secure ingress

kubectl apply -f ingress-tls.yml

kubectl rollout restart deployment.apps/nginx-ingress-ingress-nginx-controller -n ingress-nginx

###### curl to secure ingress endpoint 

curl --cert nginx-ingress.crt --key nginx-ingress.key  https://flextrack.com/throttle/v1/ratelimit -k
{"status":true}

######