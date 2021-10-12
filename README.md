# Ansible FragDenStaat.de

Based on [ansible-django-stack](https://github.com/jcalazan/ansible-django-stack).

Ansible to deploy FragDenStaat.de - a Django app with Postgres database, ElasticSearch search engine, Celery+RabbitMQ background queue, Redis server and a full email server with postfix and dovecot on Ubuntu 20.04.


## Install this repo

```bash
python -m venv ansible-env
source ansible-env/bin/activate
pip install -r requirements.txt
```

## Configure your SSH user

Copy `local_config.yml.example` to `local_config.yml` and set your SSH username.

## Deploy FragDenStaat.de

Run this to deploy FragDenStaat.de

    ansible-playbook fragdenstaat.de.yml -v

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
