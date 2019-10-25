# Makefile example for GHDL version 0.37-dev (v0.36-981-g9b18abcd) [Dunoon edition]

GHDL=ghdl
GHDLFLAGS= --ieee=synopsys
GHDLRUNFLAGS=
CLEANUP=*.cf *.vcd

# Default target : elaborate
all : run

# Elaborate target.  Almost useless
elab : force
	$(GHDL) -c $(GHDLFLAGS) -e tb_forkskinnyrb_enc
	$(GHDL) -c $(GHDLFLAGS) -e tb_forkskinnyrb_encdec

# Run target
run : force
	@make init
	$(GHDL) -c $(GHDLFLAGS) -r tb_forkskinnyrb_enc $(GHDLRUNFLAGS)
	$(GHDL) -c $(GHDLFLAGS) -r tb_forkskinnyrb_encdec $(GHDLRUNFLAGS)
	@make clean

vcd: 
	make init
	$(GHDL) -c $(GHDLFLAGS) -r tb_forkskinnyrb_enc --vcd=vcd_enc.vcd $(GHDLRUNFLAGS)
	$(GHDL) -c $(GHDLFLAGS) -r tb_forkskinnyrb_encdec --vcd=vcd_dec.vcd $(GHDLRUNFLAGS)
	rm -f *.cf


# Targets to analyze libraries
init: force
	@# /usr/local/lib/ghdl/synopsys/v93/../../src/ieee/v93/std_logic_1164.vhdl
	@# /usr/local/lib/ghdl/synopsys/v93/../../src/ieee/v93/std_logic_1164-body.vhdl
	@$(GHDL) -a $(GHDLFLAGS) ForkSkinnyPKG.vhd
	@$(GHDL) -a $(GHDLFLAGS) FSMForkSkinnyEncDec.vhd
	@$(GHDL) -a $(GHDLFLAGS) RoundConstant.vhd
	@$(GHDL) -a $(GHDLFLAGS) ScanFF.vhd
	@$(GHDL) -a $(GHDLFLAGS) SBox.vhd
	@$(GHDL) -a $(GHDLFLAGS) RoundFunction.vhd
	@$(GHDL) -a $(GHDLFLAGS) Permutation.vhd
	@$(GHDL) -a $(GHDLFLAGS) KeyExpansion.vhd
	@$(GHDL) -a $(GHDLFLAGS) InverseRoundFunction.vhd
	@$(GHDL) -a $(GHDLFLAGS) BranchConstant.vhd
	@$(GHDL) -a $(GHDLFLAGS) ForkSkinnyRB.vhd
	@$(GHDL) -a $(GHDLFLAGS) TB_ForkSkinnyRB_Enc.vhd
	@$(GHDL) -a $(GHDLFLAGS) TB_ForkSkinnyRB_EncDec.vhd

.PHONY : clean
clean :
	@rm -f $(CLEANUP)


force:
