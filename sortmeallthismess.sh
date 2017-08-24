#!/bin/bash

bookDirName=$1
subdir1="droite impairs"
subdir1List=()
subdir2="gauche pairs"
subdir2List=()

#parse options
if test $# -ne "1" ; then
    echo "error: expecting one argument"
    exit -42
fi
if test ${#1} -lt 3 -o ! -d $bookDirName ; then
    echo "error: arg 1: book directory name is incorrect: $bookDirName"
    exit -43
fi
cd $bookDirName
echo "changing dir to $PWD"
if test ! -d "$subdir1" -o ! -d "$subdir2" ; then
    echo "error: subdirectories missing or mispelled"
    exit -44
fi

#regrouping files in directories
copiesdir=`mktemp -d`
echo "directory containing copies is: $copiesdir"
cd "$subdir1"
echo "changing dir to $PWD"
filesNbIndicator=`ls | wc -l`
i=1
for file in * ; do
    newFile=$(echo $file | sed 's/[a-zA-Z_]*//')
    progress=$(($i*100/$filesNbIndicator))
    echo "treating $file -> $copiesdir/$newFile (progress=$progress%)"
#cp $file "$copiesdir/$newFile"
    convert $file -brightness-contrast 15x15 -resize 1024x768 -quality 80 -rotate 90 "$copiesdir/$newFile"
    subdir1List+=("$newFile");
    ((i++))
done
echo "subdir1List = ${#subdir1List[@]}"

cd "../$subdir2"
echo "changing dir to $PWD"
filesNbIndicator=`ls | wc -l`
i=1
for file in * ; do
    newFile=$(echo $file | sed 's/[a-zA-Z_]*//')
    progress=$(($i*100/$filesNbIndicator))
    echo "treating $file -> $copiesdir/$newFile (progress=$progress%)"
#cp $file "$copiesdir/$newFile"
    convert $file -brightness-contrast 15x15 -resize 1024x768 -quality 80 -rotate 90 "$copiesdir/$newFile"
    subdir2List+=("$newFile");
    ((i++))
done
echo "subdir2List = ${#subdir2List[@]}"

#check our lists are not empty, and let's continue our work
if test ${#subdir1List[@]} -eq "0" -a ${#subdir2List[@]} -eq "0" ; then
    echo "error: two lists of files are empty"
    exit -45
fi
#also check that copies number is correct
OrigFilesNb=$((${#subdir1List[@]}+${#subdir2List[@]}))
copiesNb=`ls $copiesdir | wc -l`
if test $OrigFilesNb -ne $copiesNb ; then
    echo "Error: number of copies incorrect: OrigFilesNb=$OrigFilesNb copiesNb=$copiesNb"
    exit -46
fi

i=0
producedName=0
cd "$copiesdir"
echo "changing dir to $PWD"
for file_r in "${subdir1List[@]}" ; do
    file_l=${subdir2List[$i]}

#working on modifying original filenames is useless after all...
#    base_r=`basename $file_r .JPG`
#    base_l=`basename $file_l .JPG`

((producedName++))
echo -n "turning $file_r into $producedName.JPG"
mv $file_r "$producedName.JPG"
((producedName++))
echo " ...and $file_l into $producedName.JPG"
mv $file_l "$producedName.JPG"

    #echo "iteration $i: file_r=$file_r file_l=$file_l base_r=$base_r base_l=$base_l"
    ((i++))
done
nbNewFiles=`ls $copiesdir | wc -l`
echo "ending: list1_length=${#subdir1List[@]} list2_length=${#subdir2List[@]} number of new files created:$nbNewFiles"

resLogFile=`mktemp`
echo "converting into one single pdf (located under /tmp/result.pdf). To see advancement, see log file $resLogFile"
convert *.JPG -monitor /tmp/result.pdf 2> $resLogFile
echo "done."