#! /bin/bash
USAGE="usage: $0 [OPTIONS] [FILES]" 
vals=()
inter=1
curwd=$(pwd)


# generic (excluding setting inter and vals) function used to get multiple user inputs when required. 
# Only required by recover in this script

get_uinpts(){
	# inter used to inform script whether or not it's being used interactively, 
	inter=0
	
	fin="n"
	
	# inpts stores all values entered while running get_uinpts
	inpts=()
	
	while [[ $fin != ["Y""y"] ]]
	do

		inpt=
		echo -n "${1:-enter value: }" 
		read inpt 
		inpts+=($inpt)

		# val of fin set to null to ensure while loop validation is entered into
		fin=
		while [[ $fin != ["Y""y""N""n"] ]]; do
			echo -n "done?(Y or y = yes N or n = no): "
			read fin
		done
	done
	# exports all values entered to global array "vals"
	vals="${inpts[@]}"
	
}

# lists files and file information for each file in the .junkdir directory
list(){
	
	cd ~/.junkdir
	# checks that the junk directory is empty before performing listing of .junkdir.
	# This ensures output is understandable by user when .junkdir is empty.  
	if [ -z "$(ls -A)" ]; then
   		echo "The junk directory is empty"
	else
		# gets the names of all files in .junkdir
   		FILES=($(echo *))
		# runs through all files in .junkdir, prints out required information when at each file
		for f in "${FILES[@]}" 
		do
			echo "filename: ${f} | size in bytes: $(stat --printf="%s" $f) | filetype: $(file -b $f)"
		done
	
	fi
	
	# returns script to the directory it was executed in
	cd "${curwd}"
}	

# used to recover files from the .junkdir junk directory, files are passed into the function as arguments
recover(){
	# if the script is not being run interactively, continually shifts through arguments until 
	# script gets to -r. Ensures only relevant data (files) processed by the recover function
	if [[ $inter == 1 ]]; then
		for f in $@; do
			if [[ "${f}" != "-r" ]]; then
				shift
			else
				shift; break
			fi
		done			
	fi
	
	# loops through all files provided, recovers them to the current directory if they exist
	# otherwise an error message is output
	for f in $@; do
		if [ ! -e ~/.junkdir/"${f}" ]; then
			echo "error, file: ${f} not found"
		else
			mv ~/.junkdir/${f} .
			# current file file name is output to .filesRec.txt for use in the watch script
			# to output files recovered through junk recover
			echo "${f}" >> ~/bin/.filesRec.txt; echo "${f} has been recovered to ${curwd}"
		fi
	done
	# lists files in current directory
	echo "files now in current directory:"; ls
}

# used to interactively delete functions in the junk directory, runs through all files in the junk directory and asks the user whether or not they want to delete the current file
delete(){
	# counter variable i used to print out the file no. for each file. 

	i=0

	#fs_del_nms used to output the name of each file deleted by the junk script	

	fs_del_nms=()

	# navigates to the junkdir directory then outputs all filenames to FILES array

	cd ~/.junkdir
	FILES=($(echo *))
	echo "Y/y for yes or N/n for no"

	# loops through all files in the .junkdir directory and asks the user whether or not they wish to delete each file

	for f in "${FILES[@]}"
	do 
		
		# er variable used to detect user input error.
		i=$((i+1))
		er=1
		# er variable set to 1 initially to ensure while loop enters, value only changes when valid 
		# input data is entered therefore loop will continually run until valid data is entered.
		while [ "${er}" == 1 ]; do
			echo -n "file ${i}: filename: ${f}, do you wish to delete this file?>"
			read u_ans
			
			if [[ $u_ans == ["Y""y"] ]]; then
				
				# current file removed from .junkdir when the user inputs Y or y.
				# -r option used to allow directory deletion.
				# -f option used to avoid any additional removal prompts.

				# file name added to list of deleted files, file name also added
				# to .filesDel.txt file which is used by the watch script to get info on
				# files deleted through junk delete 

				rm -rf "${f}"; fs_del_nms+=("${f}")
				echo "${f}" >> ~/bin/.filesDel.txt
				er=0
			
			elif [[ $u_ans == ["N""n"] ]]; then
				# does nothing other than tell program user has
				# entered valid input data				
				
				er=0

			else
				# error message output when invalid input data is entered
				echo "error: invalid input, enter Y/y for yes or N/n for no"
			fi
		done
	done

	

	# outputs the number of files deleted and the names of files deleted, script then navigates
	# back to original directory it was run from
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

# used to output storage space used by each individual users .junkdir directory then output the total of all
# .junkdir directories added together
total(){
	
	cd /home
	# directs used to store names of directories of all users on current system
	directs=(*/)
	# tot_size used to stores the sum of all directories
	tot_size=0	

	for dir in "${directs[@]}";
 	do 
		
		cd "${dir}"
		# checks if a .junkdir directory exists, if not user is informed of this. If script
		# is run as super user .junkdir directories are also automatically created.
		
		# .junkdir directories created through total are not initially included in the total size of
		# all .junkdir directories and their sizes are not output initially. running total again
		# includes newly created .junkdir directories in size output 

		if [ ! -d .junkdir ]; then
			if [[ $EUID -ne 0 ]]; then
				echo "${dir::-1}: a .junkdir directory does not exist in $dir, run as root to create one automatically using total (-t)"
			else
				mkdir .junkdir
				echo "${dir::-1}: a .junkdir directory did not exist in $dir, a .junkdir directory has now been created"
			fi
		else
			# j_size used to store the size of users .junkdir directory. 
			# du command used to get size of the user .junkdir directory.
			# du output then piped through cut which takes the first field (size)
			# as this is the only bit of data required from du output.
			# du -h used to make output readable. du -b used to 
			# output size in byte format			
			
			j_size=$(du -hb ./.junkdir | cut -f1)
			
			# ::-1 used to cut end / from each user directory output
			echo "${dir::-1} .junkdir directory size in bytes: ${j_size}"
			
			# total size incremented by the size of current user .junkdir
			tot_size=$((${tot_size} + ${j_size}))
		fi
		cd ..
	done
	echo "total size of all user .junkdir directories in bytes: ${tot_size}"
	cd "${curwd}"
}

# used to execute watch_script process in seperate terminal window
watch(){
	# >/dev/null used to supress any error output based on plugins not on current machine (irrelevant to 
	# watch script successful run)
	# & used to run watch_script in background, ensures user can still use current terminal window
	terminator -e ~/bin/watch.sh >/dev/null 2>&1 &
}

# used to kill any watch processes currently running
kill_w(){
	# unoptimal method of killing watch script as finds any processes that match search term and kills
	# them. E.g. if editing watch script in gedit will kill gedit process in addition to watch script.
	# Originally attempted to export the PID from watch func however I was not successful in implementing
	# that method.

	kill $(pgrep -f watch.sh)
}

# used to send files passed in as arguments to junk directory 
junk(){

	# loops through files passed in as arguments
	for i in $@; do
		# ensures files are not moved to the junk directory when the user wishes to use the recover 
		# function
		if [[ $i = *"-r"* ]]; then
			break
		# ensures any options passed as args are ignored by junk function
		elif [[ $i = *"-"* ]]; then
			:
		# ensures file exists before moving to junk directory, otherwise error message is output
		elif [ -e "${i}" ]; then
			# touch used on file to allow watch script to output files recently moved to 
			# .junkdir (uses file modification time for output) 
			touch "${i}"
			mv "${i}" ~/.junkdir
			echo "${i} moved to junk directory"
		else
			echo "error, ${i} does not exist within the current directory"
		fi
	done

}

# used to handle what the script should do when SIGINT signals are sent to it. 
# in this case the number of regular files within the user's .junkdir are output
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

####Main

trap sigint_handle SIGINT

echo "Name: Alexander McKenzie | Student ID: S1507940"
echo "-----------------------------------------------"

# directories required for successful run of junk script are created if they do not already exist
if [ ! -d ~/.junkdir ]; then
	mkdir ~/.junkdir
fi

if [ ! -d ~/bin ]; then
	mkdir ~/bin
fi

if [ $(du -k ~/.junkdir | cut -f1) -gt 1000 ];then 
	echo "warning, junk directory disk usage exceeds 1Kb"
fi

# all arguments are initially passed into the junk function
junk $@


# used for options passed into the script. Functions are executed based on the options provided to the
# script
while getopts :lr:dtwk args #options
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

# used when the script is given no arguments. Displays a menu interface, users select the function they want
# to carry out based on the number representing each option

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
