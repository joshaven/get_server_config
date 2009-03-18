function Hash.class {
  if [[ -n $2 ]]; then    # two params => assignment
    export typeset hash_${1}=$2
    # need to track hash keys so the entire hash can be returned, deleted or keys returned...
  elif [[ -n $1 ]]; then  # one param => inquiry
    echo "$(eval echo \$hash_${1})"
  else                    # no params => whole hash
    echo no variables
  fi
}

function Hash.delete {
  # expects string   ** unimplemented
  # unalias hash_$1
}

function Hash.new {
  # expects hash name string
  # retuns function alaised as hash name string
  alias $1=Hash.class
}

# # tests
# Hash.new colors
# colors red ff0000
# colors red
# # yields => ff0000