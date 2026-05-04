PROJ = fpga
BUILD = ./build
DEVICE = --up5k
TOP = top

FILES = driver.v top.v
PCF = pinmap.pcf

all: $(BUILD)/$(PROJ).bin

clean:
	rm -rf build

.PHONY: all clean

$(BUILD)/$(PROJ).blif $(BUILD)/$(PROJ).json: $(FILES)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top $(TOP) -blif $(BUILD)/$(PROJ).blif -json $(BUILD)/$(PROJ).json" $(FILES)

$(BUILD)/$(PROJ).asc: $(BUILD)/$(PROJ).json $(PCF)
	# place and route using nextpnr
	nextpnr-ice40 $(DEVICE) --json $(BUILD)/$(PROJ).json --pcf $(PCF) --asc $(BUILD)/$(PROJ).asc

$(BUILD)/$(PROJ).bin: $(BUILD)/$(PROJ).asc
	# convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin
