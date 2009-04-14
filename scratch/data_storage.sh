# hash object
function Hash {
  if [ $# = 3 ]; then # three or more param: assignment
    export "hash_${1}_${2}=\$3"
  elif [ $# = 2 ]; then # two params: inquiry
    echo "$(eval echo \$hash_${1}_${2})"
  elif [ $# = 1 ]; then # one param: create a hash instance
    eval "function ${1} { Hash $1 \$@; }";
  else
    echo "Usage:"
    echo "$ Hash colors"
    echo "$ colors red f00"
    echo "$ colors red"
    echo "\"f00\""
  fi
}

function Array {
  if [ $# = 2 ]; then # two or more params: assignment (ie: Array tests 123 45 6)
    arg=$1;shift
    params=$@
    echo params:${params[@]}
    export "array_${arg}"=${params[@]};fi;};Array me one two
  elif [ $# = 1 ]; then # one params: Array inquiry (ie: Array tests OR Array instantiation)
    if [ "\$array_$1" ] # if var exists then give it
      echo "$(eval echo \${array_$1[@]})"
    else # else make the instantize the Array
      eval "function ${1} { Array $1 \$@ }"
    fi
  else # Array call to self 
    echo "Declare Array:        Aray people"
    echo "Assignment to Array:  people Josh Daniel John Ben"
    echo "Inquiry to Array:     people"
    echo "concat Array:         people.concat Joseph"
    echo 'enumerate Array:      people.each {echo "First Name: $1"}'
  fi
}

Array hex_vals
hex_vals concat f00
hex_vals concat 0f0
hex_vals size
Array << f000
 
Hash colors
colors red f00
colors green 0f0
colors blue 00f
colors red
echo $hash_colors_keys