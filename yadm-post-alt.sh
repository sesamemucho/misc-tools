#!/bin/bash
# post_alt hook file for yadm
# Copyright (C) 2020 Bob Forgey

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

for i in $(find . -name \*##\* -prune)
do
    if [[ -d $i ]]
    then
        dirlist+=($i)
    else
        filelist+=($i)
    fi
done

#echo dirlist is "${dirlist[@]}"
#echo filelist is "${filelist[@]}"

dlist="${dirlist[@]%%##*}"
flist="${filelist[@]%%##*}"

#echo dlist is "${dlist[@]}"
#echo flist is $(echo "${flist[@]}" | sort)

unison_file=$(mktemp)

echo "# unison ignore list for yadm link targets" > "${unison_file}"
echo "# Automatically created on "$(date) >> "${unison_file}"
for j in ${flist[@]}+${dlist[@]}
do
    echo "ignore = Path "$j
done | sort -u >> "${unison_file}"

if [[ ! -e ~/.unison/ignore-yadm.prf ]]
then
    touch ~/.unison/ignore-yadm.prf
fi

# Only change ignore-yadm.prf if it's actually different (ignore the
# always-updated date line though)
if diff -q -I 'Automatically created' "${unison_file}" ~/.unison/ignore-yadm.prf >/dev/null
then
    # The files are the same
    true
else
    cp -v "${unison_file}" ~/.unison/ignore-yadm.prf
fi

rm "${unison_file}"

for j in ${dlist[@]}
do
    link-dirs ${j}##*
done
