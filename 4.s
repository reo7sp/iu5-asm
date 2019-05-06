# gcc -nostdlib -m32 4.s

.intel_syntax noprefix


.data

delim:
    .ascii " - "

.set delim_len, . - delim


.text

.global _start

print_char_utf8_2byte:  # args: ch
    mov ebp, esp

    mov eax, [ebp + 4]

    # prepare 1st byte
    mov ebx, eax
    and ebx, 0x7c0
    shl ebx, 2
    or ebx, 0xc000

    # prepare 2nd byte
    mov ecx, eax
    mov ecx, eax
    and ecx, 0x3f
    or ecx, 0x80

    # merge
    mov eax, 0
    or eax, ebx
    or eax, ecx

    # change endian-ness
    bswap eax
    shr eax, 16
    push eax

    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, esp
    mov edx, 2
    int 0x80

    mov esp, ebp
    ret

print_char_hex:  # args: ch
    mov ebp, esp

    # push 'h' to stack
    dec esp
    movb [esp], 0x68  # 'h'

    # start spliting arg to digits
    mov eax, [ebp + 4]

__print_char_hex_loop1:
    mov ebx, eax
    and ebx, 0xF
    shr eax, 4

    cmp ebx, 0x9
    ja __print_char_hex_if__is_char

__print_char_hex_if__is_digit:
    add ebx, 0x30
    jmp __print_char_hex_if_end

__print_char_hex_if__is_char:
    add ebx, 0x41
    sub ebx, 0xA

__print_char_hex_if_end:
    dec esp
    movb [esp], bl

    cmp eax, 0
    jne __print_char_hex_loop1

    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, esp
    mov edx, ebp
    sub edx, esp
    int 0x80

    mov esp, ebp
    ret

print_delim:
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, offset delim
    mov edx, delim_len
    int 0x80

    ret

print_newline:
    push 0x0a  # '\n'

    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, esp
    mov edx, 1
    int 0x80

    add esp, 4
    ret

print_char_with_hex_with_newline:  # args: ch
    push [esp + 4]
    call print_char_utf8_2byte
    add esp, 4

    call print_delim

    push [esp + 4]
    call print_char_hex
    add esp, 4

    call print_newline

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
    mov eax, 0x410  # 'А'
    mov ecx, 20

__loop1:
    push ecx

    push eax
    call print_char_with_hex_with_newline
    pop eax

    pop ecx

    inc eax
    loop __loop1

    call getch

    call exit
