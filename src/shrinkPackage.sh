#!/usr/bin/env bash

#
# Unifies all scripts of a package into a single file.
#
# @param dirFullPath $1
# Target directory.
#
# @param fileFullPath $2
# Full path to package new file.
#
# @param string $3
# Optional. Data to be set in package file header (before shebang).
#
# @return status
shrinkPackage() {
  local tgtDir="${1}"
  if [ ! -d "${tgtDir}" ]; then
    echo "[ x ] Error: target directory does not exists!" >&2
    return "1"
  fi

  local tgtPackage="${2}"
  if [ "${tgtPackage}" == "" ]; then
    echo "[ x ] Error: package filename cannot be empty!" >&2
    return "1"
  fi

  local strShrinkHeader="${3}"


  # 1. Get all content
  local codeNL=$'\n'
  local strPackageFileContent=""

  local pathToTargetFile=""
  for pathToTargetFile in $(find "${tgtDir}" -type f -name "*.sh" | sort); do
    strPackageFileContent+="$(< "${pathToTargetFile}")${codeNL}"
  done

  if [ "${strPackageFileContent}" == "" ]; then
    echo "[ x ] Error: target content is empty!" >&2
    return "1"
  fi



  # 2. Save file
  echo -n "${strPackageFileContent}" > "${tgtPackage}"
  if [ "$?" != "0" ]; then
    echo "[ x ] Error: on create 'package.sh' file!" >&2
    return "1"
  fi


  # 3. Validate generated content with bash parser
  #    on error will remove current file and generate a '-error' version for debug
  if ! bash -n "${tgtPackage}"; then
    echo "[ x ] Error: Selected code has sintax error; Created a '${tgtPackage}.error' for debug proposes." >&2

    mv "${tgtPackage}" "${tgtPackage}.error"
    return "1"
  fi


  # 4. Remove all comments and empty lines
  #    Preserve identation and multiline strings
  shrinkFileScript "${tgtPackage}" "" "${strShrinkHeader}"
  if [ "$?" != "0" ]; then
    echo "[ x ] Error: Fail on shrink '${tgtPackage}'; Created a '${tgtPackage}.error' for debug proposes." >&2
    
    mv "${tgtPackage}" "${tgtPackage}.error"
    return "1"

  else
    # 5 Validate again the shrink code
    if ! bash -n "${tgtPackage}"; then
      echo "[ x ] Error: Selected code has sintax error after shrink proccess; Created a '${tgtPackage}.error' for debug proposes." >&2

      mv "${tgtPackage}" "${tgtPackage}.error"
      return "1"
    fi

    echo "[ v ] Success: File '${tgtPackage}' created!"
    return "0"
  fi
}