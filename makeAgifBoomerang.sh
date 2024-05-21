#!/bin/bash
if [ -z "$1" ]; then
	echo "Aucun nom de fichier donner"
	echo "Format de commande: .sh <Nom_fichier> [premier frame] [nb frame à retirer depuis la fin] [fps]"
	return 1
fi

filename="$1"
if [ -z "$2" ]; then
	bufferDebut=0
else
	bufferDebut=$2
fi

if [ -z "$3" ]; then
	bufferFin=0
else
	bufferFin=$3
fi
# $2 => start buff
# $3 => end buff
resultDir="${filename%.*}_boomerang"
framecount=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $1)
# LOG
echo "Fichier:	${filename}"
echo "Frame de début:	${bufferDebut}"
echo "Frame avant la fin:	${bufferFin}"
echo "Nombre de frame: ${framecount} > $((framecount-2))"

if [ $framecount -lt $bufferFin ]; then
	echo "le frame de buffer de fin fourni (${bufferFin}) est trop grand. Le fichier ne contient que ${framecount} frames"
	return 2
fi

if [ $framecount -lt $bufferDebut ]; then
	echo "le frame de buffer de debut fourni (${bufferDebut}) est trop grand. Le fichier ne contient que ${framecount} frames"
	return 3
fi

if [ $((framecount-bufferFin)) -le $bufferDebut ]; then
	echo "Le frame de début est après la fin. le gif à"
	return 4
fi

if [ ! -d $resultDir ]; then
	mkdir "${resultDir}"
fi

# export frame initial
ffmpeg -hide_banner -loglevel error -i $filename $resultDir/%04d.png

IMAGES=$resultDir/*

# Compteur d'images
NB_IMAGES=0
for f in $IMAGES; do
	((NB_IMAGES++))
done
tmp_nb_image=$NB_IMAGES
# Enlève les buffer
for f in $IMAGES; do
	i=${f: -8: 4}
	if [ $i -lt $bufferDebut ]; then
		# echo $i est moins que $bufferDebut
		rm $f
		((tmp_nb_image--))
	elif [ $i -gt $(($NB_IMAGES - $bufferFin)) ]; then
		# echo $i est plus que $NB_IMAGES - $bufferFin = $(($NB_IMAGES - $bufferFin))
		rm $f
		((tmp_nb_image--))
	fi
done
NB_IMAGES=$tmp_nb_image

# Renome pour que les nombres se suivent
i=0000
if [ ! $bufferDebut -eq 0 ]; then
	for f in $IMAGES; do
		((i++))
		mv ${f} ${f::-8}$(printf %04d $i).png
	done
fi

for i in $(seq 2 $((NB_IMAGES-1))); do
	n=$((i-2))
	cp "$resultDir/$(printf %04d $i).png" "$resultDir/$(printf %04d $((NB_IMAGES*2-2-n))).png"
done

# ==== The meat ====
# ffmpeg -hide_banner -loglevel error -i $filename -filter_complex "[0:v]trim=start_frame=${bufferDebut}:end_frame=$((framecount-bufferFin)),split=2[a][b];[b]trim=start_frame=1:end_frame=$((framecount-bufferFin-bufferDebut-1)),reverse[c];[a][c]concat" -an "${resultDir}/%04d.png"
# FUCK THE MEAT

if [ -z "$4" ]; then
	fps=20
else
	fps=$4
fi
echo "fps:	${fps}"
gifski --extra -W 2560 -H 1080 --fps ${fps} -o ${resultDir}_${bufferDebut}-${bufferFin}-${fps}.gif ${resultDir}/*

rm -r $resultDir
