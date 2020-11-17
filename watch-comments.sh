# used to control output of files deleted and recovered using junk delete and junk recover. 
# Decided to put this code in its own function as the code is used twice in the program, just with different
# output in each instance it's used.
rec_del(){
	fs_del="$(cat ~/bin/.filesDel.txt)"
	echo "${1} $(echo ${fs_del} | wc -w)"
	echo
	echo "most recently deleted files (max 10)"
	echo
	tail ~/bin/.filesDel.txt 
	echo

	fs_rec="$(cat ~/bin/.filesRec.txt)"
	echo "${2} $(echo ${fs_rec} | wc -w)"
	echo
	echo "most recently recovered files (max 10)"
	echo
	tail ~/bin/.filesRec.txt 

	> ~/bin/.filesDel.txt; > ~/bin/.filesRec.txt

	echo "---------"
}

# watch function used to control the output of the watch script every 15 seconds
watch(){
	# gets all files in the .junkdir directory before the 15 second wait
	curFs=($(echo $(ls ~/.junkdir) ))
	sleep 15s
	
	# parameters passed into watch are only used within the rec_del function call	
	rec_del "${1}" "${2}"
	
	# finds all files with a modification time within 15 seconds ago and stores all this 
	# information in the fs_crt variable
	fs_crt="$(find ~/.junkdir -type f -newermt '-15 seconds' -printf '%f\n')"

	#gets all files in the .junkdir directory after the 15 second wait
	delChk=($(echo $(ls ~/.junkdir) ))
	
	# stores all unique files (files that are only present in one array) in fs_dOr (deleted or recovered)
	# fs_crt included in comparison to ensure newly created files are not included in the output stored
	# in fs_dOr
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

####Main

main(){
# k's sole purpose is used to infinitely keep while loop running. Process should run continously 
# until it is killed so infinite looping should not be an issue 
k=0

# del_ec and rec_ec used to control output for info relating to files recovered and deleted
# within the rec_del function. Passing in these arguments is required as the rec_del function
# outputs information on files recovered and deleted since the last time the watch script was run
# on startup and then proceeds to output information on files recovered and deleted in the last
# 15 seconds.
del_ec="no. files deleted from junk dir using junk delete since last watch script run:"
rec_ec="no. files recovered using junk recover since last watch script run:"

rec_del "${del_ec}" "${rec_ec}" 

del_ec="no. files deleted from junk dir using junk delete in the last 15 seconds:"
rec_ec="no. files recovered using junk recover in the last 15 seconds:"

while [ "${k}" != 1 ]; do

# variables passed into the watch function are only passed into it for use within the rec_del function
# which is called within the watch function
watch "${del_ec}" "${rec_ec}" 
done
}

main

