#!/bin/bash 

#Verifier la ligne de comande 
if [ $# -ne 1 ]
    then
        echo "Nombre d'arguments incorrect"
	    echo "Usage : $0 arg[1] "
        exit 
fi
#Verifier l'existance du fichier passer en argument et si il est remplit/vie
if [ ! -s $1 ]
    then 
        echo "Fichier n'existe pas ou vide " 
        exit 
fi

#Verifier le contenu du fichier
while IFS=':' read -r prenom nom groupes sudo motdepasse; 
    do
        if [ $? -ne 0 ]
            then 
                echo "Format fichier non valide (Erreur en lecture)" 
        fi
        # Vérifier le format de chaque ligne prénom:nom:groupe1,groupe2,…:sudo:motdepasse 
        if [[ -z $prenom || -z $nom || -z $sudo || -z $motdepasse ]]; 
        then
            echo "Erreur : Format incorrect dans le fichier"
            exit 
        fi
    done < "$1"

#Fonction qui ajoute l'utilisateur au groupe sudoers si sudo : oui 
ajouteeSudo() {
    local login="$1"  # le nom d'utilisateur
    local sd="$2"  # le champ sudo  
    if [ "${sudo}" = "oui" ]; then
        sudo usermod -aG sudo "${login}"
    fi
}

#Creer des groupes et Ajouter des utilisateurs
while IFS=':' read -r prenom nom groupes sudo motdepasse; do
    #Generer le login 
    login="${prenom:0:1}${nom}"
    login="${login,,}"
    if getent passwd $login > /dev/null; then
      i=1
      original_login=$login
      while grep -q "^$login:" /etc/passwd;
        do
            login="${original_login}$i"
            i=$(( $i + 1 )) 
        done
    fi

    #Contenu du Champs commentaire dans /etc/passwd : nom prenom
    gecos="$prenom $nom"
    #Creer un utilisateur et un groupe primaire avec son nom si le champ groupes est vide 
    if [ -z "$groupes" ]
        then 
            sudo useradd -c "$gecos" -U -m -p "$(openssl passwd -1 "$motdepasse")" "$login"
            sudo chage -d 0 "$login" # forcer a changer le mdp lors de la 1er connexion
            ajouteeSudo $login $sd
    else
        IFS=',' read -ra ARRAY_GROUPES <<< "$groupes"
        for GROUPE in "${ARRAY_GROUPES[@]}"; 
            do  
                if ! getent group "$GROUPE" &>/dev/null; 
                    then addgroup "$GROUPE"
                fi
            done
        #Creer un utilisateur avec son groupe primaire
        sudo useradd -c "$gecos" -m -p "$(openssl passwd -1 "$motdepasse")" -g "${ARRAY_GROUPES[0]}" "$login" 
        sudo chage -d 0 "$login"
        ajouteeSudo $login $sd
        #Ajouter les groupes secondaires a l'utilisateur
        for GROUPE in "${ARRAY_GROUPES[@]}"; 
            do  
                if [ "${GROUPE}" != "${ARRAY_GROUPES[0]}" ]; 
                    then 
                        sudo usermod -aG "$GROUPE" "$login"
                fi
            done
    fi
    # Créer entre 5 et 10 fichiers de taille 5Mo < taille < 50Mo pour tous les utilisateurs
    nombre_de_fichiers=$((RANDOM % 6 + 5)) # creer un nombre aléatoire entre 5 et 10 (nombre de fichiers)
    for i in $(seq 1 $nombre_de_fichiers);  
        do
            taille_fichier=$((RANDOM % 46 + 5)) # creer un nombre aléatoire entre 5 et 50 Mo (taille d'un fichier).
            nom_fichier="${login}_$i"
            dd if=/dev/urandom of="/home/$login/$nom_fichier" bs=512K count=$taille_fichier status=none
            
        done
done < "$1"

