MODULE=knight_rider

SRCDIR=../hdl
TBDIR=./hdl
GENDIR=./gen

TB_OBJ=$(GENDIR)/TB_$(MODULE).o
TB_SRC=$(TBDIR)/TB_$(MODULE).v
OBJ=$(GENDIR)/$(MODULE).o
SRC=$(SRCDIR)/$(MODULE).v $(SRCDIR)/pwm_sm.v
MSG_FILE=$(GENDIR)/msgs.txt

VCC=iverilog
INCLUDE=-I ../../include
FLAGS=-Wall

VSIM=vvp

sim: $(MSG_FILE)

$(MSG_FILE): $(TB_OBJ) 
	$(VSIM) $(TB_OBJ) > $@
	@!(cat $@ | grep FAILED && rm -rf $^)
	@(cat $@ | grep PASSED)

$(TB_OBJ): $(TB_SRC) $(SRC)
	$(VCC) $(INCLUDE) $(FLAGS) $(DEFINES) -o $@ $^

clean:
	rm -Rf ./$(GENDIR)/*
