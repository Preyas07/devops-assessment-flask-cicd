# DevOps Assessment: Flask + Docker + CI/CD (GitHub Actions & CircleCI) + Kubernetes

A tiny Flask web app with automated pipeline:
- Tests on every push
- Builds and pushes a Docker image
- (Optional) Deploys to a single-node Kubernetes (k3s) on an EC2 VM

## Repo layout
```
app/                 # Flask app
tests/               # pytest unit tests
k8s/                 # Deployment + Service manifests
.github/workflows/   # GitHub Actions pipeline
.circleci/           # CircleCI pipeline (optional)
Dockerfile
docker-compose.yml   # Local dev
```

---

## 1) Run locally (10 min)

```bash
# 1. Clone and enter
git clone <your-fork-or-repo-url>
cd devops-assessment-flask-cicd

# 2. Run tests
pip install -r requirements.txt
pytest -q

# 3. Build & run container
docker compose up --build -d
curl http://localhost:8000/          # -> Hello from CI/CD! Build: local
curl http://localhost:8000/healthz   # -> {"status":"ok"}
```

---

## 2) Push to Docker Hub via CI (15–20 min)

1. Create a **Docker Hub** repo (e.g., `hello-flask`).
2. Push this project to **GitHub** and set **GitHub Secrets**:
   - `DOCKERHUB_USERNAME` = your Docker Hub username
   - `DOCKERHUB_TOKEN` = a Docker Hub **Access Token**
   - (Optional) `KUBE_CONFIG` = base64-encoded kubeconfig (see section 3)
3. Ensure your default branch is `main`, then push.
4. GitHub Actions will:
   - run tests
   - build & push `docker.io/<user>/hello-flask:{latest, <short-sha>}`

You can do the **same** flow on **CircleCI** (optional):
- In Project Settings → Environment Variables, add:
  - `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
  - (Optional) `KUBE_CONFIG` if you want CircleCI to deploy
- The workflow runs on `main` branch only (see `.circleci/config.yml`).

---

## 3) (Optional) One-node Kubernetes on EC2 with k3s (20–30 min)

> This lets the pipeline auto-deploy to a real cluster. Cheapest path: a small Ubuntu EC2.

**On the EC2 VM (Ubuntu):**
```bash
# install k3s (single node)
curl -sfL https://get.k3s.io | sh -

# verify
sudo kubectl get nodes

# copy kubeconfig to your user and fix perms
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# IMPORTANT: change cluster server address to your EC2 public IP
# (k3s writes 127.0.0.1 by default)
PUBLIC_IP=$(curl -s ifconfig.me)
kubectl config set-cluster default --server=https://$PUBLIC_IP:6443
kubectl config view --minify
```

**Security Group rules** on the EC2 instance:
- Inbound TCP **6443** (Kubernetes API) from GitHub/CircleCI runners (0.0.0.0/0 is ok for demo, but not for prod)
- Inbound TCP **30080** (app NodePort) from your IP to view the app

**Create the `KUBE_CONFIG` secret** for CI:
```bash
# on the EC2 box
base64 -w0 ~/.kube/config
# copy the output and paste it into:
#   GitHub → Settings → Secrets and variables → Actions → New repository secret
# name: KUBE_CONFIG
```

---

## 4) Deploy via CI

When `KUBE_CONFIG` is present, the pipeline will:
- `kubectl apply -f k8s/deployment.yaml && k8s/service.yaml`
- update the Deployment image to the freshly pushed tag
- wait for rollout to finish

Then open:
```
http://<EC2_PUBLIC_IP>:30080/
http://<EC2_PUBLIC_IP>:30080/healthz
```

---

## 5) 5‑Minute Walkthrough Video Script

**0:00 – 0:30** — Intro & goal  
- “I’ll show a tiny Flask app shipped via CI/CD to Kubernetes.”

**0:30 – 1:30** — Code & tests  
- Show `app/app.py` and `tests/test_app.py`
- Run `pytest` locally (or show in CI logs)

**1:30 – 2:30** — Containerization  
- `Dockerfile` (gunicorn, port 8000)  
- `docker-compose.yml` for local run

**2:30 – 4:00** — Pipeline  
- GitHub Actions: test → build → push (→ deploy if `KUBE_CONFIG` present)  
- Mention CircleCI config that mirrors the flow

**4:00 – 5:00** — Deploy & verify  
- Show rollout logs in CI  
- Hit `/<healthz>` and root URL on `http://<EC2_IP>:30080/`  
- Wrap up with “how I’d improve this next”:
  - add IaC (Terraform) for infra
  - add Prometheus/Grafana for monitoring
  - add blue/green or canary with Argo Rollouts
  - add SAST/Trivy scans in CI

---

## Troubleshooting

- **CI can’t reach cluster**: open SG port 6443 and ensure kubeconfig `server:` uses the EC2 public IP.  
- **Pod CrashLoopBackOff**: check `kubectl logs deploy/hello-flask`.  
- **NodePort not reachable**: open 30080 in SG and verify the Service type is `NodePort`.

---

## Credits

Built for a quick DevOps assessment demo. Enjoy and customize!
