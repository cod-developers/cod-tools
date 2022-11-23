include Makeconf

.PHONY: all clean distclean cleanAll

.INTERMEDIATE: ${PARTS}

MODULE_NAME      ?= AtomProperties
YAML_MODULE       = modules/${MODULE_NAME}.yaml
PERL_MODULE      ?= modules/${MODULE_NAME}.pm
NAMESPACE_PREFIX ?= COD::
NAMESPACE        ?= ${NAMESPACE_PREFIX}${MODULE_NAME}

PATCH_DIR ?= patches/enabled
PATCHES = $(wildcard $(PATCH_DIR)/*.yaml)

all: ${PERL_MODULE} ${YAML_MODULE}

${PERL_MODULE}: ${PARTS} ${PATCHES}
	grep -h -P "#(Source|Descrp)" $^ > $@
	bin/atom_properties_merge --no-fill-missing $^ -p -n ${NAMESPACE} -o >> $@

${YAML_MODULE}: ${PARTS} ${PATCHES}
	grep -h -P "#(Source|Descrp)" $^ > $@
	bin/atom_properties_merge --no-fill-missing $^ -y -o >> $@

core.yaml:
	${CORE_DIR}/core ${CORE_DIR}/input.yaml > $@

cov.yaml:
	${COV_DIR}/covalent_radii ${COV_DIR}/input.yaml > $@

vdw.yaml:
	${VDW_DIR}/vdw_radii ${VDW_DIR}/input.yaml > $@

spin.yaml:
	${SPIN_DIR}/spin_state_radii ${SPIN_DIR}/input.yaml > $@

oxi.yaml:
	${OXI_DIR}/oxidation_states ${OXI_DIR}/input.yaml > $@

val.yaml:
	${VAL_DIR}/valence ${VAL_DIR}/input.yaml > $@

clean:
	rm -rf ${PARTS}

distclean cleanAll: clean
	rm -rf ${PERL_MODULE} ${YAML_MODULE}
