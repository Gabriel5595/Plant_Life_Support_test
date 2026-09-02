AS      = as
LD      = ld
OBJDUMP = objdump
GDB     = gdb

TARGET  = main

all: main

main: main.o estabelece_conexao.o recebe_info.o gpio.o converte_temp.o converte_luz.o converte_umidade_ar.o converte_umidade_solo.o coeficientes_calibracao.o
	ld -o main main.o estabelece_conexao.o recebe_info.o gpio.o converte_temp.o converte_luz.o converte_umidade_ar.o converte_umidade_solo.o coeficientes_calibracao.o

main.o: main.s
	as -g -o main.o main.s

estabelece_conexao.o: estabelece_conexao.s
	as -g -o estabelece_conexao.o estabelece_conexao.s

recebe_info.o: recebe_info.s
	as -g -o recebe_info.o recebe_info.s

gpio.o: gpio.s
	as -g -o gpio.o gpio.s

converte_temp.o: converte_temp.s
	as -g -o converte_temp.o converte_temp.s

converte_luz.o: converte_luz.s
	as -g -o converte_luz.o converte_luz.s

converte_umidade_ar.o: converte_umidade_ar.s
	as -g -o converte_umidade_ar.o converte_umidade_ar.s

converte_umidade_solo.o: converte_umidade_solo.s
	as -g -o converte_umidade_solo.o converte_umidade_solo.s

coeficientes_calibracao.o: coeficientes_calibracao.s
	as -g -o coeficientes_calibracao.o coeficientes_calibracao.s

run: main
	sudo ./main

debug: main
	sudo gdb ./main

disasm: main
	objdump -d main

clean:
	rm -f main.o estabelece_conexao.o recebe_info.o gpio.o converte_temp.o converte_luz.o converte_umidade_ar.o converte_umidade_solo.o coeficientes_calibracao.o main
