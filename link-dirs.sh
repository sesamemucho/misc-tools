#!/bin/bash
# link-dirs - script for yadm hook to manage directories
# Parts Copyright (C) 2020 Bob Forgey

# The functions were copied from
# https://github.com/TheLocehiliosan/yadm/blob/master/yadm and
# simplified by using assumptions that are correct for my system, but
# that yadm generalized.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script handles directories similarly to how yadm handles files,
# in that it automatically links alternative directories to a
# basename, but it does not then use git.

LSB_RELEASE_PROGRAM="lsb_release"
OS_RELEASE="/etc/os-release"
OPERATING_SYSTEM="Unknown"

function config()
{
    git config "$1"
}

function query_distro() {
  distro=""
  if command -v "$LSB_RELEASE_PROGRAM" &> /dev/null; then
    distro=$($LSB_RELEASE_PROGRAM -si 2>/dev/null)
  elif [ -f "$OS_RELEASE" ]; then
    while IFS='' read -r line || [ -n "$line" ]; do
      if [[ "$line" = ID=* ]]; then
        distro="${line#ID=}"
        break
      fi
    done < "$OS_RELEASE"
  fi
  echo "$distro"
}

function set_local_alt_values() {

  local_class="$(config local.class)"

  local_system="$(config local.os)"
  if [ -z "$local_system" ] ; then
    local_system="$OPERATING_SYSTEM"
  fi

  local_host="$(config local.hostname)"
  if [ -z "$local_host" ] ; then
    local_host=$(uname -n)
    local_host=${local_host%%.*} # trim any domain from hostname
  fi

  local_user="$(config local.user)"
  if [ -z "$local_user" ] ; then
    local_user=$(id -u -n)
  fi

  local_distro="$(query_distro)"

}

function score_file() {
  src="$1"
  tgt="${src%%##*}"
  conditions="${src#*##}"

  if [ "${tgt#$YADM_ALT/}" != "${tgt}" ]; then
    tgt="${YADM_WORK}/${tgt#$YADM_ALT/}"
  fi

  score=0
  IFS=',' read -ra fields <<< "$conditions"
  for field in "${fields[@]}"; do
    label=${field%%.*}
    value=${field#*.}
    [ "$field" = "$label" ] && value="" # when .value is omitted
    score=$((score + 1000))
    # default condition
    if [[ "$label" =~ ^(default)$ ]]; then
      score=$((score + 0))
    # variable conditions
    elif [[ "$label" =~ ^(o|os)$ ]]; then
      if [ "$value" = "$local_system" ]; then
        score=$((score + 1))
      else
        score=0
        return
      fi
    elif [[ "$label" =~ ^(d|distro)$ ]]; then
      if [ "$value" = "$local_distro" ]; then
        score=$((score + 2))
      else
        score=0
        return
      fi
    elif [[ "$label" =~ ^(c|class)$ ]]; then
      if [ "$value" = "$local_class" ]; then
        score=$((score + 4))
      else
        score=0
        return
      fi
    elif [[ "$label" =~ ^(h|hostname)$ ]]; then
      if [ "$value" = "$local_host" ]; then
        score=$((score + 8))
      else
        score=0
        return
      fi
    elif [[ "$label" =~ ^(u|user)$ ]]; then
      if [ "$value" = "$local_user" ]; then
        score=$((score + 16))
      else
        score=0
        return
      fi
    # templates
    elif [[ "$label" =~ ^(t|template|yadm)$ ]]; then
      score=0
      cmd=$(choose_template_cmd "$value")
      if [ -n "$cmd" ]; then
        record_template "$tgt" "$cmd" "$src"
      else
        debug "No supported template processor for template $src"
        [ -n "$loud" ] && echo "No supported template processor for template $src"
      fi
      return 0
    # unsupported values
    else
      INVALID_ALT+=("$src")
      score=0
      return
    fi
  done

  record_score "$score" "$tgt" "$src"
}

function record_score() {
  score="$1"
  tgt="$2"
  src="$3"

  # record nothing if the score is zero
  [ "$score" -eq 0 ] && return

  # search for the index of this target, to see if we already are tracking it
  index=-1
  for search_index in "${!alt_targets[@]}"; do
    if [ "${alt_targets[$search_index]}" = "$tgt" ]; then
        index="$search_index"
        break
    fi
  done
  # if we don't find an existing index, create one by appending to the array
  if [ "$index" -eq -1 ]; then
    alt_targets+=("$tgt")
    # set index to the last index (newly created one)
    for index in "${!alt_targets[@]}"; do :; done
    # and set its initial score to zero
    alt_scores[$index]=0
  fi

  # record nothing if a template command is registered for this file
  [ "${alt_template_cmds[$index]+isset}" ] && return

  # record higher scoring sources
  if [ "$score" -gt "${alt_scores[$index]}" ]; then
    alt_scores[$index]="$score"
    alt_sources[$index]="$src"
  fi

}


set_local_alt_values

for i in "$@"
do
    score_file "$i"
done

src="${alt_sources[0]}"
tgt="${alt_targets[0]}"
# echo link ${alt_targets[0]} to ${alt_sources[0]}

if [[ ! -e $tgt ]]
then
    # echo source file \"$tgt\" does not exist. OK to link.
    true
elif [[ ! -L $tgt ]]
then
    echo source file \"$tgt\" exists but is not a link. Error case.
    exit 1
else
    # echo source file \"$tgt\" is a link. Remove and re-link
    rm "$tgt"
fi

echo Linking $tgt to $src
ln -s $(basename "$src") "$tgt"
