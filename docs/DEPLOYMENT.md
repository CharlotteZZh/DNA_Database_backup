# Deploying MethylProphet DB at Duke Health

The app runs on the Duke Kubernetes Service (DKSO, Red Hat OpenShift), cluster
`dksoprod-nc1`, namespace `inferred-dna-methylation-db`.

| | |
|---|---|
| GitLab project | https://gitlab.dhe.duke.edu/cz280/dreamlanddb |
| Pipelines | https://gitlab.dhe.duke.edu/cz280/dreamlanddb/-/pipelines |
| Internal URL (Duke network/VPN only) | https://methylprophetdb-inferred-dna-methylation-db.apps.dksoprod-nc1.dhe.duke.edu |
| Planned public URL | https://dreamlanddb.duhs.duke.edu |
| OpenShift console | https://console-openshift-console.apps.dksoprod-nc1.dhe.duke.edu |
| Namespace admins | jd495, cz280 |

## How a deploy works

Every push to `main` on the GitLab remote runs `.gitlab-ci.yml`:

1. **build**: builds the image from `Dockerfile` (DHTS kaniko template) and pushes
   it to the GitLab registry tagged with the commit SHA.
2. **scan**: DHTS Twistlock image scan (`.docker_scan`). A failed scan blocks the deploy.
3. **tag**: also tags the image `latest`.
4. **deploy**: `helm upgrade --install` of `chart/` into the namespace. If the app
   does not become ready within 5 minutes, the job prints the app log and cluster
   events and fails.
5. **decom** (manual button): removes the deployment.

```
git push gitlab main     # deploy to Duke
git push origin main     # (optional) keep GitHub in sync
```

GitLab settings the pipeline relies on:

- **Settings → CI/CD → Variables**: `HELM_TOKEN` (masked, protected), the
  `helm-deployer` token from the namespace email.
- **Settings → Repository → Deploy tokens**: `gitlab-deploy-token` with `read_registry`.

## Making the site public

Per the DHTS guide *Vanity URLs in DKSO → External Vanity URL*, four ServiceNow
requests are needed, **in this order**. Submit each from
https://duke.service-now.com (search the catalog for the form name).

### 1. SSL certificate

Form: **Request or Manage Duke Health SSL Certificates**

- Common name: `dreamlanddb.duhs.duke.edu`
- Purpose: public web application (DreamlandDB research database), hosted on
  DKSO `dksoprod-nc1`, namespace `inferred-dna-methylation-db`

If the form asks for a CSR, generate one locally. The `secrets/` folder is ignored by
git and never leaves your machine:

```
mkdir -p secrets
openssl req -new -newkey rsa:2048 -nodes \
  -keyout secrets/dreamlanddb.key \
  -out secrets/dreamlanddb.csr \
  -subj "/C=US/ST=North Carolina/L=Durham/O=Duke University/CN=dreamlanddb.duhs.duke.edu"
```

When the certificate is issued, download **"Certificate (w/ issuer after), PEM
encoded"** (full chain).

### 2. Static IP in the DMZ

Form: **Request a new Static IP Address**

| Field | Value |
|---|---|
| Request Action | Request |
| Request Type | Application |
| DNS | `dreamlanddb.duhs.duke.edu` |
| IP | TBD |
| VRF | dmz |
| Location | dksoprod-nc1 (NC1 Data Center 152.16.0.0/24 (NC-1 G4 DMZ)) |
| LCR | `inferred-dna-methylation-db` |
| Reason | Public vanity URL for DreamlandDB (DKSO namespace `inferred-dna-methylation-db`) |

Note the static IP you are assigned; steps 3 and 4 need it.

### 3. Firewall rule (2-3 business days for security approval)

Form: **Request a Firewall Rule Change**

Attach the **Sample Firewall Request Spreadsheet for Vanity URLs** (download it from
ServiceNow) filled in as:

- Source: Any (internet)
- Destination: the static IP from step 2
- Ports: TCP 443 (and TCP 80, which redirects to 443)
- Description: public HTTPS access to DreamlandDB at `dreamlanddb.duhs.duke.edu`

### 4. Load balancer proxy

Form: **Request Load Balancer/Proxy Change**

| Field | Value |
|---|---|
| DNS name | `dreamlanddb.duhs.duke.edu` |
| VIP IP (Forward Facing) | the static IP from step 2 |
| Backend Servers (FQDN)(Pool Member) | `10.19.212.10` (NetScaler proxy VIP for dksoprod-nc1 ingress) |
| Data center | NC1 |
| TCP/UDP Service Port | 443 (and 80) |

### 5. Turn on the public route (in GitLab, after the certificate is issued)

Add under **Settings → CI/CD → Variables** (all **Protected**):

| Key | Type | Value |
|---|---|---|
| `VANITY_HOST` | Variable | `dreamlanddb.duhs.duke.edu` |
| `VANITY_TLS_CERT` | **File** | full-chain PEM certificate |
| `VANITY_TLS_KEY` | **File** | private key (`secrets/dreamlanddb.key`) |

Then rerun the latest pipeline (or push any commit). The deploy job creates a second
OpenShift Route for the public hostname and prints `Public URL https://...`.

The certificate has to be renewed before it expires. Update `VANITY_TLS_CERT` and
rerun the pipeline. (DHTS also offers automated renewal through cert-manager; see
*SSL Automation at Duke Health* in the developer guide.)

## Troubleshooting

- **Pipeline fails at deploy**: open the deploy job log. It ends with the app's R
  output and recent cluster events.
- **Scan hangs or fails with `runner_system_failure`**: the DHTS scanner is having
  problems; retry the job or ask in the DHTS DevOps Teams channel.
- **App logs**: Splunk, `index=dhe_devops source="DKSOPROD.inferred-dna-methylation-db" clusterID="dksoprod-nc1"`.
- **System libraries**: R packages are installed as prebuilt Ubuntu binaries. If a new
  package fails to load with `cannot open shared object file`, add the missing runtime
  library to the `apt-get install` line in `Dockerfile`.
