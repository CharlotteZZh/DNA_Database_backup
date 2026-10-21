# Deploying DreamlandDB at Duke Health

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

Per the DHTS guides *Vanity URLs in DKSO → External Vanity URL* and *SSL Automation
at Duke Health*, the public URL needs a static IP, a firewall rule and a load balancer
(requested through ServiceNow at https://duke.service-now.com), plus a certificate that
cert-manager gets automatically from OIT's Locksmith.

| Request | Status |
|---|---|
| Static IP in the NC1 DMZ: `dreamlanddb.duhs.duke.edu` → `152.16.3.61` | Done (Oct 2026) |
| Firewall rule, inbound TCP 443 from the internet | RITM8686642 |
| Load balancer, `152.16.3.61` → NetScaler VIP `10.19.212.10`, HTTP → HTTPS redirect | RITM8686667 |

Do **not** request a certificate through the ServiceNow SSL form. DHTS does not support
certificates installed only on the load balancer; the certificate lives in OpenShift.

### 1. Check that the network side is ready

From a machine off the Duke network and VPN:

```
curl -skv --max-time 10 https://dreamlanddb.duhs.duke.edu -o /dev/null
```

- Times out: the firewall or load balancer is not in place yet.
- HTTP 503 "Application is not available": traffic reaches OpenShift. Go on to step 2.

Locksmith checks the hostname over the internet before it issues a certificate
(http-01 challenge), so step 2 only works once this returns 503. Locksmith allows
only 3 requests per certificate per day, so do not retry over and over.

### 2. Turn on the public route

Under **Settings → CI/CD → Variables**, add `VANITY_HOST` = `dreamlanddb.duhs.duke.edu`
(Protected), then rerun the latest pipeline (or push any commit). The deploy creates:

- `chart/templates/vanity-issuer.yaml`: a cert-manager Issuer (`locksmith-issuer`) that
  registers with Locksmith using the Grouper support group
  `groups-dhts-academic-suppport-admins@duke.edu` (`vanity.issuerEmail` in
  `chart/values.yaml`; "suppport" with three p's is the real address).
- `chart/templates/vanity-route.yaml`: an edge-terminated Route for the public hostname,
  annotated `cert-manager.io/issuer: locksmith-issuer`. cert-manager requests the
  certificate and copies it into the Route.

When it works, the Grouper group receives a confirmation email and the certificate shows
up on Locksmith's cert page. cert-manager renews it about 30 days before it expires; no
manual renewal is needed.

Afterwards, add **ACME/Locksmith Auto-Renewal** to the *SSL Certificate Information*
field on the app's ServiceNow application record.

### Certificate troubleshooting

```
kubectl get issuers,certificates,certificaterequests,orders,challenges -n inferred-dna-methylation-db
kubectl describe challenges -n inferred-dna-methylation-db
```

- A pending challenge usually means Locksmith cannot reach the hostname (firewall or
  load balancer). Locksmith's ACME logs show why validation failed.
- To reissue a certificate, delete the Secret listed by `kubectl get certificates`.
- To change the notification email, delete the Issuer, change `vanity.issuerEmail` and
  redeploy.

## Troubleshooting

- **Pipeline fails at deploy**: open the deploy job log. It ends with the app's R
  output and recent cluster events.
- **Scan hangs or fails with `runner_system_failure`**: the DHTS scanner is having
  problems; retry the job or ask in the DHTS DevOps Teams channel.
- **App logs**: Splunk, `index=dhe_devops source="DKSOPROD.inferred-dna-methylation-db" clusterID="dksoprod-nc1"`.
- **System libraries**: R packages are installed as prebuilt Ubuntu binaries. If a new
  package fails to load with `cannot open shared object file`, add the missing runtime
  library to the `apt-get install` line in `Dockerfile`.
