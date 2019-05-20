# gcc -nostdlib -m32 5.s

.intel_syntax noprefix


.bss

.lcomm tc_initial, 60  # sizeof(termios)


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

memcpy:  # args: dst_ptr, src_ptr, n
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]   # dst_ptr
    mov ebx, [ebp + 12]  # src_ptr
    mov ecx, 0
    mov edx, [ebp + 16]  # n

    cmp edx, 0
    je __memcpy_loop1_end

__memcpy_loop1:
    push edx

    movb dl, [ebx + ecx]
    movb [eax + ecx], dl

    pop edx

    inc ecx

    cmp ecx, edx
    je __memcpy_loop1_end

    jmp __memcpy_loop1

__memcpy_loop1_end:
    mov esp, ebp
    pop ebp
    ret
 
tc_getattr:  # args: ptr
    mov eax, 0x36   # ioctl(fd, cmd, arg)
    mov ebx, 0      # stdin
    mov ecx, 21505  # TCGETS
    mov edx, [esp + 4]
    int 0x80

    ret

tc_setattr:  # args: ptr
    mov eax, 0x36   # ioctl(fd, cmd, arg)
    mov ebx, 0      # stdin
    mov ecx, 21506  # TCSETS
    mov edx, [esp + 4]
    int 0x80

    ret

term_noncanon:
    push ebp
    mov ebp, esp

    # read tc
    sub esp, 60  # sizeof(termios)
    mov ebx, esp

    push ebx

    push ebx
    call tc_getattr

    pop ebx

    # backup tc
    push ebx

    push 60  # sizeof(termios)  # memcpy: len
    push ebx                    # memcpy: src_ptr
    push offset tc_initial      # memcpy: dst_ptr
    call memcpy
    add esp, 12

    pop ebx

    # disable ICANON and ECHO
    mov eax, [ebx + 12]  # termios.c_lflag

    mov edx, 0x2  # ICANON
    not edx
    and eax, edx

    mov edx, 0x8  # ECHO
    not edx
    and eax, edx

    mov [ebx + 12], eax
    
    push ebx
    call tc_setattr

    mov esp, ebp
    pop ebp
    ret

term_canon:
    push ebp
    mov ebp, esp

    push offset tc_initial
    call tc_setattr

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

transform_n:  # args: i, len  # return: i
    push ebp
    mov ebp, esp

#   for i in range(len(a)):
#       if i < (len(a) >> 1) + 1:
#           i <<= 1
#       else:
#           i = len(a) - i
#           i <<= 1
#           i -= 1
#       print(i)

    mov eax, [ebp + 8]  # i

    mov ebx, [ebp + 12]  # len
    inc ebx
    shr ebx, 1

    cmp eax, ebx
    jl __transform_n_first_half
    jmp __transform_n_second_half

__transform_n_first_half:
    shl eax, 1

    jmp __transform_n_end

__transform_n_second_half:
    mov ebx, [ebp + 12]  # len
    sub ebx, eax
    mov eax, ebx
    shl eax, 1
    dec eax

__transform_n_end:
    mov esp, ebp
    pop ebp
    ret

print_char_hexes:  # args: cnt, chs...
    push ebp
    mov ebp, esp

    # cnt
    mov edx, [ebp + 8]

    cmp edx, 0
    je __print_char_hexes_loop1_end

    # chs
    mov ecx, 0

__print_char_hexes_loop1:
    push ecx
    push edx

    call print_space

    pop edx
    pop ecx

    push ecx
    push edx

    push edx  # transform_n: len
    push ecx  # transform_n: i
    call transform_n
    add esp, 8

    push [ebp + eax * 4 + 12]  # print_char_hex: ch
    call print_char_hex
    add esp, 4

    pop edx
    pop ecx

    inc ecx
    cmp ecx, edx
    je __print_char_hexes_loop1_end

    jmp __print_char_hexes_loop1

__print_char_hexes_loop1_end:
    mov esp, ebp
    pop ebp
    ret

print_space:
    push ebp
    mov ebp, esp

    push 0x20  # ' '  # putch: ch
    call putch

    mov esp, ebp
    pop ebp
    ret

print_newline:
    push ebp
    mov ebp, esp

    push 0x0a  # '\n'  # putch: ch
    call putch

    mov esp, ebp
    pop ebp
    ret

process_line:  # return: 1 if must stop
    push ebp
    mov ebp, esp

    sub esp, 80  # 20 chars * 4  # putstr: str

    mov ecx, 0

__process_line_loop1:
    push ecx

    call getch

    pop ecx

    cmp eax, 0x24  # '$'
    je __process_line_loop1_end
    cmp eax, 0x2a  # '*'
    je __process_line_stop
    cmp ecx, 20
    je __process_line_loop1_end

    mov [esp + ecx * 4], eax  # print_char_hexes: chs
    inc ecx

    push eax
    push ecx

    push eax  # putch: ch
    call putch
    add esp, 4

    pop ecx
    pop eax

    jmp __process_line_loop1

__process_line_loop1_end:
    push ecx  # print_char_hexes: cnt
    call print_char_hexes

    mov eax, 0
    jmp __process_line_stop_end

__process_line_stop:
    mov eax, 1

__process_line_stop_end:
    push eax

    call print_newline

    pop eax

    mov esp, ebp
    pop ebp
    ret

process_input:
    push ebp
    mov ebp, esp

    mov ecx, 0

__process_input_loop1:
    push ecx

    call process_line

    pop ecx

    cmp eax, 1
    je __process_input_loop1_end
    cmp ecx, 10
    je __process_input_loop1_end

    jmp __process_input_loop1

__process_input_loop1_end:
    mov esp, ebp
    pop ebp
    ret

_start:
    call term_noncanon
    call process_input
    call term_canon
    call exit
