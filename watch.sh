rec_del(){
	fs_del="$(cat ~/bin/.filesDel.txt)"
	echo "${1} $(echo ${fs_del} | wc -w)"
	echo
	echo "most recently deleted files"
	echo
	tail ~/bin/.filesDel.txt 
	echo

	fs_rec="$(cat ~/bin/.filesRec.txt)"
	echo "${2} $(echo ${fs_rec} | wc -w)"
	echo
	echo "most recently recovered files"
	echo
	tail ~/bin/.filesRec.txt 

	> ~/bin/.filesDel.txt; > ~/bin/.filesRec.txt

	echo "---------"
}


watch(){
	curFs=($(echo $(ls ~/.junkdir) ))
	sleep 15s
	
	rec_del "${1}" "${2}"

	fs_crt="$(find ~/.junkdir -type f -newermt '-15 seconds' -printf '%f\n')"

	delChk=($(echo $(ls ~/.junkdir) ))
	
	fs_dOr=($(echo ${curFs[@]} ${delChk[@]} ${fs_crt[@]} | tr ' ' '\n' | sort | uniq -u))

	 	

	echo "total no. files created, modified or moved to junk in the last 15 seconds: $(echo ${fs_crt} | wc -w)"
	echo "files created, modified or moved to junk in the last 15 seconds:"
	echo "${fs_crt}"
	
	echo	

	echo "total no. files deleted or recovered in the last 15 seconds: $(echo ${#fs_dOr[@]})"
	echo "files deleted or recovered in the last 15 seconds:"

	for f in "${fs_dOr[@]}"; do
		echo "${f}"
	done
	echo "---------"
}

main(){
k=0
del_ec="no. files deleted from junk dir using junk delete since last watch script run:"
rec_ec="no. files recovered using junk recover since last watch script run:"
rec_del "${del_ec}" "${rec_ec}" 
del_ec="no. files deleted from junk dir using junk delete in the last 15 seconds:"
rec_ec="no. files recovered using junk recover in the last 15 seconds:"
while [ "${k}" != 1 ]; do
watch "${del_ec}" "${rec_ec}" 
done
}

main

