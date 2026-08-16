export DESIGN_TOP := mosaic_module
export TB_TOP := $(DESIGN_TOP)_tb
export FORMAL_TOP := $(DESIGN_TOP)_formal
export DUT_INSTANCE := $(TB_TOP)/dut
export FLOW_CONFIG_ROOT := $(MODULE_ROOT)/flows
export RTL_FILELIST := $(MODULE_ROOT)/filelists/rtl.f
export TB_FILELIST := $(MODULE_ROOT)/filelists/tb.f
export VERILATOR_WAIVER_FILE := $(FLOW_CONFIG_ROOT)/verilator_lint/waivers.vlt
export VERIBLE_WAIVER_FILE := $(FLOW_CONFIG_ROOT)/verible/waivers.txt
export VERIBLE_RULES_FILE := $(FLOW_CONFIG_ROOT)/verible/rules
export FORMAL_CONFIG := $(FLOW_CONFIG_ROOT)/symbiyosys/formal.sby
export EQUIVALENCE_CONFIG := $(FLOW_CONFIG_ROOT)/eqy/equivalence.eqy
export OPENROAD_CONFIG := $(FLOW_CONFIG_ROOT)/openroad/config.mk
export SYNTHESIS_CONSTRAINT_FILE := $(FLOW_CONFIG_ROOT)/synthesis/timing.sdc
export CDC_CONFIG := $(FLOW_CONFIG_ROOT)/cdc/constraints.tcl
export DFT_CONFIG := $(FLOW_CONFIG_ROOT)/sg_dft/constraints.tcl
export UPF_CONFIG := $(FLOW_CONFIG_ROOT)/vc_lp/power.upf
export CONSTRAINT_DIR := $(FLOW_CONFIG_ROOT)/synthesis
export REPORT_DIR := $(MODULE_ROOT)/reports
export WORK_DIR := $(MODULE_ROOT)/work
export OPENROAD_PLATFORM ?= nangate45

# Override in CI or a site-local, untracked environment file.
export TECH_SETUP_TCL ?=
export TARGET_LIBRARY ?=
export LINK_LIBRARY ?=
export OPERATING_CONDITION ?=
export ACTIVITY_FILE ?=$(WORK_DIR)/vcs_sim/$(DESIGN_TOP).saif
