# Dummy Makefile to create a random dataset for plotting.
#
# Copyright (C) 2018-2023 Mohammad Akhlaghi <mohammad@akhlaghi.org>
#
# This Makefile is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This Makefile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this Makefile.  If not, see <http://www.gnu.org/licenses/>.





# Demo image PDF
# --------------
#
# For an example image, we'll make a PDF copy of the WFPC II image to
# display in the paper.
dm-histdir = $(texdir)/image-histogram
$(dm-histdir): | $(texdir); mkdir $@
dm-img-pdf = $(dm-histdir)/wfpc2.pdf
$(dm-img-pdf): $(dm-histdir)/%.pdf: $(indir)/%.fits | $(dm-histdir)

#	When the plotted values are re-made, it is necessary to also
#	delete the TiKZ externalized files so the plot is also re-made.
	rm -f $(tikzdir)/delete-me-image-histogram.pdf

#	Convert the dataset to a PDF.
	astconvertt --colormap=gray --fluxhigh=4 $< -h0 -o$@





# Histogram of demo image
# -----------------------
#
# For an example plot, we'll show the pixel value histogram also. IMPORTANT
# NOTE: because this histogram contains data that is included in a plot, we
# should publish it, so it will go into the $(tex-publish-dir).
dm-img-histogram = $(tex-publish-dir)/wfpc2-histogram.txt
$(dm-img-histogram): $(tex-publish-dir)/%-histogram.txt: $(indir)/%.fits \
                     | $(tex-publish-dir)

#	When the plotted values are re-made, it is necessary to also delete
#	the TiKZ externalized files so the plot is also re-made.
	rm -f $(tikzdir)/delete-me-image-histogram.pdf

#	Generate the pixel value histogram.
	aststatistics --lessthan=5 $< -h0 --histogram -o$@.data

#	Put a two-line description of the dataset, copy the column metadata
#	from '$@.data', and add copyright.
	echo "# Histogram of example image to demonstrate Maneage (MANaging data linEAGE)." \
	     > $@.tmp
	echo "# Example image URL: $(DEMO-URL)" >> $@.tmp
	echo "# " >> $@.tmp
	awk '/^# Column .:/' $@.data >> $@.tmp
	echo "# " >> $@.tmp
	$(call print-general-metadata, $@.tmp)

#	Add the column numbers in a formatted manner, rename it to the
#	output and clean up.
	awk '!/^#/{printf("%-15.4f%d\n", $$1, $$2)}' $@.data >> $@.tmp
	mv $@.tmp $@
	rm $@.data





# Basic statistics
# ----------------
#
# This is just as a demonstration on how to get analysic configuration
# parameters from variables defined in 'reproduce/analysis/config/'.
dm-img-stats = $(dm-histdir)/wfpc2-stats.txt
$(dm-img-stats): $(dm-histdir)/%-stats.txt: $(indir)/%.fits \
                 | $(dm-histdir)
	aststatistics $< -h0 --mean --median > $@





# TeX macros
# ----------
#
# This is how we write the necessary parameters in the final PDF.
#
# NOTE: In LaTeX you cannot use any non-alphabetic character in a variable
# name.
$(mtexdir)/delete-me.tex: $(dm-img-pdf) $(dm-img-histogram) \
                          $(dm-img-stats)

#	Write the number of random values used.
	echo "\newcommand{\deletemenum}{$(delete-me-squared-num)}" > $@

#	Write the statistics of the demo image as a macro.
	mean=$$(awk     '{printf("%.2f", $$1)}' $(dm-img-stats))
	echo "\newcommand{\deletemewfpctwomean}{$$mean}"          >> $@
	median=$$(awk   '{printf("%.2f", $$2)}' $(dm-img-stats))
	echo "\newcommand{\deletemewfpctwomedian}{$$median}"      >> $@
