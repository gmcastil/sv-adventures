.PHONY:
all: work top

.PHONY: work
work:
	rm -rf work
	vlib work

.PHONY: top
top: work
	vlog -work work -sv "../basys3/sim/interfaces/axi4l_if.sv"
	vlog -work work -sv "top.sv"

.PHONY: clean

