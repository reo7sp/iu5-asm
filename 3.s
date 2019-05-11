# gcc -nostdlib -m32 3.s

.intel_syntax noprefix


.text

.global _start

putch:  # args: ch
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, esp
    add ecx, 4
    mov edx, 1
    int 0x80

    ret

getch:  # return: ch
    push 0

    mov eax, 3  # read(fd, buf, count)
    mov ebx, 0  # stdin
    mov ecx, esp
    mov edx, 1
    int 0x80

    pop eax
    ret

exit:
    mov eax, 1  # exit()
    mov ebx, 0
    int 0x80

    ret

_start:
    call getch

    inc eax

    mov ecx, 2

__loop1:
    push eax
    push ecx

    push eax
    call putch
    add esp, 4

    push 0x0A  # '\n'
    call putch
    add esp, 4

    pop ecx
    pop eax

    inc eax
    loop __loop1

    call getch

    call exit
