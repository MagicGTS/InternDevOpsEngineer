#!/bin/sh
set -o pipefail

set +e

cat $RENEWED_LINEAGE/privkey.pem $RENEWED_LINEAGE/fullchain.pem > /etc/pki/nginx/$(basename $RENEWED_LINEAGE).crt
cat $RENEWED_LINEAGE/privkey.pem > /etc/pki/nginx/private/$(basename $RENEWED_LINEAGE).key
chmod 600 /etc/pki/nginx/private/$(basename $RENEWED_LINEAGE).key /etc/pki/nginx/$(basename $RENEWED_LINEAGE).crt
systemctl reload nginx
