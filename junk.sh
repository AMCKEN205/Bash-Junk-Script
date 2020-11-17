#! /bin/bash
USAGE="usage: $0 [OPTIONS] [FILES]"
vals=()
inter=1
curwd=$(pwd)

get_uinpts(){
	inter=0
	fin="n"
	inpts=()
	
	while [[ $fin != ["Y""y"] ]]
	do
		inpt=
		echo -n "${1:-enter value: }" 
		read inpt 
		inpts+=($inpt)
		fin=
		while [[ $fin != ["Y""y""N""n"] ]]; do
			echo -n "done?(Y or y = yes N or n = no): "
			read fin
		done
	done
	vals="${inpts[@]}"
	
}


list(){
	
	cd ~/.junkdir
	if [ -z "$(ls -A)" ]; then
   		echo "The junk directory is empty"
	else
   		FILES=($(echo *))
	
		for f in "${FILES[@]}" 
		do
			echo "filename: ${f} | size in bytes: $(stat --printf="%s" $f) | filetype: $(file -b $f)"
		done
	
	fi
	
	cd "${curwd}"
}	


recover(){
	if [[ $inter == 1 ]]; then
		for f in $@; do
			if [[ "${f}" != "-r" ]]; then
				shift
			else
				shift; break
			fi
		done			
	fi

	for f in $@; do
		if [ ! -e ~/.junkdir/"${f}" ]; then
			echo "error, file: ${f} not found"
		else
			mv ~/.junkdir/${f} .
			echo "${f}" >> ~/bin/.filesRec.txt; echo "${f} has been recovered to ${curwd}"
		fi
	done
	echo "files now in current directory:"; ls
}


delete(){
	i=0
	fs_del_nms=()
	cd ~/.junkdir
	FILES=($(echo *))
	echo "Y/y for yes or N/n for no"
	for f in "${FILES[@]}"
	do 
		i=$((i+1))
		er=1
		while [ "${er}" == 1 ]; do
			echo -n "file ${i}: filename: ${f}, do you wish to delete this file?>"
			read u_ans
			if [[ $u_ans == ["Y""y"] ]]; then
				rm -rf "${f}"; fs_del_nms+=("${f}")
				echo "${f}" >> ~/bin/.filesDel.txt
				er=0

			elif [[ $u_ans == ["N""n"] ]]; then
				er=0

			else
				echo "error: invalid input, enter Y/y for yes or N/n for no"
			fi
		done
	done

	


	echo 
	echo "${#fs_del_nms[@]} files deleted"
	echo
	echo "files deleted:"
	echo
	for x in "${fs_del_nms[@]}"; do
		echo "${x}"
	done
	cd "${curwd}"
}

total(){
	
	cd /home
	directs=(*/)
	tot_size=0	

	for dir in "${directs[@]}";
 	do 
		
		cd "${dir}"
		if [ ! -d .junkdir ]; then
			if [[ $EUID -ne 0 ]]; then
				echo "${dir::-1}: a .junkdir directory does not exist in $dir, run as root to create one automatically using total (-t)"
			else
				mkdir .junkdir
				echo "${dir::-1}: a .junkdir directory did not exist in $dir, a .junkdir directory has now been created"
			fi
		else
			j_size=$(du -hb ./.junkdir | cut -f1)
			echo "${dir::-1} .junkdir directory size in bytes: ${j_size}"
			tot_size=$((${tot_size} + ${j_size}))
		fi
		cd ..
	done
	echo "total size of all user .junkdir directories in bytes: ${tot_size}"
	cd "${curwd}"
}

watch(){
	terminator -e ~/bin/watch.sh >/dev/null 2>&1 &
}

kill_w(){
	kill $(pgrep -f watch.sh)
}

junk(){


	for i in $@; do
		
		if [[ $i = *"-r"* ]]; then
			break
		elif [[ $i = *"-"* ]]; then
			:
		elif [ -e "${i}" ]; then
			touch "${i}"
			mv "${i}" ~/.junkdir
			echo "${i} moved to junk directory"
		else
			echo "error, ${i} does not exist within the current directory"
		fi
	done

}

sigint_handle(){
	z=0
	FILES=($(echo ~/.junkdir/*))
	for f in "${FILES[@]}"; do
		
		if [ -f "${f}" ]; then
			((z++))
		fi
	done
	echo
	echo "${z} regular files within ${USER}'s junk directory"

	
}

trap sigint_handle SIGINT

echo "Name: Alexander McKenzie | Student ID: S1507940"
echo "-----------------------------------------------"

if [ ! -d ~/.junkdir ]; then
	mkdir ~/.junkdir
fi

if [ ! -d ~/bin ]; then
	mkdir ~/bin
fi

if [ $(du -k ~/.junkdir | cut -f1) -gt 1000 ];then 
	echo "warning, junk directory disk usage exceeds 1KB"
fi

junk $@

while getopts :lr:dtwk args 
do
  case $args in
     l) list;;
     r) recover "${@}";;
     d) delete;; 
     t) total;; 
     w) watch;; 
     k) kill_w;;   
     :) echo "data missing, option -$OPTARG";;
    \?) echo "$USAGE";;
  esac
done

((pos = OPTIND - 1))
shift $pos

PS3='option> '



if (( $# == 0 ))
then if (( $OPTIND == 1 ))
 then select menu_list in list recover delete total watch kill exit
      do case $menu_list in
         "list") list;;
         "recover") get_uinpts "enter file to recover> "; recover "${vals}";;
         "delete") delete;;
         "total") total;;
         "watch") watch ;;
         "kill") kill_w;;
         "exit") exit 0;;
         *) echo "unknown option";;
         esac
      done
 fi
fi
