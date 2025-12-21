#!/usr/bin/env bash

#
# Check if the given string is a code that's starting a here-doc.
#
# @param string $1
# String.
#
# @return string
# Empty if not open a heredoc
# Or the respective heredoc delimiter.
shrinkCheckOpenHeredoc() {
  local strLine="${1}"
  strLine="${strLine#"${strLine%%[![:space:]]*}"}" # trim L
  strLine="${strLine//<<</}" # Remove herestring ini


  if [[ "${strLine}" =~ (^|[^\"\'])(\<\<-?)([[:space:]]*)([A-Za-z0-9_]+|\'[^\']*\'|\"[^\"]*\") ]]; then
    local delimiter="${BASH_REMATCH[4]}"

    # Remove single quotes on start/end
    delimiter="${delimiter%'}"
    delimiter="${delimiter#'}"

    # Remove double quotes on start/end
    delimiter="${delimiter%\"}"
    delimiter="${delimiter#\"}"

    echo -ne "${delimiter}"
  fi
}