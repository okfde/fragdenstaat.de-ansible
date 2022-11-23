# Ansible FragDenStaat.de

Based on [ansible-django-stack](https://github.com/jcalazan/ansible-django-stack).

Ansible to deploy FragDenStaat.de - a Django app with Postgres database, ElasticSearch search engine, Celery+RabbitMQ background queue, Redis server and a full email server with postfix and dovecot on Ubuntu 22.04.


## Install this repo

```bash
python -m venv ansible-env
source ansible-env/bin/activate
pip install -r requirements.txt
```

## Configure your SSH user

Copy `playbooks/local_config.yml.example` to `playbooks/local_config.yml` and set your SSH username.

## Deploy FragDenStaat.de

Run this to deploy FragDenStaat.de

    ansible-playbook playbooks/fragdenstaat.de.yml -v

There are tags available:

- `deploy-web` – updates app and reloads app server
- `deploy-backend` – like `deploy-web` but also restarts workers
- `deploy-frontend` - rebuilds frontend and reloads app server
- `nginx` – rebuilds nginx config and reload nginx

Use like this:

```
ansible-playbook fragdenstaat.de.yml -v -t deploy-web -t deploy-frontend
```

## Secrets management

Secrets are managed with `git-crypt` and `ansible-vault`.

Unlock key file after cloning the repo:

```
git-crypt unlock
```

Edit production secrets:

```
ansible-vault edit group_vars/all/secrets.yml
```

## Add VPN clients

Make sure vpn server is setup.

Copy example client configuration

```
cp env_vars/vpnclients.yml.example env_vars/vpnclients.yml
```

Setup VPN server:
```
ansible-playbook -v playbooks/vpnserver.yml
```

Store public key in host variables file in `host_vars/` under the key `host_data.wg_publickey`

Run this script to add a client:

```
ansible-playbook -v playbooks/vpn_add_client.yml
```

After it's done, a client configuration file is in your local directory and the public key has been recorded in `env_vars/vpnclients.yml`.

Update the peers on the server:

```
ansible-playbook -v playbooks/vpnserver.yml
```
