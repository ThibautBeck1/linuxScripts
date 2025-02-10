#!/bin/bash

# Controleer of het script met root-rechten wordt uitgevoerd
if [ "$EUID" -ne 0 ]; then
  echo "Voer dit script als root of met sudo uit."
  exit 1
fi

# Functie om het huidige DNS te tonen
function show_current_dns() {
  echo "Huidige DNS-instellingen:"
  nmcli dev show | grep DNS
  echo
}

# Functie om DNS te wijzigen
function change_dns() {
  echo "Geef de nieuwe DNS-server op (bijv. 8.8.8.8 of 1.1.1.1):"
  read -r new_dns

  if [[ -z "$new_dns" ]]; then
    echo "Geen DNS-server opgegeven. Probeer opnieuw."
    exit 1
  fi

  # Pas de nieuwe DNS toe op alle actieve verbindingen
  for conn in $(nmcli -t -f NAME connection show | grep -v '^--$'); do
    echo "Wijzigen van DNS voor verbinding: $conn"
    nmcli connection modify "$conn" ipv4.dns "$new_dns"
    nmcli connection modify "$conn" ipv4.ignore-auto-dns yes
    nmcli connection up "$conn"
  done

  echo "DNS-server gewijzigd naar: $new_dns"
  show_current_dns
}

# Menu
echo "DNS Configuratie Script - Fedora"
echo "1. Toon huidige DNS-instellingen"
echo "2. Wijzig DNS-server"
echo "3. Sluit het script"
echo -n "Kies een optie [1-3]: "
read -r keuze

case $keuze in
  1)
    show_current_dns
    ;;
  2)
    change_dns
    ;;
  3)
    echo "Script afgesloten."
    exit 0
    ;;
  *)
    echo "Ongeldige keuze. Probeer opnieuw."
    ;;
esac

