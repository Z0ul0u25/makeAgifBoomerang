# makeAgifBoomerang

Un script bien simple pour faire boucler un GIF sur lui même en le passant à reculon

## Dépandance

- ffmpeg
- gifski

## Comment l'utiliser

`./makeAgifBoomerang.sh <TonGif.gif> [frame de début] [nombre de frame] [fps]`
Remplace `TonGif.gif` par le nom de ton image.

`[frame de début]` Défaut à 0; correspond à l'index du frame de départ.

`[nombre de frame]` Défaut à 12; correspond au nombre de frame avant de boucler.

`fps` Défaut à 20; est le nombre d'image par seconde du résultat.

Le fichier résultant sera nommé selon le fichier initial plus le frame initial, final et fps exemple: `exemple_2-15-30.gif`

Donc avec la commande `./makeAgifBoomerang.sh exemple.gif 2 15 30` on passe de

![exempleIn](exemple.gif)

Deviendra

![exempleOut](exemple_2-15-30.gif)
