#!/bin/bash

# Controleer of er een argument is meegegeven
if [ -z "$1" ]; then
    echo "Gebruik: $0 <domeinnaam>"
    echo "Bijvoorbeeld: $0 voorbeeld.snb"
    exit 1
fi

# Variabelen
DOMAIN="$1"
BASE_DOMAIN="snb"
NAMED_CONF="/etc/named.conf"
ZONE_DIR="/var/named"
ZONE_FILE="$ZONE_DIR/$DOMAIN"
NAMED_USER="named"  # Standaard gebruiker voor named

# Controleer of het domein correct eindigt op .snb
if [[ $DOMAIN != *"."$BASE_DOMAIN ]]; then
    if [[ $DOMAIN == *"."* ]]; then
        echo "Fout: Domeinnaam moet eindigen op .$BASE_DOMAIN"
        exit 1
    else
        DOMAIN="$DOMAIN.$BASE_DOMAIN"
        ZONE_FILE="$ZONE_DIR/$DOMAIN"
    fi
fi

# Toon de aangemaakte domeinnaam
echo "Domein: $DOMAIN"

# Controleer of de zonefile al bestaat
if [ -f "$ZONE_FILE" ]; then
    echo "Fout: Zonefile voor $DOMAIN bestaat al."
    exit 1
fi

# Maak de zonefile aan
echo "Zonefile wordt aangemaakt in: $ZONE_FILE"

cat << EOF > "$ZONE_FILE"
\$TTL 86400
@   IN  SOA ns.$BASE_DOMAIN. root.$BASE_DOMAIN. (
        2023121201  ; Serial
        3600        ; Refresh
        1800        ; Retry
        1209600     ; Expire
        86400       ; Minimum TTL
)
    IN  NS  ns.$BASE_DOMAIN.
@   IN  A   10.129.37.211
www IN  CNAME @
EOF

# Pas de rechten aan voor named
chown $NAMED_USER:$NAMED_USER "$ZONE_FILE"

# Voeg de zone toe aan named.conf met 'allow-update { none; };'
echo "Zone wordt toegevoegd aan $NAMED_CONF"
cat << EOF >> "$NAMED_CONF"
zone "$DOMAIN" IN {
    type master;
    file "$ZONE_FILE";
    allow-update { none; };
};
EOF

# Herstart de DNS-server
echo "DNS-server wordt herstart..."
systemctl restart named

# Controleer de status
if systemctl is-active --quiet named; then
    echo "Domein $DOMAIN werd succesvol toegevoegd en DNS-server is actief."
else
    echo "Fout: DNS-server kon niet herstarten. Controleer de configuratie."
fi

