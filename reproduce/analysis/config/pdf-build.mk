# Make the final PDF?
# -------------------
#
# During the project's early phases, it is usually not necessary to build
# the PDF file (which makes a lot of output lines on the command-line and
# can make it hard to find the commands and possible errors (and their
# outputs). Also, in some cases, only the produced results may be of
# interest and not the final PDF, so LaTeX (and its necessary packages) may
# not be installed.
#
# If this variable is given any string, a PDF will be made with
# LaTeX. Otherwise, a notice will just printed that for now, no PDF will be
# created.
#
# Copyright (C) 2018-2020 Mohammad Akhlaghi <mohammad@akhlaghi.org>
#
# Copying and distribution of this file, with or without modification, are
# permitted in any medium without royalty provided the copyright notice and
# this notice are preserved.  This file is offered as-is, without any
# warranty.
pdf-build-final = yes
