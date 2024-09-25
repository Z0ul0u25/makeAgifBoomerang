#!/bin/bash
if [ -z "$1" ]; then
	echo "Aucun nom de fichier donner"
	echo "Format de commande: .sh <Nom_fichier> [premier frame] [nb frame total] [fps]"
	return 1
fi

filename="$1"
if [ -z "$2" ]; then
	bufferDebut=0
else
	bufferDebut=$2
fi

if [ -z "$3" ]; then
	nbFrame=24
else
	nbFrame=$3
fi
# $2 => start buff
# $3 => end buff
resultDir="${filename%.*}_boomerang"
framecount=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 $1)
# LOG
echo "Fichier:	${filename}"
echo "Nombre de frame: ${framecount}"
echo "==============="
echo "Frame de début:	${bufferDebut}"
echo "Frame au total:	${nbFrame}"

# export frame initial
if [ ! -d $resultDir ]; then
	mkdir "${resultDir}"
fi
ffmpeg -hide_banner -loglevel error -i $filename $resultDir/%04d.png

IMAGES=$resultDir/*
compteurManuel=$(ls ${resultDir} | wc -l)

# Certaine video/gif on des doublons. detecté par ffprobe comme ayant la moitié de la valeur requise
if [ $compteurManuel -eq $((framecount * 2)) ]; then
	echo élimine les doublons
	c=0
	for i in $IMAGES; do
		echo "we do be $(($c % 2))"
		if [ $(($c % 2)) -eq 0 ];then
			rm $i
		else
			mv $i ${i::-8}$(printf %04d $((c/2))).png
		fi
		((c++))
	done
fi
framecount=$compteurManuel

if [ $framecount -lt $bufferDebut ]; then
	echo "le frame de debut fourni (${bufferDebut}) est trop grand. Le fichier ne contient que ${framecount} frames"
	return 3
fi

if [ $framecount -lt $((nbFrame-bufferDebut)) ]; then
	echo "le nombre de frame founri (${nbFrame}) est trop grand. Le fichier ne contient que ${framecount} frames"
	return 2
fi

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
	elif [ $i -gt $(($bufferDebut + $nbFrame - 1)) ]; then
		# echo $i est plus que $bufferDebut + $nbFrame = $(($bufferDebut + $nbFrame))
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
# ffmpeg -hide_banner -loglevel error -i $filename -filter_complex "[0:v]trim=start_frame=${bufferDebut}:end_frame=$((framecount-nbFrame)),split=2[a][b];[b]trim=start_frame=1:end_frame=$((framecount-nbFrame-bufferDebut-1)),reverse[c];[a][c]concat" -an "${resultDir}/%04d.png"
# FUCK THE MEAT

if [ -z "$4" ]; then
	fps=20
else
	fps=$4
fi
echo "fps:	${fps}"
gifski --extra -W 1080 --fps ${fps} -o ${resultDir}_${bufferDebut}-${nbFrame}-${fps}.gif ${resultDir}/*

rm -r $resultDir
