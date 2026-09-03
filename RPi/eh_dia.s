// ============================================================
// eh_dia.s
//
// Decide se e' "dia" (07:00-20:59 hora local) ou "noite", a
// partir do timestamp Unix (UTC) ja disponivel via
// obtem_timestamp (recebe_info.s).
//
// LIMITACAO ACEITA CONSCIENTEMENTE: fuso fixo UTC+2 (CEST,
// horario de verao da Belgica). NAO implementa troca automatica
// pra CET (UTC+1) quando o horario de verao europeu terminar
// (ultimo domingo de outubro) - isso exigiria calculo de
// calendario que foge do escopo do projeto. Se o sistema ainda
// estiver rodando depois dessa troca, atualizar
// OFFSET_UTC_SEGUNDOS manualmente pra 3600.
//
// Janela de dia (07:00-20:59) escolhida com folga generosa sobre
// as 6-8h de sol direto que o manjericao precisa (fonte:
// bababerry.co/blogs/self-watering/basil-light-requirements).
// ============================================================

.global eh_dia
.extern obtem_timestamp

.equ OFFSET_UTC_SEGUNDOS, 7200   // UTC+2 (CEST) - ver limitacao acima
.equ HORA_INICIO_DIA, 7
.equ HORA_FIM_DIA,    21          // dia = [7, 21) horas locais

.section .text

// ============================================================
// eh_dia
// Saida: x0 = 1 se for dia (07:00-20:59 local), 0 se for noite
// ============================================================
eh_dia:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl obtem_timestamp          // x0 = tv_sec (UTC, segundos desde 1970)

    mov x1, #OFFSET_UTC_SEGUNDOS
    add x0, x0, x1
    ldr x1, =86400
    udiv x2, x0, x1
    msub x0, x2, x1, x0         // segundos_do_dia_local = (tv_sec+offset) mod 86400

    mov x1, #3600
    udiv x0, x0, x1             // hora_local = segundos_do_dia_local / 3600

    mov x1, #HORA_INICIO_DIA
    cmp x0, x1
    blt fim_eh_dia_noite

    mov x1, #HORA_FIM_DIA
    cmp x0, x1
    bge fim_eh_dia_noite

    mov x0, #1
    b fim_eh_dia

fim_eh_dia_noite:
    mov x0, #0

fim_eh_dia:
    ldp x29, x30, [sp], 16
    ret
