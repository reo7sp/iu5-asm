# gcc -nostdlib -m32 7.s

.intel_syntax noprefix


.data

hello_msg:
.ascii "Enter hex number> "

.set hello_msg_len, . - hello_msg

delim:
.ascii " = "

.set delim_len, . - delim

delim2:
.ascii " "

.set delim2_len, . - delim2


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

print_hex:  # args: num
    push ebp
    mov ebp, esp

    # push 'h' to stack
    sub esp, 1
    movb [esp], 0x68  # '\n'  # putstr: str

    # start spliting arg to digits
    mov eax, [ebp + 8]  # num

__print_hex_loop1:
    mov ebx, eax
    and ebx, 0xF
    shr eax, 4

    cmp ebx, 0x9
    ja __print_hex_if__is_char

__print_hex_if__is_digit:
    add ebx, 0x30
    jmp __print_hex_if_end

__print_hex_if__is_char:
    add ebx, 0x41
    sub ebx, 0xA

__print_hex_if_end:
    sub esp, 1
    movb [esp], bl  # putstr: str

    cmp eax, 0
    jne __print_hex_loop1

    # calc len
    mov ecx, ebp
    sub ecx, esp

    # print
    push ecx  # putstr: len
    call putstr

    mov esp, ebp
    pop ebp
    ret

print_dec:  # args: num
    push ebp
    mov ebp, esp

    # start spliting arg to digits
    mov ecx, [ebp + 8]  # num

__print_dec_loop1:
    mov edx, 0
    mov eax, ecx
    mov ebx, 10
    div ebx
    mov ebx, edx

    mov edx, 0
    mov eax, ecx
    mov ecx, 10
    div ecx
    mov ecx, eax

    add ebx, 0x30

    sub esp, 1
    movb [esp], bl  # putstr: str

    cmp ecx, 0
    jne __print_dec_loop1

    # calc len
    mov ecx, ebp
    sub ecx, esp

    # print
    push ecx  # putstr: len
    call putstr

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

print_hello:
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, offset hello_msg
    mov edx, hello_msg_len
    int 0x80

    ret

print_delim:
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, offset delim
    mov edx, delim_len
    int 0x80

    ret

print_delim2:
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, offset delim2
    mov edx, delim2_len
    int 0x80

    ret

parse_ch:  # args: ch  # return: num, is_err
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]  # ch

__parse_ch_challenge_dec_start:
    cmp eax, 0x30  # '1'
    jl __parse_ch_challenge_hex_start

__parse_ch_challenge_dec_continue:
    cmp eax, 0x39  # '9'
    jg __parse_ch_challenge_hex_start

__parse_ch_challenge_dec_pass:
    sub eax, 0x30  # '1'
    mov ebx, 0
    jmp __parse_ch_end

__parse_ch_challenge_hex_start:
    cmp eax, 0x41  # 'A'
    jl __parse_ch_challenge_hex2_start

__parse_ch_challenge_hex_continue:
    cmp eax, 0x46  # 'F'
    jg __parse_ch_challenge_hex2_start

__parse_ch_challenge_hex_pass:
    sub eax, 0x41  # 'A'
    add eax, 0xa
    mov ebx, 0
    jmp __parse_ch_end

__parse_ch_challenge_hex2_start:
    cmp eax, 0x61  # 'a'
    jl __parse_ch_fail

__parse_ch_challenge_hex2_continue:
    cmp eax, 0x66  # 'f'
    jg __parse_ch_fail

__parse_ch_challenge_hex2_pass:
    sub eax, 0x61  # 'a'
    add eax, 0xa
    mov ebx, 0
    jmp __parse_ch_end

__parse_ch_fail:
    mov eax, 0
    mov ebx, 1

__parse_ch_end:
    mov esp, ebp
    pop ebp
    ret

process_line:  # return: 1 if must stop
    push ebp
    mov ebp, esp

    call print_hello

    mov eax, 0
    mov ecx, 0
    mov edx, 0

__process_line_loop1:
    push ecx
    push edx

    call getch

    pop edx
    pop ecx

    cmp eax, 0x24  # '$'
    je __process_line_loop1_end
    cmp eax, 0x0a  # '\n'
    je __process_line_loop1_end
    cmp eax, 0x2a  # '*'
    je __process_line_stop
    cmp ecx, 20
    je __process_line_loop1_end

    push eax
    push ecx
    push edx

    push eax  # parse_ch: ch
    call parse_ch
    add esp, 4

    pop edx

    shl edx, 4
    add edx, eax

    pop ecx
    pop eax

    cmp ebx, 1
    je __process_line_loop1_ok_end

__process_line_loop1_ok:
    inc ecx

    push ecx
    push edx

    push eax  # putch: ch
    call putch
    add esp, 4

    pop edx
    pop ecx

__process_line_loop1_ok_end:
    jmp __process_line_loop1

__process_line_loop1_end:
    cmp ecx, 0
    je __process_line_stop_end

    push ecx
    push edx

    call print_delim

    pop edx
    push edx

    push edx  # print_hex: num
    call print_hex
    add esp, 4

    pop edx
    push edx

    call print_delim2

    pop edx
    push edx

    push edx  # print_dec: num
    call print_dec
    add esp, 4

    pop edx
    pop ecx

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
