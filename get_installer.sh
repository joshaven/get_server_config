#! /bin/bash
function init_install_list {
  puts "* Ensuring proper file structure in /etc/get_server_config"
  super_user_do mkdir -p /etc/get_server_config/deb
  super_user_do touch /etc/get_server_config/deb.list

  super_user_do mkdir -p /etc/get_server_config/gem
  super_user_do touch /etc/get_server_config/gem.list

  super_user_do mkdir -p /etc/get_server_config/bin
  puts "* Ensureing executable location"
  super_user_do mkdir -p /usr/local/bin
}

function puts {
  # make echo command expandable to allow verbosity.
  echo -e "$@"
}

function display_version_info {
  puts "get 0.0.2 alpha (http://github.com/joshaven/get_server_config)"
}
function display_help {
  display_version_info
  puts "Usage: get [package] "
  puts "Install applications using apt package manager."
  puts "Examples:"
  puts "  get ruby"
  puts "  get --purge ruby"
  puts "  get --rebuild"
  puts
  puts "Options:"
  puts "  --purge [package_name]  This will uninstall package and purge config"
  puts "  --rebuild               Use this option to install any missing applications"
  puts "  --version               Display version info."
  puts "  --self_install          Install get to your system"
  puts "  --self_uninstall        Remove get from path, leave config files intact"
  puts "  --self_purge            Remove get & config files (Destructive!)"
  puts "  --self_update           Download and Install current version of get"
  puts
  puts "Any .deb packages locate in /etc/get_server_config/deb will take precedence over"
  puts "any apt repositories.  Be sure to use the following naming convention:"
  puts "package_name-version.deb for any applications in the local repo."
  puts "Report any bugs to yourtech@gmail.com"
  puts "If you find this script useful please paypal my email address a buck or two!"
  puts "                                    -- Joshaven Potter <yourtech@gmail.com> --"
}

function self_installer {
  self=$0
  if [ -e /usr/local/bin/get ];then self_uninstaller;fi # Remove executable symlink
  self_version_migrator                                 # Run version migrations
  init_install_list                                     # Ensure file structure is built
  
  # Ensure path exists and copy this script to the installation folder
  super_user_do cp -f $self /etc/get_server_config/bin/get
  
  # link script into path
  if [ -e /etc/get_server_config/bin/get ]; then
    super_user_do ln -s /etc/get_server_config/bin/get /usr/local/bin/get
  else
    puts "Could not find '/etc/get_server_config/bin/get'"
    return 1
  fi
  
  # Set script as executable and symlink to a good location
  if [ -e /usr/local/bin/get ];then
    super_user_do chmod +x /usr/local/bin/get
  fi
  
  
  # Test install
  if [ -e '/usr/local/bin/get' ];then 
    puts "SUCCESSFULLY installed 'get'."
  else
    puts "Could not locate '/usr/local/bin/get'.  Erron in install."
  fi

  # Test path
  if [[ ! $PATH =~ (^|:)/usr/local/bin($|:) ]]; then
    puts -e "> It appears that '/usr/local/bin' is not part of your path.\n*** Please add '/usr/local/bin' root's path ***"
  else
    successful=1
  fi
  if [ $successful ];then
    puts "Enjoy your (get)ting.  For help try 'get --help'"
  else
    puts "Error installing get"
  fi
}

function self_version_migrator {
  if [ -e /etc/server_config ]; then
    super_user_do mv /etc/server_config /etc/get_server_config
  fi
}

function self_uninstaller {
  if [ -e /usr/local/bin/get ];then
    super_user_do rm /usr/local/bin/get
    if [ $? ];then puts "Successfully destroyed: executable"; fi
  else
    echo "No execuatables to remove, already uninstalled."
  fi
}

function self_updater {
  if [ -e /tmp/get_installer.sh ];then 
    rm /tmp/get_installer.sh
  fi
  
  if which wget>/dev/null; then
    wget -O /tmp/get_installer.sh -- http://github.com/joshaven/get_server_config/raw/master/get_installer.sh
  elif which curl>/dev/null; then
    curl -o /tmp/get_installer.sh -- http://github.com/joshaven/get_server_config/raw/master/get_installer.sh
  else
    return 1
  fi
    
  if [ -e /tmp/get_installer.sh ];then 
    puts "Downloaded updates"
    self_uninstaller # this is needed to remove the exeutable 
  else
    puts "Error Downloading new get."
    return 1
  fi
  sh /tmp/get_installer.sh --self_install
  if [ $? ];then puts "Updated Successfully"; else puts "Error Installing"; fi
  rm /tmp/get_installer.sh
}

function self_purger {
  self_uninstaller
  if [ -e /etc/get_server_config ]; then
    super_user_do rm -r /etc/get_server_config
    if [ $? ];then puts "Successfully destroyed: config files"; fi
  else
    puts "No config files to delete, already purged."
  fi
}

function super_user_do {
  if [ $(id -u) == 0 ]; then
    $@
    puts " - Did: '$@' as root"
  else
    if [ $(which sudo) ];then
      sudo $@
      puts "  - Did: '$@' through sudo"
    else
      puts "This command requires super user privilages, Please log in as root or install sudo and add $(id -un) to sudoers"
      return 1
    fi
  fi
}

function rebuild_deb {
  while read package
  do
    if [ -n "$package" ]; then  # -n tests to see if the argument is non empty
      installed=$(dpkg --list |grep "^ii  $package "|awk '{ print $2 }')
      if [ "$package" == "$installed" ]; then
        puts "$package installation confirmed."
      else
        puts
        puts "Installing $package..."
        install_packages $package
      fi
    fi
  done < "/etc/get_server_config/deb.list"
}

function install_packages {
  packages=($@) #convert string into an array
  for (( i=0; i<=${#packages[@]}-1; i++ )); do # step through array
    package=${packages[i]}
    installed=$(dpkg --list |grep "^ii  $package "|awk '{ print $2 }')
    if [ "$package" == "$installed" ]; then
      puts "$package installation confirmed."
    else
      if install_from_local $package; then
        super_user_do dpkg --install `ls /etc/get_server_config/deb/$package*.deb`
      else
        super_user_do apt-get install -y $package
      fi
    fi
  done
}

function install_from_local {
  ls -1 /etc/get_server_config/deb/$1*.deb > /dev/null 2>&1
  return $?
}

function purge_package {
  #convert string into an array
  packages=($@) 
  for (( i=0; i<=${#packages[@]}-1; i++ )); do
    ##FIXME need feature
    puts "This would purge: ${packages[$i]}... if it were written to do so"
    puts "please manually edit /etc/get_server_config/deb.list"
  done
}

function append_deb_install_list {
  packages=($@)
  #array of packages
  for (( i=0; i<=$[${#packages[@]}-1]; i++ )); do
    if ls /etc/get_server_config/deb/|grep "^${packages[$i]}-[0-9].*.deb$";then
      if package_untracked ${packages[$i]} 'deb';then
        super_user_do puts "${packages[$i]}" >> /etc/get_server_config/deb.list
      fi
    elif apt-cache search ${packages[$i]}|awk '{print $1}'|grep "^${packages[$i]}$";then
      if package_untracked ${packages[$i]} 'deb'; then
        super_user_do puts "${packages[$i]}" >> /etc/get_server_config/deb.list
      fi
    else
      puts "ERROR::Can not find package >> ${packages[$i]}"
      puts "If you are installing a custom .deb package copy it to /etc/get_server_config/deb/"
      puts "be sure to name the .deb package like: name-version.deb (ie. ruby-1.8.2-p72.deb)"
      puts
      return 1
    fi
  done
} 

function append_gem_install_list {
  packages=($@) #array of packages
  for (( i=0; i<=$[${#packages[@]}-1]; i++ )); do # step through array, i is index a is the entire array
    if ls /etc/get_server_config/gem/|grep "^${packages[$i]}-[0-9].*.gem$";then # if an existing .gem is around
      if package_untracked ${packages[$i]} 'gem';then
        super_user_do puts "${packages[$i]}" >> /etc/get_server_config/gem.list
      fi
    elif gem list ${packages[$i]}|awk '{print $1}'|grep "^${packages[$i]}$";then # if package is on a repo
      if package_untracked ${packages[$i]} 'gem'; then
        super_user_do puts "${packages[$i]}" >> /etc/get_server_config/gem.list
      fi
    else
      puts "ERROR::Can not find package >> ${packages[$i]}"
      puts "If you are installing a custom .gem package copy it to /etc/get_server_config/gem/"
      puts "be sure to name the .gem package like: name-version.deb (ie. rails-2.2.2.gem)"
      puts
      return 1
    fi
  done
}

function package_untracked {
  while read package; do
    if [ $1 == $package ];then return 1;fi
  done < "/etc/get_server_config/$2.list"
  return 0
}

##################################################################################################################
# Main
# Process:  Allows self installation without further checks. Otherwise if already installed, processessing request
#           or crying about needing to be installed.
##################################################################################################################
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
    '--purge*')
      shift
      purge_package $@
      ;;
    '--rebuild')
      rebuild_deb
      #rebuild_gem  #FIXME Need this to work
      ;;
    '--gem*')
      if super_user_do gem install $@;then
        append_gem_install_list $@
      fi
      ;;
    '--self_install')
      puts "get is allready installed."
      ;;
    '--self_uninstall')
      self_uninstaller
      ;;
    '--self_update')
      self_updater
      ;;
    '--self_purge')
      self_purger
      ;;
    *)
      if append_deb_install_list $@; then install_packages $@; fi
      ;;
    esac
  else
    puts
    puts "NOTICE: get is NOT installed!"
    puts "** Please Install by running 'sh $0 --self_install' install get"
  fi
fi