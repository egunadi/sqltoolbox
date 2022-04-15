 #!/bin/bash

function clone
{
	BaseDirectoryBitBucket="https://jkahanding@bitbucket.org/MedinfoAdmins/"
    # allGIT[] array of git repositories on github
	allGIT=( \
	"https://openrange.medinformatix.com/patient-portal-legacy/BUILD" \
	)
	# all dir repository name in bitbucket
	allDIR=( \
	"buildscript" \
	)
	for i in ${!allGIT[@]}; do
		echo "BEGIN cloning ${allDIR[$i]}"
		git clone ${allGIT[$i]} ${allDIR[$i]}
		echo "END cloning ${allDIR[$i]}"
		cd ${allDIR[$i]}
		echo "BEGIN checkout origin branches ${allDIR[$i]}"
		for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do
		   echo "$branch TRACKING ADDED "
		   git branch --track ${branch#remotes/origin/} $branch
		done		
		echo "END checkout origin branches ${allDIR[$i]}"
		echo "BEGIN PUSH origin branches ${allDIR[$i]}"
		git remote add bitweb "${BaseDirectoryBitBucket}${allDIR[$i]}.git"
		git push --all bitweb
		echo "END PUSH origin branches ${allDIR[$i]}"
		cd ..
		echo END
	done
}

clone