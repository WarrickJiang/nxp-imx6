#!/bin/bash

CREATE_EMMC=0

while [ $# -gt 0 ]; do
    case "$1" in
    --config)
            CONFIG_FILE="$2"
            shift
            ;;
    --config-dnf)
            CONFIG_FILE_DNF="$2"
            shift
            ;;
    --config-ostree)
            CONFIG_FILE_OSTREE="$2"
            shift
            ;;
    --image)
            IMAGE="$2"
            shift
            ;;
    --url)
            OSTREE_URL="$2"
            shift
            ;;
    --emmc)
            CREATE_EMMC=1
            shift
            ;;
         *) break
            ;;
    esac
    shift
done

usage(){

cat << EOF

ostree-deploy.sh --config <smart-config-file> --config-dnf <dnf-config-file> --config-ostree <ostree-config-file> --image <live image> --url <ostree-url> --emmc

EOF
}

verify_root_user()
{
    if [ "$EUID" -ne 0 ]; then
        return 1
    fi
    return 0
}

if ! [ $CREATE_EMMC -eq 1 -o -n "$OSTREE_URL" -o -e "$CONFIG_FILE" -o -e "$CONFIG_FILE_DNF" -o -e "$CONFIG_FILE_OSTREE" ]; then
	usage
	exit 1
else
       if [ -e "$CONFIG_FILE" ]; then
	   CONFIG_FILE=`readlink -f $CONFIG_FILE`
       fi
       if [ -e "$CONFIG_FILE_DNF" ]; then
           CONFIG_FILE_DNF=`readlink -f $CONFIG_FILE_DNF`
       fi
       if [ -e "$CONFIG_FILE_OSTREE" ]; then
           CONFIG_FILE_OSTREE=`readlink -f $CONFIG_FILE_OSTREE`
       fi
fi

if ! [ -e "$IMAGE" ]; then
        usage
	exit 1
else
	IMAGE=`readlink -f $IMAGE`
fi

verify_root_user
if [ $? != 0 ]; then
	echo "root right is required to run this script!"
	exit 1
fi

device=`losetup -f --show $IMAGE`
partprobe ${device}
if [ -z "$device" ]; then
	echo "[ERROR]: No free loop devices available"
	exit 1
fi

if ! [ -e "${device}p1" ]; then
        echo "[ERROR]: ${device}p1 cannot available!"
        losetup -d ${device}
        exit 1
fi

if ! [ -e "${device}p2" ]; then
	installer_sfr_image="Y"
elif ! [ -e "${device}p3" ]; then
	installer_image="Y"
elif [ -e "${device}p8" ]; then
	live_double_ot_image="Y"
elif ! [ -e "${device}p4" ]; then
	live_installer_image="Y"
else 
        live_image="Y"
fi

function deploy_live(){
	device=$1
	dir=$2	

	mount ${device}p3 $dir
	if [ -e "$dir/rootfs/var/lib/lxc" ]; then
		mount ${device}p4 $dir/rootfs/var/lib/lxc
		cd $dir/rootfs
	elif [ -e "$dir/var/lib/lxc" ]; then
		mount ${device}p4 $dir/var/lib/lxc
		cd $dir
	else
		echo "[ERROR]: essential rootfs is not available"
		umount $dir
        	losetup -d ${device}
		exit 1
	fi

	if ! [ -d factory_tmp ]; then
		mkdir factory_tmp
	fi

	mount -o subvolid=5 ${device}p3 factory_tmp
	if [ -d factory_tmp/.factory/var/lib/lxc ]; then
		mount -o subvolid=5 ${device}p4 factory_tmp/.factory/var/lib/lxc
	fi

	echo "[INFO] deploy $CONFIG_FILE to essential"
	cp -f $CONFIG_FILE var/lib/smart/config

	if [ -d factory_tmp/.factory/var/lib/smart ]; then
		echo "[INFO] deploy $CONFIG_FILE to factory-reset backed essential"
		cp -f $CONFIG_FILE factory_tmp/.factory/var/lib/smart/config
	fi

	CN=`ls var/lib/lxc`

	for cn in $CN; do
		if [ -d var/lib/lxc/$cn/rootfs/var/lib/smart ]; then
			echo "[INFO] deploy $CONFIG_FILE to $cn"
			cp -f $CONFIG_FILE var/lib/lxc/$cn/rootfs/var/lib/smart/config

			if [ -d factory_tmp/.factory/var/lib/lxc/.factory/$cn/rootfs/var/lib/smart ]; then 
				echo "[INFO] deploy $CONFIG_FILE to factory-reset backed $cn"
				cp -f $CONFIG_FILE factory_tmp/.factory/var/lib/lxc/.factory/$cn/rootfs/var/lib/smart/config
			fi
		fi
	done

	echo "[INFO] clean up the system"
	umount factory_tmp/.factory/var/lib/lxc
	umount factory_tmp
	rm -rf factory_tmp
	umount var/lib/lxc
	cd - >/dev/null 2>&1
}

function deploy_installer(){
	device=$1
	dir=$2

	if [ "X$installer_sfr_image" == "XY" ]; then
		mount ${device}p1 $dir
	else
		mount ${device}p2 $dir
	fi

	cd $dir
	if [ -e "opt/installer/images" ]; then
		echo "[INFO] deploy $CONFIG_FILE to `pwd`/opt/installer/images/config.smart"
		cp -f $CONFIG_FILE opt/installer/images/config.smart
	elif [ -e "./sfr.dsk" ]; then
		echo "[INFO] deploy $CONFIG_FILE to `pwd`/sfr.dsk"
		mount ./sfr.dsk EFI
		cp -f $CONFIG_FILE EFI/installer/images/config.smart
		umount EFI
	fi
	
        if [ -d "ostree/deploy/pulsar-linux" ]; then
		if [ -e "$CONFIG_FILE_DNF" ]; then
			echo "[INFO] deploy $CONFIG_FILE_DNF to `pwd`/ostree/deploy/pulsar-linux/deploy/*/etc/dnf/"
			cp -f $CONFIG_FILE_DNF ostree/deploy/pulsar-linux/deploy/*/etc/dnf/dnf.conf
		fi
		if [ -e "$CONFIG_FILE_OSTREE" ]; then
                        echo "[INFO] deploy $CONFIG_FILE_OSTREE to `pwd`/ostree/deploy/pulsar-linux/deploy/*/etc/ostree/remotes.d/"
                        cp -f $CONFIG_FILE_OSTREE ostree/deploy/pulsar-linux/deploy/*/etc/ostree/remotes.d/
                fi
	fi

	cd - >/dev/null 2>&1
}

function deploy_ostree(){
	device=$1
	dir=$2
	if [ -n "$OSTREE_URL" ]; then
                echo "[INFO] deploy $OSTREE_URL to `pwd`/ostree/repo/"
		mount ${device}p8 $dir
		cd $dir
		branch=`ls ${dir}/ostree/repo/refs/remotes/pulsar-linux/ | sed -n '1p'`
		if [ -n '${branch}' ]; then
			branch='branches='${branch}';'
		fi
		cat << EOF > `pwd`/ostree/repo/config
[core]
repo_version=1
mode=bare
[remote "pulsar-linux"]
url=${OSTREE_URL}
${branch}
EOF
		cd - >/dev/null 2>&1		
		umount $dir
		

		mount ${device}p6 $dir
		cd $dir
		branch=`ls ${dir}/ostree/repo/refs/remotes/pulsar-linux/ | sed -n '1p'`
		if [ -n '${branch}' ]; then
			branch='branches='${branch}';'
		fi
		cat << EOF > `pwd`/ostree/repo/config
[core]
repo_version=1
mode=bare
[remote "pulsar-linux"]
url=${OSTREE_URL}
${branch}
EOF
		cd - >/dev/null 2>&1
	fi
	if [ $CREATE_EMMC -eq 1 ]; then
		label_append="_hd"
		echo "reset label for eMMC"
		e2label ${device}p5 otaboot${label_append}
		e2label ${device}p6 otaroot${label_append}
		e2label ${device}p7 otaboot_b${label_append}
		e2label ${device}p8 otaroot_b${label_append}
		e2label ${device}p3 fluxdata${label_append}
	fi
	sync
}

if ! [ -e "/z" ]; then
        mkdir /z
fi

if [ "X$installer_sfr_image" == "XY" -o "X$installer_image" == "XY" -o "X$live_installer_image" == "XY" ]; then
	deploy_installer $device "/z"
elif [ "X$live_image" == "XY" ]; then
	deploy_live $device "/z"
elif [ "X$live_double_ot_image" == "XY" ]; then
	echo "Deploy double image"
	deploy_ostree $device "/z"
fi

echo "umount directory /z"
umount "/z"
echo "release loop device $device"
losetup -d ${device}


