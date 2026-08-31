AS      = as
LD      = ld
OBJDUMP = objdump
GDB     = gdb

TARGET  = main

all: main

main: main.o estabelece_conexao.o recebe_info.o gpio.o
	ld -o main main.o estabelece_conexao.o recebe_info.o gpio.o

main.o: main.s
	as -g -o main.o main.s

estabelece_conexao.o: estabelece_conexao.s
	as -g -o estabelece_conexao.o estabelece_conexao.s

recebe_info.o: recebe_info.s
	as -g -o recebe_info.o recebe_info.s

gpio.o: gpio.s
	as -g -o gpio.o gpio.s

run: main
	sudo ./main

debug: main
	sudo gdb ./main

disasm: main
	objdump -d main

clean:
	rm -f main.o estabelece_conexao.o recebe_info.o gpio.o main
