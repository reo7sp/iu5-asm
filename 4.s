# gcc -nostdlib -m32 4.s

.intel_syntax noprefix


.data

delim:
.ascii " - "

.set delim_len, . - delim


.text

.global _start

putstr:  # args: len, str...
    push ebp
    mov ebp, esp

    # len
    add esp, 8
    mov edx, [esp]

    # str
    add esp, 4
    mov ecx, esp

    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    int 0x80

    mov esp, ebp
    pop ebp
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

print_char_utf8_2byte:  # args: ch
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]  # ch

    # prepare 1st byte
    mov ebx, eax
    and ebx, 0x7C0
    shl ebx, 2
    or ebx, 0xC000

    # prepare 2nd byte
    mov ecx, eax
    mov ecx, eax
    and ecx, 0x3F
    or ecx, 0x80

    # merge
    mov eax, 0
    or eax, ebx
    or eax, ecx

    # change endian-ness
    bswap eax
    shr eax, 16

    # print
    sub esp, 2
    movw [esp], ax  # putstr: str
    push 2  # putstr: len
    call putstr

    mov esp, ebp
    pop ebp
    ret

print_char_hex:  # args: ch
    push ebp
    mov ebp, esp

    # push 'h' to stack
    sub esp, 1
    movb [esp], 0x68  # '\n'  # putstr: str

    # start spliting arg to digits
    mov eax, [ebp + 8]  # ch

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
    sub esp, 1
    movb [esp], bl  # putstr: str

    cmp eax, 0
    jne __print_char_hex_loop1

    # calc len
    mov ecx, ebp
    sub ecx, esp

    # print
    push ecx  # putstr: len
    call putstr

    mov esp, ebp
    pop ebp
    ret

print_delim:
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, offset delim
    mov edx, delim_len
    int 0x80

    ret

print_newline:
    push ebp
    mov ebp, esp

    sub esp, 1
    movb [esp], 0x0A  # '\n'  # putstr: str
    push 1  # putstr: len
    call putstr

    mov esp, ebp
    pop ebp
    ret

print_char_with_hex_with_newline:  # args: ch
    push ebp
    mov ebp, esp

    push [esp + 4]  # ch  # print_char_utf8_2byte, print_char_hex: ch

    call print_char_utf8_2byte
    call print_delim
    call print_char_hex
    call print_newline

    mov esp, ebp
    pop ebp
    ret

_start:
    mov eax, 0x410  # 'А'
    mov ecx, 20

__loop1:
    push ecx

    push eax  # print_char_with_hex_with_newline: ch
    call print_char_with_hex_with_newline
    pop eax

    pop ecx

    inc eax
    loop __loop1

    call getch

    call exit
