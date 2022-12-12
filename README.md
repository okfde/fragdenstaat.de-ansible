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

Secrets are managed with `ansible-vault`.

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


## Current FragDenStaat.de architecture

```mermaid
flowchart TB
    subgraph brooke
        brookessh[[SSH access]]
        appserver[Gunicorn/Uvicorn]
        brookenginx[nginx frontend server]
        appworker[Celery Worker]
        wireguard[Wireguard VPN]
        db[Postgres Database]
        postfix["Postfix (SMTP)"]
        dovecot["Dovecot (IMAP)"]
        redis[Redis Broker]
        memcached[memcached Cache]
        rabbitmq[RabbitMQ Queue]
        brookessd[(SSD storage)]
    end
    subgraph schoch
        schochssh[[SSH access]]
        schochnginx[nginx frontend server]
        schochnginx-->nfs[NFS server]
        schochnginx--authenticating access --> appserver
        nfs-->schochhdd[(HDD storage)]
    end
    subgraph fds-es01
        fdses01ssh[[SSH access]]
        appserver-->elasticsearch[Elasticsearch server]
        elasticsearch-->fdses01ssd[(SSD storage)]
    end
    subgraph backupstorage
        backup[(duplicity backup)]
    end
    subgraph brooke
        brookenginx-->appserver
        brookenginx-->brookessd
        appserver-->db
        nfsmount-->nfs
        appserver-->nfsmount
        appserver-->rabbitmq
        appserver-->memcached
        appserver-- mail download -->dovecot
        appserver-- Websocket Channel Layer Group -->redis
        rabbitmq<-->appworker
        postfix-- check deliverability -->db
        db-->brookessd
        postfix-->brookessd
        dovecot-->brookessd

        appworker-->db
        appworker-->elasticsearch
        appworker-->nfsmount
        appworker-- fetch mail -->dovecot
        appworker-- Mail Log reading -->brookessd

        wireguard-->brookenginx

        cronbackup[Cron Backup Task]
        brookessd-- mail storage --> cronbackup
        brookessd-- database dumps --> cronbackup
        nfsmount-- media files --> cronbackup
        cronbackup --> backup
    end
    subgraph schaar
        schaarssh[[SSH access]]
        fdsbot[Slack fdsbot]-->brookessh
        schaarnginx
        db-->dbreplica[Postgres Database Replica]
    end
    subgraph schaar
        schaarnginx[nginx frontend server]
        subgraph docker
            schaarnginx-->weblate
            schaarnginx-->sentry
            schaarnginx-->fds-ogimage
        end
    end
    subgraph internet
        slack([Slack])==>fdsbot
        %% fdsdev([FDS developer])==>brookessh
        %% fdsdev==>schaarssh
        %% fdsdev==>schochssh
        %% fdsdev==>fdses01ssh
        user([User])== media.frag-den-staat.de ==>schochnginx
        user== fragdenstaat.de / static.frag-den-staat.de ==>brookenginx
        user== sentry.okfn.de / ogimage.frag-den-staat.de / weblate.okfn.de ==>schaarnginx
        mailuser([Email])==>postfix
        fdsstaff([FDS staff])==>dovecot
        fdsstaff==>schaarnginx
        fdsstaff==>wireguard
    end
```
