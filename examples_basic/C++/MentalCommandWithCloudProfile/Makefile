PROJECT_ROOT=$(HOME)/work/community-sdk-master
INCLUDE_PATH=$(PROJECT_ROOT)/include
LIBRARY_PATH=$(PROJECT_ROOT)/bin/armhf

OBJS	:= MentalCommandWithCloudProfile.o
BIN	:= demo

.SUFFIXES: .cpp.o
.cpp.o:
	g++ -c $< -I$(INCLUDE_PATH)

$(BIN): $(OBJS)
	g++  $^ $(LIBRARY_PATH)/libedk.so -o $@

run: $(BIN)
	LD_LIBRARY_PATH=$(LIBRARY_PATH) ./$(BIN)

clean:
	rm -rf *.o $(BIN)

#g++ -L/home/drone/work/community-sdk/bin/linux64 MentalCommandDemo.o MentalCommandControl.o Socket.o -ledk
