PROJECT_ROOT=$(HOME)/work/bci_drone
INCLUDE_PATH=$(PROJECT_ROOT)/include
LIBRARY_PATH=$(PROJECT_ROOT)/bin/armhf

OBJS	:= MentalCommandDemo.o MentalCommandControl.o Socket.o drone.o
STR_OBJS	:= straight.o MentalCommandControl.o Socket.o drone.o
EXP_OBJS	:= expert.o MentalCommandControl.o Socket.o drone.o

BIN	:= demo

.SUFFIXES: .cpp.o
.cpp.o:
	g++ -c $< -I$(INCLUDE_PATH)

$(BIN): $(OBJS)
	g++  $^ $(LIBRARY_PATH)/libedk.so -o $@

str: $(STR_OBJS)
	g++  $^ $(LIBRARY_PATH)/libedk.so -o $@

expert: $(EXP_OBJS)
	g++  $^ $(LIBRARY_PATH)/libedk.so -o $@

run: $(BIN)
	LD_LIBRARY_PATH=$(LIBRARY_PATH) ./$(BIN)

clean:
	rm -rf *.o $(BIN) str expert

#g++ -L/home/drone/work/community-sdk/bin/linux64 MentalCommandDemo.o MentalCommandControl.o Socket.o -ledk
