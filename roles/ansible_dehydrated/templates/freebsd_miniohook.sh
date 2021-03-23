#!/usr/bin/env/sh
cp /usr/local/etc/dehydrated/certs/backupofden.libcom.de/fullchain.pem /usr/local/etc/dehydrated/certs/backupofden.libcom.de/public.crt
cp /usr/local/etc/dehydrated/certs/backupofden.libcom.de/privkey.pem /usr/local/etc/dehydrated/certs/backupofden.libcom.de/private.key
chown minio:minio /usr/local/etc/dehydrated/certs/backupofden.libcom.de/public.crt
chown minio:minio /usr/local/etc/dehydrated/certs/backupofden.libcom.de/private.key
