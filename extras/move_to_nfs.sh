function move_to_nfs {
  # Usage 
  # ie:  to_nfs /home 10.22.88.200 vm1
  if [ $# < 3 ]; then; return 2; fi
  MOUNT=$1
  PACKETSIZE=131072
  NFSSERVER=$2
  VMNAME=$3
  MOUNTUSER=$(ls -ld $MOUNT|awk '{print $3}')
  MOUNTGROUP=$(ls -ld $MOUNT|awk '{print $4}')
  MOUNTPERMISSIONS=$(permissions_to_octal `ls -ld $MOUNT`)
  sudo mv $MOUNT /tmp
  sudo mkdir $MOUNT
  sudo chown $MOUNTUSER $MOUNT
  sudo chgroup $MOUNTGROUP $MOUNT
  sudo chmod $MOUNTPERMISSIONS $MOUNT
  sudo echo "$NFSSERVER:/nfs/$VMNAME/$MOUNT /$MOUNT nfs rw,rsize=$PACKETSIZE,wsize=$PACKETSIZE,hard,intr,async,nodev,nosuid 0 0" >> /etc/fstab
  sudo mount
  sudo mv -r "/tmp/$MOUNT/* $MOUNT/"
  sudo rm "/tmp/$MOUNT"
}

function permissions_to_octal {
  # expects text like: drwxr-xr-x 2 joshaven joshaven 4096 2009-04-13 17:21
  # The output of `ls -ld` is great!
  echo $@ | sed 's/.\(.........\).*/\1/
  h;y/rwsxtST-/IIIIIOOO/;x;s/..\(.\)..\(.\)..\(.\)/|\1\2\3/
  y/sStTx-/IIIIOO/;G
  s/\n\(.*\)/\1;OOO0OOI1OIO2OII3IOO4IOI5IIO6III7/;:k
  s/|\(...\)\(.*;.*\1\(.\)\)/\3|\2/;tk
  s/^0*\(..*\)|.*/\1/;q'
}

function best_speed {
  MOUNT=$1
  i=128
  # loop from i to less then 524288 doubleing i each loop... ie: (128,256..131072,262144)
  while [ $i -lt 524288 ]; do
    echo "########################################################"
    mount $MOUNT /mnt/ -o rw,wsize=$size
    time dd if=/dev/zero of=/mnt/test bs=16k count=16k
    echo "with a size of: $size"
    umount /mnt
    echo "########################################################"
    echo
    echo
    i=$[$i*2]
  done
}

function display_version_info { echo "Pre-Alpha 0.0.0 - Unstable" }

function display_help { echo "--speed_test 10.22.88.200:/nfs/vm2  *WARNING... this takes a while to run, be patient*" }


if [[ $@ == '--self_install' ]]; then
  self_installer $0
else
  if [ -e '/usr/local/bin/get' ]; then
    case $@ in
    '--version')
      display_version_info
      ;;
    '' | '--help')
      display_help
      ;;
    *)
      if [ $# = 3 ]; then
        move_to_nfs $@
      else
        display_help
        return 2
      fi
      ;;
    esac
  else
    puts
    puts "NOTICE: get is NOT installed!"
    puts "** Please Install by running 'sh $0 --self_install' install get"
  fi
fi