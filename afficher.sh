#!/bin/bash

MIN_UID=1000

# Traitement des options
while getopts ":G:g:s:u:" opt; do
  case ${opt} in
    G ) primary_group_name=$OPTARG;;  # Filtre par groupe primaire
    g ) secondary_group_option=$OPTARG;;  # Filtre par groupe secondaire spécifique
    s ) sudo_option=$OPTARG;;  # Filtre par statut sudoer (0 pour non, 1 pour oui)
    u ) user_option=$OPTARG;;  # Filtre par nom d'utilisateur
    \? ) echo "Usage: cmd [-G groupe] [-g groupe] [-s 0|1] [-u nom]"; exit 1;;
  esac
done

# Parcourir /etc/passwd pour obtenir les entrées d'utilisateurs humains
grep ":x:[${MIN_UID}-9][0-9][0-9][0-9]:" /etc/passwd | while IFS=':' read -r login password uid gid gecos home shell; do
    primary_group=$(id -gn "$login")
    
    # Récupérer les groupes secondaires
    secondary_groups=$(id -nG "$login" | tr ' ' '\n' | grep -v "^$primary_group$" | tr '\n' ' ')

    # Appliquer le filtre de groupe secondaire
    if [[ -n "$secondary_group_option" && ! $(echo "$secondary_groups" | grep -w "$secondary_group_option") ]]; then
        continue
    fi

    # Vérifier et appliquer le filtre sudoer
    sudo_status="NON"
    if sudo -l -U "$login" 2>/dev/null | grep -q '(ALL)'; then
        sudo_status="OUI"
    fi
    if [[ -n "$sudo_option" && (("$sudo_option" == "1" && "$sudo_status" != "OUI") || ("$sudo_option" == "0" && "$sudo_status" != "NON")) ]]; then
        continue
    fi

    # Appliquer le filtre de nom d'utilisateur
    if [[ -n "$user_option" && "$user_option" != "$login" ]]; then
        continue
    fi

    # Extraire le prénom et le nom
    full_name=$(echo "$gecos" | awk -F',' '{print $1}')
    prenom=$(echo "$full_name" | awk '{print $1}')
    nom=$(echo "$full_name" | awk '{ $1=""; print $0 }' | sed 's/^[ ]*//')

    # Calculer la taille du répertoire personnel
    taille=$(du -sb "$home" | awk '{print $1}')
    tailleMo=$((taille / 1024 / 1024))
    tailleRestanteKo=$(((taille / 1024) % 1024))
    tailleRestanteOctets=$((taille % 1024))

    # Afficher les informations de l'utilisateur
    echo "Utilisateur : $login"
    echo "Prénom : $prenom"
    echo "Nom : $nom"
    echo "Groupe primaire : $primary_group"
    echo "Groupes secondaires : $secondary_groups"
    echo "Répertoire personnel : ${tailleMo}Mo ${tailleRestanteKo}ko ${tailleRestanteOctets}octets"
    echo "Sudoer : $sudo_status"
    echo "------------------------------"
done
