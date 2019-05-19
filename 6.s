# gcc -nostdlib -m32 3.s

.intel_syntax noprefix


.data

hello_msg:
.ascii "Entered args:"

.set hello_msg_len, . - hello_msg

first_param_msg:
.ascii "1st arg "

.set first_param_msg_len, . - first_param_msg

second_param_msg:
.ascii "2nd arg "

.set second_param_msg_len, . - second_param_msg

author_name:
.ascii "Morozenkov"

.set author_name_len, . - author_name

first_param_yes_msg:
.ascii "= Morozenkov"

.set first_param_yes_msg_len, . - first_param_yes_msg

first_param_no_msg:
.ascii "not correct"

.set first_param_no_msg_len, . - first_param_no_msg

second_param_yes_msg:
.ascii "exist"

.set second_param_yes_msg_len, . - second_param_yes_msg

second_param_no_msg:
.ascii "not passed"

.set second_param_no_msg_len, . - second_param_no_msg



.text

.global _start

putstr:  # args: len, str_ptr
    mov eax, 4  # write(fd, buf, count)
    mov ebx, 1  # stdout
    mov ecx, [esp + 8]  # str_ptr
    mov edx, [esp + 4]  # len
    int 0x80

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

strlen:  # args: ptr  # return: len
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]  # ptr
    mov ecx, 0

__strlen_loop1:
    movb al, [edx + ecx]
    cmp al, 0
    je __strlen_loop1_end

    inc ecx
    jmp __strlen_loop1

__strlen_loop1_end:
    mov eax, ecx

    mov esp, ebp
    pop ebp
    ret

strcmp:  # args: str1_ptr, str1_len, str2_ptr, str2_len  # return: 0 if eq
    push ebp
    mov ebp, esp

    mov eax, [ebp + 12]  # str1_len
    mov ebx, [ebp + 20]  # str2_len
    cmp eax, ebx
    jne __strcmp_no

    mov ecx, 0
    mov edx, [ebp + 12]  # str1_len

__strcmp_loop1:
    cmp ecx, edx
    je __strcmp_yes

    mov eax, [ebp + 8]   # str1_ptr
    add eax, ecx
    movb al, [eax]
    mov ebx, [ebp + 16]  # str2_ptr
    add ebx, ecx
    movb bl, [ebx]
    cmp al, bl
    jne __strcmp_no

    inc ecx
    jmp __strcmp_loop1

__strcmp_yes:
    mov eax, 0
    jmp __strcmp_end

__strcmp_no:
    mov eax, 1

__strcmp_end:
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
    push offset hello_msg  # putstr: str_ptr
    push hello_msg_len     # putstr: len
    call putstr
    add esp, 8

    call print_newline

    ret

handle_first_arg:  # args: argc, first_arg_ptr
    push ebp
    mov ebp, esp

    push offset first_param_msg  # putstr: str_ptr
    push first_param_msg_len     # putstr: len
    call putstr
    add esp, 8

    mov eax, [ebp + 8]  # argc
    cmp eax, 2
    jl __handle_first_arg_no

    push [ebp + 12]  # first_arg_ptr  # strlen: ptr
    call strlen

    push author_name_len              # strcmp: str2_len
    push offset author_name           # strcmp: str2_ptr
    push eax                          # strcmp: str1_len
    push [ebp + 12]  # first_arg_ptr  # strcmp: str1_ptr
    call strcmp

    cmp eax, 0
    jne __handle_first_arg_no

__handle_first_arg_yes:
    push offset first_param_yes_msg  # putstr: str_ptr
    push first_param_yes_msg_len     # putstr: len
    call putstr

    jmp __handle_first_arg_end

__handle_first_arg_no:
    push offset first_param_no_msg  # putstr: str_ptr
    push first_param_no_msg_len     # putstr: len
    call putstr

__handle_first_arg_end:
    call print_newline

    mov esp, ebp
    pop ebp
    ret

handle_second_arg:  # args: argc, second_arg_ptr
    push ebp
    mov ebp, esp

    push offset second_param_msg  # putstr: str_ptr
    push second_param_msg_len     # putstr: len
    call putstr
    add esp, 8

    mov eax, [ebp + 8]  # argc
    cmp eax, 3
    jl __handle_second_arg_no

__handle_second_arg_yes:
    push offset second_param_yes_msg  # putstr: str_ptr
    push second_param_yes_msg_len     # putstr: len
    call putstr

    jmp __handle_second_arg_end

__handle_second_arg_no:
    push offset second_param_no_msg  # putstr: str_ptr
    push second_param_no_msg_len     # putstr: len
    call putstr

__handle_second_arg_end:
    call print_newline

    mov esp, ebp
    pop ebp
    ret

_start:
    mov ebp, esp

    call print_hello

    push [ebp + 8]   # first_arg_ptr
    push [ebp]       # argc
    call handle_first_arg
    add esp, 8

    push [ebp + 12]  # second_arg_ptr
    push [ebp]       # argc
    call handle_second_arg
    add esp, 8

    call exit
