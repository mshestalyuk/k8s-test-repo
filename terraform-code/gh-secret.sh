kubectl create secret generic github-repo-creds \
  -n argocd \
  --from-file=sshPrivateKey=$HOME/.ssh/argocd-github \
  --from-literal=type=git \
  --from-literal=url=git@github.com:mshestalyuk/k8s-test-repo.git
  
kubectl label secret github-repo-creds \
  -n argocd \
  argocd.argoproj.io/secret-type=repository
