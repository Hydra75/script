#!/bin/bash

# Liste de tous les utilisateurs sauf 'manu', 'root' et les utilisateurs système (UID < 1000)
users=$(awk -F: '{ if ($3 >= 1000 && $1 != "manu" && $1 != "root") print $1 }' /etc/passwd)

for user in $users
do
    echo "Suppression de l'utilisateur: $user"
    sudo userdel -r $user  # Supprime l'utilisateur et son répertoire personnel
done