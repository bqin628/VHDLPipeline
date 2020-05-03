GHDL = ghdl
GHDL_SIM_OPT = --stop-time=$(TIME)
GHDL_FLAGS = --ieee=synopsys -fexplicit
SIMDIR = sim_dir
ifndef TIME
	TIME = 3000ns
endif

#depending on your project - you'll probably only
#have to change the next two lines
SRC = pipe_reg1.vhd pipe_reg2.vhd pipe_reg3.vhd pipe_reg4.vhd ps_clock.vhd ps_control.vhd ps_decode.vhd ps_execute.vhd ps_fetch.vhd ps_memory.vhd spim_pipe.vhd
TOP_ENTITY = spim_pipe

$(SIMDIR):
	mkdir -p $(SIMDIR)
	$(GHDL) -i --workdir=$(SIMDIR) $(SRC)

$(TOP_ENTITY).ghw :$(SRC) $(SIMDIR)
	$(GHDL) -m $(GHDL_FLAGS) -o $(SIMDIR)/$(TOP_ENTITY) --workdir=$(SIMDIR)/ $(TOP_ENTITY)
	cd $(SIMDIR);$(GHDL) -r $(TOP_ENTITY) --ieee-asserts=disable --stop-time=$(TIME) --wave=$(TOP_ENTITY).ghw --vcd=$(TOP_ENTITY).vcd

clean :
	rm -rf $(SIMDIR)

sim: $(TOP_ENTITY).ghw

.PHONY : sim