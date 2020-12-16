#!/bin/bash
# scan_letter_1side - Scan letter-size, 1 side, convert to pdf
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

set -e

out=${1:?Need a file name for output}
rm -f /tmp/a.tiff /tmp/sc*.tiff
scanimage -d "fujitsu:ScanSnap S1500:20909" --mode=Lineart --resolution=300 --ald=yes --page-width=216 --page-height=700 -x 216 -y 700 --format=tiff --batch="/tmp/sc%d.tiff"
tiffcp /tmp/sc*.tiff /tmp/a.tiff
tiff2pdf -j -o "$out" /tmp/a.tiff
