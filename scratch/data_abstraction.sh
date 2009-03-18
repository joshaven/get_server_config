function parse_file {
  # to define the field sporator set IFS
  # ie:
  # IFS=$','
  #   vals='/mnt,/var/lib/vmware/Virtual Machines,/dev,/proc,/sys,/tmp,/usr/portage,/var/tmp'
  #   for i in $vals; do echo $i; done
  #   unset IFS
  
}

function readconf {
  # looks for options in a config file
  # ie: if blah.conf contained:
  # default {
  #  COOLNESS = "very"
  # }
  # CONFIG = blah.conf
  # readconf default
  match=0
  while read line; do
  [[ ${line:0:1} == "#" ]] && continue              # skip comments
  [[ -z "$line" ]] && continue                      # skip empty lines
  if [ $match == 0 ]; then                          # still no match? lets check again
    if [[ ${line:$((${#line}-1))} == "{" ]]; then   # do we have an opening tag ?
      group=${line:0:$((${#line}-1))}               # strip "{"
      group=${group// /}                            # strip whitespace
      if [[ "$group" == "$1" ]]; then               # do we have a match ?
        match=1
        continue
      fi
      continue
    fi
  elif [[ ${line:0} == "}" && $match == 1 ]]; then  # found closing tag after config was read - exit loop
    break
  else                                              # got a config line eval it
      eval $line
  fi
  done < "$CONFIG"
}
