#!/usr/bin/env sh
#
# Attempt downloading multiple times before crashing whole project. From
# the top project directory (for the shebang above), this script must be
# run like this:
#
#   $ $SHELL /path/to/download-multi-try.sh downloader lockfile \
#                                           input-url downloaded-name
#
# NOTE:
# - This script doesn't have a Shebang because in different stages it
#   should be built with different shells ('/bin/sh' before Maneage
#   installs its own shell and afterwards with Maneage's own shell).
# - The 'downloader' must contain the option to specify the output name
#   in its end. For example "wget -O". Any other option can also be placed in
#   the middle.
#
# Due to temporary network problems, a download may fail suddenly, but
# succeed in a second try a few seconds later. Without this script that
# temporary glitch in the network will permanently crash the project and
# it can't continue. The job of this script is to be patient and try the
# download multiple times before crashing the whole project.
#
# LOCK FILE: Since there is usually only one network port to the outside
# world, downloading is done much faster in serial, not in parallel. But
# the project's processing may be done in parallel (with multiple threads
# needing to download different files at the same time). Therefore, this
# script uses the 'flock' program to only do one download at a time. To
# benefit from it, any call to this script must be given the same lock
# file. If your system has multiple ports to the internet, or for any
# reason, you don't want to use a lock file, set the 'lockfile' name to
# 'nolock'.
#
# Copyright (C) 2019-2026 Mohammad Akhlaghi <mohammad@akhlaghi.org>
#
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.





# Script settings
# ---------------
# Stop the script if there are any errors.
set -e





# Input arguments and necessary sanity checks. Note that the 5th argument
# (backup servers) isn't mandatory.
inurl="$3"
outname="$4"
lockfile="$2"
downloader="$1"
backupservers="$5"
if [ "x$downloader" = x ]; then
    echo "$0: downloader (first argument) not given."; exit 1;
fi
if [ "x$lockfile" = x ]; then
    echo "$0: lock file (second argument) not given."; exit 1;
fi
if [ "x$inurl" = x ]; then
    echo "$0: full input URL (third argument) not given."; exit 1;
fi
if [ "x$outname" = x ]; then
    echo "$0: output name (fourth argument) not given."; exit 1;
fi





# Separate the actual filename, to possibly use backup server.
urlfile=$(echo "$inurl" | awk -F "/" '{print $NF}')





# Function for downloading
download_func () {

    # Set the arguments.
    inurl="$1"

    # During the installation of basic software, the dependencies of the
    # downloaders that are installed in Maneage can conflict with the
    # downloader that is not yet installed in Maneage. To avoid this, we
    # check if the downloader works (with '--version') and remove the
    # Maneage library temporarily in case it does not.
    lpathorig=""
    dprog=$(echo $downloader | awk '{print $1}')
    if ! $dprog --version > /dev/null 2> /dev/null; then
        echo "NOTE: the segmentation fault is expected, is not a problem"
        basedir=$(echo $outname \
                      | sed -e's|\/tarballs\/| |' \
                      | awk '{print $1}')
        libdir=$basedir/installed/lib
        lpathorig=$LD_LIBRARY_PATH
        lpath=$(echo $LD_LIBRARY_PATH \
                    | sed -e's|'$libdir':||')
        export LD_LIBRARY_PATH=$lpath
    fi

    # Attempt downloading the file. Note that the 'downloader' ends with
    # the respective option to specify the output name. For example "wget
    # -O" (so 'outname', that comes after it) will be the name of the
    # downloaded file.
    if [ x"$lockfile" = xnolock ]; then
        if ! $downloader $outname $inurl; then rm -f $outname; fi
    else
        flock "$lockfile" sh -c \
           "if ! $downloader $outname \"$inurl\"; then rm -f $outname; fi"
    fi

    # In case the LD_LIBRARY_PATH was changed, set it back to normal.
    if ! [ x"$lpathorig" = x ]; then
        export LD_LIBRARY_PATH=$lpathorig
    fi

    # Some servers return HTTP 4xx/5xx errors as an HTML page with a 200
    # status, so the downloader exits 0 and saves the HTML body to disk.
    # Detect this by checking whether the response starts with an HTML tag
    # and treat it as a failed download so backup servers will be tried.
    if [ -f "$outname" ] \
       && head -c 500 "$outname" 2>/dev/null | grep -qi '<html'; then
        rm -f "$outname"
    fi
}





# Try downloading multiple times before crashing.
counter=0
maxcounter=10
while [ ! -f "$outname" ]; do

    # Increment the counter.
    counter=$(echo $counter | awk '{print $1+1}')

    # If we have passed a maximum number of trials, just exit with
    # a failed code.
    reachedmax=$(echo $counter \
         | awk '{if($1>'$maxcounter') print "yes"; else print "no";}')
    if [ x$reachedmax = xyes ]; then
        echo ""
	echo "Failed $maxcounter download attempts: $outname"
        echo ""
	exit 1
    fi

    # If this isn't the first attempt print a notice and wait a little for
    # the next trail.
    if [ x$counter = x1 ]; then
        just_a_place_holder=1
    else
        tstep=$(echo $counter | awk '{print $1*5}')
        echo "Download trial $counter for '$outname' in $tstep seconds."
        sleep $tstep
    fi

    # First attempt at the download.
    download_func "$inurl"

    # If the download failed, try the backup server(s).
    if [ ! -f "$outname" ]; then
        if [ x"$backupservers" != x ]; then
            for bs in $backupservers; do

                # For Zenodo backup servers, append '?download=1' as well.
                bsurl="$bs/$urlfile"
                case "$bsurl" in
                    *zenodo.org*) bsurl="${bsurl}?download=1" ;;
                esac

                # Download the file.
                download_func "$bsurl"

                # If the file was downloaded, break out of the loop that
                # parses over the backup servers.
                if [ -f "$outname" ]; then break; fi
            done
        fi
    fi
done





# Return successfully
exit 0
