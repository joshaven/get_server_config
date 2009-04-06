#! /bin/bash
function init_install_list {
  if [ ! -e /etc/server_config/deb.list ];then
      mkdir -p /etc/server_config/deb
      touch /etc/server_config/deb.list
  fi
  if [ ! -e /etc/server_config/gem.list ];then
      mkdir -p /etc/server_config/gem
      touch /etc/server_config/gem.list
  fi
}

function rebuild_deb {
  while read package
  do
    if [ -n "$package" ]; then  # -n tests to see if the argument is non empty
      installed=$(dpkg --list |grep "^ii  $package "|awk '{ print $2 }')
      if [ "$package" == "$installed" ]; then
        echo "$package installation confirmed."
      else
        echo
        echo "Installing $package..."
        install $package
      fi
    fi
  done < "/etc/server_config/deb.list"
}

function install {
  packages=($@) #convert string into an array
  for (( i=0; i<=${#packages[@]}-1; i++ )); do # step through array
    package=${packages[i]}
    installed=$(dpkg --list |grep "^ii  $package "|awk '{ print $2 }')
    if [ "$package" == "$installed" ]; then
      echo "$package installation confirmed."
    else
      if install_from_local $package; then
        dpkg --install `ls /etc/server_config/deb/$package*.deb`
      else
        apt-get install -y $package
      fi
    fi
  done
}

function install_from_local {
  ls -1 /etc/server_config/deb/$1*.deb > /dev/null 2>&1
  return $?
}

function display_help {
  echo "Usage: get [package] "
  echo "Install applications using apt package manager."
  echo "Examples:"
  echo "  get ruby"
  echo "  get --purge ruby"
  echo "  get --rebuild"
  echo
  echo "Options:"
  echo "  --purge [package_name]  This will uninstall package and purge config"
  echo "  --rebuild               Use this option to install any missing applications"
  echo "  --self_install               This will install get to your system"
  echo "  --version               Display version info."
  echo
  echo "Any .deb packages locate in /etc/server_config/deb will take precedence over"
  echo "any apt repositories.  Be sure to use the following naming convention:"
  echo "package_name-version.deb for any applications in the local repo."
  echo "Report any bugs to yourtech@gmail.com"
  echo "If you have found this script useful please paypal my email address a buck or two!"
  echo "                                    -- Joshaven Potter <yourtech@gmail.com>"
}

function purge_package {
  #convert string into an array
  packages=($@) 
  for (( i=0; i<=${#packages[@]}-1; i++ )); do
    ##FIXME need feature
    echo "This would purge: ${packages[$i]}... if it were written to do so"
    echo "please manually edit /etc/server_config/deb.list"
  done
}

function append_deb_install_list {
  packages=($@)
  #array of packages
  for (( i=0; i<=$[${#packages[@]}-1]; i++ )); do
    if ls /etc/server_config/deb/|grep "^${packages[$i]}-[0-9].*.deb$";then
      if package_untracked ${packages[$i]} 'deb';then
        echo "${packages[$i]}" >> /etc/server_config/deb.list
      fi
    elif apt-cache search ${packages[$i]}|awk '{print $1}'|grep "^${packages[$i]}$";then
      if package_untracked ${packages[$i]} 'deb'; then
        echo "${packages[$i]}" >> /etc/server_config/deb.list
      fi
    else
      echo "ERROR::Can not find package >> ${packages[$i]}"
      echo "If you are installing a custom .deb package copy it to /etc/server_config/deb/"
      echo "be sure to name the .deb package like: name-version.deb (ie. ruby-1.8.2-p72.deb)"
      echo
      return 1
    fi
  done
} 

function append_gem_install_list {
  packages=($@) #array of packages
  for (( i=0; i<=$[${#packages[@]}-1]; i++ )); do # step through array, i is index a is the entire array
    if ls /etc/server_config/gem/|grep "^${packages[$i]}-[0-9].*.gem$";then # if an existing .gem is around
      if package_untracked ${packages[$i]} 'gem';then
        echo "${packages[$i]}" >> /etc/server_config/gem.list
      fi
    elif gem list ${packages[$i]}|awk '{print $1}'|grep "^${packages[$i]}$";then # if package is on a repo
      if package_untracked ${packages[$i]} 'gem'; then
        echo "${packages[$i]}" >> /etc/server_config/gem.list
      fi
    else
      echo "ERROR::Can not find package >> ${packages[$i]}"
      echo "If you are installing a custom .gem package copy it to /etc/server_config/gem/"
      echo "be sure to name the .gem package like: name-version.deb (ie. rails-2.2.2.gem)"
      echo
      return 1
    fi
  done
}

function package_untracked {
  while read package; do
    if [ $1 == $package ];then return 1;fi
  done < "/etc/server_config/$2.list"
  return 0
}

function check_validity {
  echo "locating packages"
  packages=($@)
  for (( i=0; i<=$[${#packages[@]}-1]; i++ )); do # step through array, i is index a is the entire array
    if apt-cache search ruby|awk '{print $1}'|grep "^${packages[$i]}$";then # if package is on an apt repo
      echo .
    elif ls /etc/server_config/deb/|grep "^${packages[$i]}-[0-9].*.deb$";then #else if an existing .deb is around
      echo . 
    else
      return 1
    fi
  done
}

function get_self_installer {
  # Ensure path exists and copy this script to the installation folder
  mkdir -p /etc/get_server_config/bin/
  cp -f $0 /etc/get_server_config/bin/get
  # Set script as executable and symlink to a good location
  chmod +x /etc/get_server_config/bin/*
  mkdir -p /usr/local/bin
  ln -s /etc/get_server_config/bin/get /usr/local/bin/get
  # Test install
  if [ -e '/usr/local/bin/get' ]
    then echo "> 'get' was installed successfully"
  fi
  # Test path
  
  if [[ ! $PATH =~ (^|:)/usr/local/bin($|:) ]]; then
  echo -e "> It appears that '/usr/local/bin' is not part of your path.\n*** Please add '/usr/local/bin' root's path ***"
  fi
  echo "Enjoy your (get)ting"
}

function super_user_do {
  if [ $(id -u) == 0 ]; then
    $@
  else
    if [ $(which sudo) ];then
      sudo $@
    else
      echo "This command requires super user privilages, Please log in as root or install sudo and add $(id -un) to sudoers"
      return 1
    fi
  fi
}


if [ ! -e '/usr/local/bin/get' ]; then
  echo "NOTICE: This package is NOT installed!"
  echo "Please Install run with --self_install option to install this package"
fi

# It may be nice to import .deb packages or build_from source as options from get so that populating the ./deb does not
# have to be manual 
init_install_list
case $@ in
'--version')
  echo "get 0.0.1 (http://github.com/joshaven/get_server_config)"
  ;;
'^$' | '--help$')
  super_user_do display_help
  ;;
'--purge*')
  shift
  super_user_do purge_package $@
  ;;
'--rebuild')
  super_user_do rebuild_deb
  #rebuild_gem  #FIXME Need this to work
  ;;
'--gem*')
  if super_user_do gem install $@;then
    super_user_do append_gem_install_list $@
  fi
  ;;
'--self_install')
  super_user_do get_self_installer $0
  ;;
*)
  if append_deb_install_list $@; then
    install $@
  fi
  ;;
esac  
