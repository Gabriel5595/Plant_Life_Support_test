.global gpio_map
.global gpio_unmap
.global gpio_set_output
.global gpio_set_input
.global gpio_write
.global gpio_read

.text

.equ SYS_openat,   56
.equ SYS_close,    57
.equ SYS_mmap,     222
.equ SYS_munmap,   215

.equ AT_FDCWD,     -100
.equ O_RDWR,       2
.equ PROT_READ,    1
.equ PROT_WRITE,   2
.equ MAP_SHARED,   1

.equ GPIO_MAP_LEN, 4096

.equ GPFSEL0,      0x00
.equ GPSET0,       0x1C
.equ GPCLR0,       0x28
.equ GPLEV0,       0x34

.data
gpiomem_path:
    .asciz "/dev/gpiomem"

last_fd:
    .quad -1

.text

gpio_map:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, #AT_FDCWD
    ldr x1, =gpiomem_path
    mov x2, #O_RDWR
    mov x3, #0
    mov x8, #SYS_openat
    svc #0

    cmp x0, #0
    b.lt map_fail

    ldr x9, =last_fd
    str x0, [x9]
    mov x9, x0

    mov x0, #0
    mov x1, #GPIO_MAP_LEN
    mov x2, #(PROT_READ | PROT_WRITE)
    mov x3, #MAP_SHARED
    mov x4, x9
    mov x5, #0
    mov x8, #SYS_mmap
    svc #0

    cmp x0, #0
    b.lt mmap_fail

    mov x1, #0
    ldp x29, x30, [sp], 16
    ret

mmap_fail:
    ldr x9, =last_fd
    ldr x0, [x9]
    cmp x0, #0
    b.lt map_fail
    mov x8, #SYS_close
    svc #0

map_fail:
    mov x0, #0
    mov x1, #1
    ldp x29, x30, [sp], 16
    ret

gpio_unmap:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x19, x0

    mov x0, x19
    mov x1, #GPIO_MAP_LEN
    mov x8, #SYS_munmap
    svc #0

    ldr x9, =last_fd
    ldr x0, [x9]
    cmp x0, #0
    b.lt unmap_done

    mov x8, #SYS_close
    svc #0

unmap_done:
    ldp x29, x30, [sp], 16
    ret

gpio_set_output:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w2, #10
    udiv w3, w1, w2
    mul w4, w3, w2
    sub w5, w1, w4
    mov w6, #3
    mul w6, w5, w6

    lsl w7, w3, #2
    add x7, x0, x7

    ldr w8, [x7]

    mov w9, #7
    lsl w9, w9, w6
    bic w8, w8, w9

    mov w10, #1
    lsl w10, w10, w6
    orr w8, w8, w10

    str w8, [x7]

    ldp x29, x30, [sp], 16
    ret

gpio_set_input:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w2, #10
    udiv w3, w1, w2
    mul w4, w3, w2
    sub w5, w1, w4
    mov w6, #3
    mul w6, w5, w6

    lsl w7, w3, #2
    add x7, x0, x7

    ldr w8, [x7]

    mov w9, #7
    lsl w9, w9, w6
    bic w8, w8, w9

    str w8, [x7]

    ldp x29, x30, [sp], 16
    ret

gpio_write:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w3, #1
    lsl w3, w3, w1

    cmp w2, #0
    b.eq write_low

    add x4, x0, #GPSET0
    str w3, [x4]
    b write_done

write_low:
    add x4, x0, #GPCLR0
    str w3, [x4]

write_done:
    ldp x29, x30, [sp], 16
    ret

gpio_read:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    add x2, x0, #GPLEV0
    ldr w3, [x2]

    mov w4, #1
    lsl w4, w4, w1

    and w5, w3, w4
    cmp w5, #0
    cset w0, ne

    ldp x29, x30, [sp], 16
    ret
