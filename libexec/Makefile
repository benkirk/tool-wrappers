SHELL := /bin/bash

# here we go through some gymnastics to force ratamount to use its
# libfuse3 implemenetation, even though we might have libfuse2 on the host.
# this is necessary to be able to fusermount onto GPFS & Lustre file systems,
# a capability added to libfuse3
# (https://github.com/libfuse/libfuse/pull/309)
ratarmount-env: ratarmount.yaml /usr/bin/fusermount3 Makefile
	[ -d $@ ] && mv $@ $@.old && rm -rf $@.old &
	$(MAKE) solve-$@
	module load conda && conda env create --file $< --prefix $@
	module load conda && conda activate ./$@ && conda-tree deptree --small 2>/dev/null || conda list
	module load conda && conda activate ./$@ && ln -sf /usr/bin/fusermount3 $$CONDA_PREFIX/bin/fusermount && fusermount --version
	module load conda && conda activate ./$@ && python3 -m pip install --force-reinstall 'git+https://github.com/mxmlnkn/ratarmount.git@develop#egginfo=ratarmountcore&subdirectory=core' 'git+https://github.com/mxmlnkn/ratarmount.git@develop#egginfo=ratarmount'
	module load conda && conda activate ./$@ && find $$CONDA_PREFIX/lib -name fuse.py | xargs sed -i "s:find_library[(]'fuse'[)]:find_library('fuse3'):g"

solve-%-env: %.yaml
	module load conda && conda env create --file $< --prefix $@ --dry-run
