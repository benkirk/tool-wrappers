SHELL := /bin/bash

# here we go through some gymnastics to force ratamount to use its
# libfuse3 implemenetation, even though we might have libfuse2 on the host.
# this is necessary to be able to fusermount onto GPFS & Lustre file systems,
# a capability added to libfuse3
# (https://github.com/libfuse/libfuse/pull/309)
ratarmount-env: ratarmount.yaml /usr/bin/fusermount3 Makefile
	[ -d $@ ] && mv $@ $@.old && rm -rf $@.old &
	@echo "Creating conda environment $@..."
	$(MAKE) solve-$@
	module load conda && conda env create --file $< --prefix $@
	module load conda && conda activate ./$@ && conda-tree deptree --small 2>/dev/null || conda list
	module load conda && conda activate ./$@ && ln -sf /usr/bin/fusermount3 $$CONDA_PREFIX/bin/fusermount && fusermount --version
	module load conda && conda activate ./$@ && python3 -m pip install --force-reinstall 'git+https://github.com/mxmlnkn/ratarmount.git@develop#egginfo=ratarmountcore&subdirectory=core' 'git+https://github.com/mxmlnkn/ratarmount.git@develop#egginfo=ratarmount'
	module load conda && conda activate ./$@ && find $$CONDA_PREFIX/lib -name fuse.py | xargs sed -i "s:find_library[(]'fuse'[)]:find_library('fuse3'):g"

solve-%-env: %.yaml
	module load conda && conda env create --file $< --prefix $@ --dry-run


%.sqfs: Makefile
	TMPDIR=/var/tmp/$${USER}-charliecloud ; \
	mkdir -p $${TMPDIR} ; \
	rm -rf /var/tmp/$${USER}.ch ; \
	ch-image pull benjaminkirk/$(patsubst %.sqfs,%,$@):latest ; \
	ch-image list ; \
	ch-convert benjaminkirk/$(patsubst %.sqfs,%,$@):latest $@ ; \
	rm -rf /var/tmp/$${USER}.ch

%.sif: Makefile
	TMPDIR=/var/tmp/$${USER}-singularity ; \
	mkdir -p $${TMPDIR} ; \
	singularity pull $@ docker://benjaminkirk/$(patsubst %.sif,%,$@):latest

clean:
	rm -f *.sif *~ *.sh.o*

clobber:
	$(MAKE) clean
	chmod -R u+rwX ./*sandbox/ >/dev/null 2>&1
	rm -rf ./*sandbox/ ./mask/ *.sqfs
