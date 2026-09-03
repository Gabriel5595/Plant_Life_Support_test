AS      = as
LD      = ld
OBJDUMP = objdump
GDB     = gdb

TARGET  = main

OBJS = main.o estabelece_conexao.o recebe_info.o gpio.o \
       converte_temp.o converte_luz.o converte_umidade_ar.o converte_umidade_solo.o \
       coeficientes_calibracao.o tabelas_amostras.o calcula_info.o atuadores.o eh_dia.o \
       fsm_principal.o usa_lcd.o apresenta_info_em_tela.o

all: main

main: $(OBJS)
	ld -o main $(OBJS)

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

tabelas_amostras.o: tabelas_amostras.s
	as -g -o tabelas_amostras.o tabelas_amostras.s

calcula_info.o: calcula_info.s
	as -g -o calcula_info.o calcula_info.s

atuadores.o: atuadores.s
	as -g -o atuadores.o atuadores.s

eh_dia.o: eh_dia.s
	as -g -o eh_dia.o eh_dia.s

fsm_principal.o: fsm_principal.s
	as -g -o fsm_principal.o fsm_principal.s

usa_lcd.o: usa_lcd.s
	as -g -o usa_lcd.o usa_lcd.s

apresenta_info_em_tela.o: apresenta_info_em_tela.s
	as -g -o apresenta_info_em_tela.o apresenta_info_em_tela.s

run: main
	sudo ./main

debug: main
	sudo gdb ./main

disasm: main
	objdump -d main

clean:
	rm -f $(OBJS) main
