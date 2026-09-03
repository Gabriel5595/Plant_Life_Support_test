.global _start
.extern estabelece_conexao
.extern fsm_principal
.extern lcd_inicializa
.extern inicializa_atuadores
.extern aciona_bomba
.extern aciona_luz
.extern gpio_unmap

.equ SYS_WRITE, 64
.equ SYS_EXIT,  93
.equ SYS_NANOSLEEP, 101

.section .data
msg_inicio: .asciz "\n=== Leitura do BME280 via I2C (Tang Nano) -> SPI -> Raspberry Pi ===\n"
msg_inicio_fim = . - msg_inicio - 1

msg_erro_conexao: .asciz "ERRO: nao foi possivel mapear o GPIO (/dev/gpiomem).\n"
msg_erro_conexao_fim = . - msg_erro_conexao - 1

msg_teste_leds: .asciz "[TESTE] Ligando os dois LEDs (GPIO17 e GPIO27) por 5 segundos...\n"
msg_teste_leds_fim = . - msg_teste_leds - 1

.align 8
tempo_teste_leds:
    .quad 5
    .quad 0

.section .text

_start:
    mov x0, #1
    ldr x1, =msg_inicio
    mov x2, #msg_inicio_fim
    mov x8, #SYS_WRITE
    svc #0

    bl estabelece_conexao
    cmp x1, #0
    b.ne erro_geral

    mov x19, x0              // gpio_base - precisa sobreviver ate' o fsm_principal

    bl lcd_inicializa

    mov x0, x19
    bl inicializa_atuadores

    // ---- TESTE DE DIAGNOSTICO: liga os dois LEDs por 5s ----
    // Isola se o problema esta na fiacao/GPIO (se nem aqui acender)
    // ou na logica da FSM (se aqui acender mas nunca dentro dos
    // estados MOLHAR_PLANTA/ILUMINAR_PLANTA).
    mov x0, #1
    ldr x1, =msg_teste_leds
    mov x2, #msg_teste_leds_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x19
    mov x1, #1
    bl aciona_bomba

    mov x0, x19
    mov x1, #1
    bl aciona_luz

    ldr x0, =tempo_teste_leds
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    mov x0, x19
    mov x1, #0
    bl aciona_bomba

    mov x0, x19
    mov x1, #0
    bl aciona_luz
    // ---- fim do teste de diagnostico ----

    mov x0, x19
    bl fsm_principal          // nunca retorna (loop infinito entre estados)

erro_geral:
    mov x0, #1
    ldr x1, =msg_erro_conexao
    mov x2, #msg_erro_conexao_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, #1
    mov x8, #SYS_EXIT
    svc #0
