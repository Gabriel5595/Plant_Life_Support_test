.global _start
.extern estabelece_conexao
.extern recebe_info
.extern gpio_unmap

.equ SYS_WRITE, 64
.equ SYS_EXIT,  93
.equ SYS_NANOSLEEP, 101

.section .data
msg_inicio: .asciz "\n=== Leitura do BME280 via I2C (Tang Nano) -> SPI -> Raspberry Pi ===\n"
msg_inicio_fim = . - msg_inicio - 1

msg_erro_conexao: .asciz "ERRO: nao foi possivel mapear o GPIO (/dev/gpiomem).\n"
msg_erro_conexao_fim = . - msg_erro_conexao - 1

.align 8
tempo_entre_leituras:
    .quad 2
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

    mov x19, x0
    mov x20, #1

loop_iteracoes:
    mov x0, x19
    mov x1, x20
    bl recebe_info

    ldr x0, =tempo_entre_leituras
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    add x20, x20, #1
    b loop_iteracoes

erro_geral:
    mov x0, #1
    ldr x1, =msg_erro_conexao
    mov x2, #msg_erro_conexao_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, #1
    mov x8, #SYS_EXIT
    svc #0
