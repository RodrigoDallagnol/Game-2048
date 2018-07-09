.model small

.stack 100H

.data 
    matriz DB 16 dup(0)
    
    join_flag db 16 dup(0)
    mov_flag db 0
    gameover_flag db 0
    bot_mode_flag db 0
    potencia_flag db 0
    
    bot_score dw 7 dup(0)
    bot_jogadas dw 7 dup(0)
    score dw 0
    jogadas dw 0
    melhor dw 0
    
    best_players db 50 dup(32)
    best_scores dw 5 dup (0)
    best_jogadas dw 5 dup (0)
    
    game_name_msg db "2048"
    game_name_len equ $-game_name_msg
    
    authors_msg db "Autores: Rodrigo Dallagnol e Thiago Melo"
    authors_len equ $-authors_msg 
    
    play_msg db "[J] Jogar 2048"
    play_len equ $-play_msg
    
    hiscores_msg db "[R] Recordes"
    hiscores_len equ $-hiscores_msg
    
    bot_msg db "[A] Automatico 2048"
    bot_len equ $-bot_msg
    
    exit_msg db "[S] Sair"
    exit_len equ $-exit_msg
    
    esc_msg db "[Esc] Sair"
    esc_len equ $-esc_msg
    
    score_msg db "Score"
    score_len equ $-score_msg
    
    players_msg db "Nome"
    players_len equ $-players_msg
    
    game_over_msg db "Game Over"
    game_over_len equ $-game_over_msg
    
    jogadas_header_msg db "Jogadas"
    jogadas_header_len equ $-jogadas_header_msg
    
    melhor_header_msg db "Melhor"
    melhor_header_len equ $-melhor_header_msg
  
    name_gameover_msg db "Digite o seu nome: "
    name_gameover_len equ $-name_gameover_msg
    
    hiscore_msg db "Top 5 Melhores Jogadas"
    hiscore_len equ $-hiscore_msg
    
    bot_result_msg db "Resultados do modo Automatico"
    bot_result_len equ $-bot_result_msg
    
    bot_repeat_msg db "Digite o numero de simulacoes: "
    bot_repeat_len equ $-bot_repeat_msg
    
    potencia_msg db "Potencia"
    potencia_len equ $-potencia_msg
    numbers_bot db "32  64  128 256 512 10242048"
    squares db 23040 dup(0)
    numbers_config db "****      2   4   8  16  32  64  128 256 51210242048"
    position_config dw 7744, 7792, 7840, 7888, 20544, 20592, 20640, 20688, 33344, 33392, 33440, 33488, 46144, 46192, 46240, 46288

.code
   
push_all macro
    push ax
    push bx
    push cx
    push dx
endm 

pop_all macro
    pop dx
    pop cx
    pop bx
    pop ax
endm

stop proc 
    push ax  
    xor ax, ax  
    int 16h
    pop ax
    ret
endp

delay proc
    push_all
    cmp bot_mode_flag, byte ptr 1
    je no_delay
    mov ax, 8600h
    mov cx, 01h
    xor dx, dx
    int 15h
    no_delay:
    pop_all
ret
endp

backspace_clear proc
    push ax
    push dx
    mov ah, 02h 
    mov dl, 08h
    int 21h
    mov dl, 20h
    int 21h
    mov dl, 08h
    int 21h 
    pop dx
    pop ax
    ret
endp

clear_memory proc
    push dx
    push bx
    mov bx, 10       
    div bx      
    pop bx        
    pop bx
    ret
endp
readchar proc
    push ax
    mov ax, 0200h
    int 21h
    pop ax
    ret
endp
read_number proc  ;Retorna em AX o valor lido do teclado
    push bx
    push cx
    push dx    

    xor ax, ax
    xor bx, bx
    mov cx, 10
read_next:
    push ax
read_n:
    mov ax, 0700h
    int 21h
    cmp al, 13
    jz end_read_n
    cmp AL, 8
    jz backspace
    cmp AL, '0'
    jb read_n
    cmp AL, '9'
    ja read_n
    mov DL, AL 
    call readchar
    sub al, '0'
    mov bl, al
    pop ax
    mul cx
    add ax, bx
    jmp read_next
backspace:
    pop ax
    call backspace_clear
    call clear_memory
    jmp read_next
end_read_n:           
    pop ax
   
    pop dx
    pop cx
    pop bx
    ret
endp

write_number proc 
    push_all
    xor cx, cx
    mov bx, 10                                    
    push_char:
    xor dx, dx                                         
    div bx      ; AX <- DXAX/BX e DX <- Resto 
    add dl, '0'
    push dx      
    inc cx
    and ax,ax
    jnz push_char
    mov ah, 02h   
    pop_char:    
    pop dx
    int 21h
    loop pop_char  ; dec CX e jnz DESEMPILHA_CHAR
    pop_all
    ret
endp   

clear_screen proc
    push_all
    xor bx, bx
    xor cx, cx
    mov ax, 0600h
    mov dx, 2439h
    int 10h
    pop_all
    ret
endp

create_square proc
    push_all
    xor cx, cx ; quadrado da cor
    mov ax, 0600h
    mov dx,0405h 
    int 10h
    
    shr bx, 8 ;quadrado preto no centro
    mov cx,0101h
    mov dx,0304h 
    int 10h  

    mov ax,1301h ;escreve numero
    mov cx, 4
    mov dx,0201h
    add bp, 4  
    int 10h

    xor si, si
    mov ax, 40 ;escreve do video na memoria
    repeat:
    mov cx, 24
    cld
    rep movsw
    add si, 272
    dec ax
    jnz repeat
    pop_all
    ret
endp

set_memory proc
    push ds
    push es
    push_all
    
    mov bp, offset numbers_config
    mov di, offset squares
    
    mov ax, @data
    mov es, ax    
    mov ax, 0A000h
    mov ds, ax
    
    xor bx, bx
    call create_square
    
    mov cx, 11
    mov bh, 68
    creating_squares:    
    call create_square

    inc bh
    loop creating_squares

    pop_all
    pop es
    pop ds
    ret
endp

print_game_header proc
    push_all
    mov ax, 1301h
    mov bx, 79
    mov bp, offset score_msg
    mov cx, offset score_len
    mov dx, 0600h
    int 10h
    
    mov bp, offset jogadas_header_msg
    mov cx, offset jogadas_header_len
    mov dx, 00B00h
    int 10h
    
    mov bp, offset melhor_header_msg
    mov cx, offset melhor_header_len
    mov dx, 01000h
    int 10h
    
    mov bp, offset esc_msg
    mov cx, offset esc_len
    mov dx, 1800h
    int 10h
    
    mov ax, best_scores
    mov melhor, ax
    call update_header
    
    mov bx, 00F00h
    mov cx, 0207h ;alta linha baixa coluna
    mov ax, 0600h
    mov dx, 1720h 
    int 10h
    pop_all
    ret
endp

print_mat proc
    push_all
    push ds
    push es
    push di
    push si
    push bp
    
    mov ax, @DATA
    mov ds, ax
    
    mov ax, 0A000h
    mov es, ax
    
    xor bx, bx
    xor bp, bp
    printing_mat:
    mov si, offset matriz
    
    xor cx, cx
    mov ax, 1920
    mov cl, [si+bx]
    mul cx
    
    mov si, offset squares
    add si, ax
    
    mov di, offset position_config
    mov dx, ds:[bp+di]
    mov di, dx
    inc bx
    inc bp
    inc bp
    
    mov ax, 40 ;escreve da memoria no video
    jump:
    mov cx, 48
    cld 
    rep movsb
    add di, 272
    dec ax
    jnz jump
    cmp bx, 16
    jne printing_mat
    
    call delay
    pop bp
    pop si
    pop di
    pop es
    pop ds
    pop_all
    ret
endp

show_menu proc
    push_all  
    
    call clear_screen
    mov ax, 1124h ;seta cursor em 2 linhas
    int 10h
    
    mov ax, 1301h
    mov bx, 79
    mov bp, offset game_name_msg
    mov cx, offset game_name_len
    mov dx, 0112h
    int 10h
     
    mov ax,1123h ;retorna cursor para 1 linha
    int 10h
    
    mov ax, 1301h
    mov bp, offset play_msg
    mov cx, offset play_len
    mov dx, 0707h
    int 10h
    
    mov bp, offset hiscores_msg
    mov cx, offset hiscores_len
    mov dh,10 
    int 10h
    
    mov bp, offset bot_msg
    mov cx, offset bot_len
    mov dh,13 
    int 10h
    
    mov bp, offset exit_msg
    mov cx, offset exit_len
    mov dh,16
    int 10h
    
    mov bp, offset authors_msg
    mov cx, offset authors_len
    mov dx, 1800h
    int 10h
    pop_all
    ret
endp

getkey_menu proc
    keep_reading:
    mov ah, 00h
    int 16h
    
    cmp ah,024h
    je play
    cmp ah,013h
    je hiscore
    cmp ah,01Eh
    je bot
    cmp ah,01Fh
    je exit
    
    jmp keep_reading

    play:
    call start_game
    ;call stop
    call reset_game
    call show_menu
    jmp keep_reading
    hiscore:
    call show_hiscore
    call stop
    call show_menu
    jmp keep_reading
    bot:
    call start_bot
    call stop
    call reset_game
    call show_menu
    jmp keep_reading
    exit:
    call clear_screen
    mov al, 00
    mov ah, 04Ch
    int 21h
    ret
endp
show_hiscore proc
    call clear_screen
    mov ax, 1301h
    mov bx, 79
    mov bp, offset hiscore_msg
    mov cx, offset hiscore_len 
    mov dx, 0109h
    int 10h
    mov bp, offset players_msg
    mov cx, offset players_len 
    mov dx, 0407h
    int 10h
    mov bp, offset score_msg
    mov cx, offset score_len 
    mov dx, 0413h
    int 10h   
    mov bp, offset jogadas_header_msg
    mov cx, offset jogadas_header_len 
    mov dx, 041ah
    int 10h 
    mov bp, offset exit_msg
    mov cx, offset exit_len
    mov dx, 1710h
    int 10h
    mov si, 5
    mov bp, offset best_players
    mov cx, 10
    mov dx, 0707h
    int 10h
    laco_best_players:
    int 10h
    add dh, byte ptr 3
    add bp, 10
    dec si
    cmp si, 0
    jne laco_best_players
    mov si, 5
    mov di, offset best_scores
    xor bx,bx
    mov dx, 0713h
    laco_best_scores:
    mov ax, 0200h
    int 10h
    mov ax,[di]
    call write_number
    add di, 2
    add dh, byte ptr 3
    dec si
    cmp si, 0
    jne laco_best_scores
    mov si, 5
    mov di, offset best_jogadas
    xor bx,bx
    mov dx, 071bh
    laco_best_jogadas:
    mov ax, 0200h
    int 10h
    mov ax,[di]
    call write_number
    add di, 2
    add dh, byte ptr 3
    dec si
    cmp si, 0
    jne laco_best_jogadas
    
    ret
endp
reset_game proc
    mov bx, offset matriz
    mov cx,16
    
    laco_reset:
    mov [bx],byte ptr 0
    inc bx
    loop laco_reset
    
    mov [score], byte ptr 0
    mov [jogadas], 0
    mov [gameover_flag], byte ptr 0
    mov [mov_flag], byte ptr 0
ret
endp

start_bot proc
    call clear_screen
    mov bot_mode_flag, byte ptr 1
    mov ax, 1301h
    mov bx, 79
    mov bp, offset bot_repeat_msg
    mov cx, offset bot_repeat_len
    mov dx, 0b02h
    int 10h
    call read_number
    call bot_mode
    call clear_screen
    
    mov ax, 1301h
    mov bx, 79
    mov bp, offset bot_result_msg
    mov cx, offset bot_result_len 
    mov dx, 0006h
    int 10h
    
    mov bp, offset potencia_msg
    mov cx, offset potencia_len 
    mov dx, 0207h
    int 10h
    
    mov bp, offset score_msg
    mov cx, offset score_len 
    mov dx, 0213h
    int 10h 
    
    mov bp, offset jogadas_header_msg
    mov cx, offset jogadas_header_len 
    mov dx, 021ah
    int 10h 
    
    mov bp, offset exit_msg
    mov cx, offset exit_len
    mov dx, 1810h
    int 10h
    
    mov si, 7
    mov bp, offset numbers_bot
    mov cx, 4
    mov dx, 0407h
    int 10h
    laco_potencia:
    int 10h
    add dh, byte ptr 3
    add bp, 4
    dec si
    cmp si, 0
    jne laco_potencia
    
    mov si, 7
    mov di, offset bot_score
    xor bx,bx
    mov dx, 0413h
    laco_bot_scores:
    mov ax, 0200h
    int 10h
    mov ax,[di]
    call write_number
    add di, 2
    add dh, byte ptr 3
    dec si
    cmp si, 0
    jne laco_bot_scores
    
    mov si, 7
    mov di, offset bot_jogadas
    xor bx,bx
    mov dx, 041bh
    laco_bot_jogadas:
    mov ax, 0200h
    int 10h
    mov ax,[di]
    call write_number
    add di, 2
    add dh, byte ptr 3
    dec si
    cmp si, 0
    jne laco_bot_jogadas
    
    mov bot_mode_flag, byte ptr 0
    call stop
    ret
endp


bot_mode proc
    push_all
    
    laco_principal:
    mov [potencia_flag] , 05h
    call reset_game
    call clear_screen
    call print_game_header
    call new_number
    call print_mat
    
    same_move:
    call arrow_right
    cmp [mov_flag], byte ptr 0
    je try_down 
    
    call start_game
    
    call arrow_down
    cmp [mov_flag], byte ptr 0
    je same_move 
    jmp update_game_bot
    
    try_down:
    call arrow_down
    cmp [mov_flag], byte ptr 0
    jne update_game_bot
    
    call arrow_left
    cmp [mov_flag], byte ptr 0
    jne update_game_bot
    
    call arrow_up
    cmp [mov_flag], byte ptr 0
    jne update_game_bot

    update_game_bot:
    call start_game
    cmp [gameover_flag], 1
    je jmp_game
    jmp same_move
    
    jmp_game:
    dec ax
    and ax, ax
    jnz laco_principal
    
    pop_all
    ret
endp

manage_bot proc
    push_all
    push di
    
    xor cx, cx
    mov cl, potencia_flag
    cmp [si], byte ptr 9
    jne baixo
    call stop
    baixo:
    cmp cl, byte ptr [si]
    jne end_manage_bot
    mov di, offset bot_jogadas
    mov bx, cx
    sub bx, 5
    mov ax, 2
    mul bx
    mov bx, ax
    mov ax, jogadas
    inc ax
    cmp [bx+di], word ptr 0
    je troca_valor
    cmp [bx+di], ax
    jbe end_manage_bot
    troca_valor:
    
    mov [bx+di], ax 
    mov ax, score
    mov [bx+offset bot_score], ax
    inc potencia_flag
    end_manage_bot:
    pop di
    pop_all
    ret
endp

start_game proc
    push_all
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    jne bot_jump
    
    call clear_screen
    call print_game_header
    call new_number
    call print_mat
    
    playing:
    call getkey_game
    bot_jump:
    cmp [mov_flag], byte ptr 0
    je no_move
    inc jogadas
    call new_number
    call print_mat
    call update_header
    call clear_flags
    call check_gameover
    
    no_move:
    cmp [gameover_flag], 1
    je end_game
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    jne end_game
    
    jmp playing
    
    end_game:
    pop_all
    ret
endp

update_header proc
    push_all
    mov ax, 0200h
    xor bx,bx
    mov dx, 0701h
    int 10h
    
    mov ax, score
    call write_number
    
    mov ax, 0200h
    mov dx, 00C01h
    int 10h
    mov ax, jogadas
    call write_number
    
    mov ax, 0200h
    mov dx, 1101h
    int 10h
    mov ax, melhor
    call write_number
    pop_all
    ret
endp

new_number proc
    push_all
    xor ax, ax      
    int 1Ah      
    mov cx, dx
    shr cx, 1
    jnc randon_mask
    rcr dx, 3
    jmp randon_end
    randon_mask:
    xor dx, 8016h
    rcr dx, 3
    randon_end:
    mov bx, dx
    and bx, 0Fh
    again:    
    cmp [bx], byte ptr 0
    jz free_pos
    cmp bx, 15
    jz fifteen 
    inc bx
    jmp again
    fifteen:
    xor bx, bx
    jmp again     
    free_pos:
    xor ah, ah      
    int 1Ah    
    mov cx, dx
    shr cx, 1
    jnc rand_mask
    rcr dx, 3
    jmp rand_finally
    rand_mask:
    xor dx, 8016h
    rcr dx, 3
    rand_finally:
    shr dx, 1
    jc escape
    mov [bx],byte ptr 1
    jmp end_newnumb    
    escape:
    mov [bx], byte ptr 2
    end_newnumb:
    pop_all   
    ret
endp

getkey_game proc
    push_all
    push si
    read_again:
    xor ax, ax
    int 16h 
    
    cmp ah,048h
    je up
    cmp ah,04Bh
    je left
    cmp ah,04Dh
    je right
    cmp ah,050h
    je down
    cmp ah,01h
    je return_menu
    jmp read_again
up: 
    call arrow_up
    jmp return_getkey
down:
    call arrow_down
    jmp return_getkey
left:
    call arrow_left
    jmp return_getkey  
right:
    call arrow_right
    jmp return_getkey
return_menu: 
    mov gameover_flag, byte ptr 1
    jmp return_getkey 
    return_getkey:
    pop si
    pop_all
    ret
endp    

add_score proc
    push_all
    mov ax, 1
    mov cl, [si]
    shl ax, cl
    add score, ax
    mov ax, score 
    cmp ax, best_scores
    jle score_notbest
    mov melhor, ax
    score_notbest:
    pop_all
    ret
endp

arrow_up proc 
    push_all
    mov bx, 3 
    next_up:
    inc bx
    cmp bx, 15 
    ja return_up
    mov dh, bl        
    cmp [bx], byte ptr 0 ;verifica se celula esta vazia
    jz next_up ; se = 0 celula esta vazia vai para proxima celula 

    xor ax, ax
    loop_up:
    mov al, [bx] ;AL recebe o expoente
    mov si, bx
    sub si, 4
    cmp [si], byte ptr 0
    jz can_up;Nao tem nada em baixo
    cmp [si],al
    jnz jump_up
    cmp [bx+offset join_flag], byte ptr 1
    je jump_up
    mov [bx], byte ptr  0 ; zera o numero de cima
    inc byte ptr [si] ; juntou, incrementa expoente do de baixo.
    call add_score 
    
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    je continue_up
    call manage_bot
    continue_up:
    
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    mov [bx+offset join_flag], byte ptr 1
    jump_up:
    mov bl, dh
    jmp next_up
    
    can_up:
    mov [si], al ; Seta expoente na celula de baixo
    xor [bx], ax ; Zera celula de cima
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    ;Celula nao esta vazia, entao determinar numero maximo de movimentos
    mov ax, bx
    shr ax, 2
    dec ax
    jz next_up
    mov bx, si
    jmp loop_up
return_up:
    pop_all
    ret
endp

arrow_down proc
    push_all
    mov bx, 12
next_down:
    dec bx
    cmp bx, 0
    jl return_down
    mov dh, bl        
    cmp [bx], byte ptr  0 ;verifica se celula esta vazia
    je next_down ; se = 0 celula esta vazia vai para proxima celula 

    ;Verificar se tem algo em baixo
    xor ax,ax
    loop_down:
    mov al, [bx] ;AX recebe o expoente
    mov si, bx
    add si, 4
    cmp [si], byte ptr  0
    jz can_down;Nao tem nada em baixo
    ;Tem coisa em baixo, verifica se pode juntar
    cmp [si],al
    jnz jump_down
    cmp [bx+offset join_flag], byte ptr 1
    je jump_down
    mov [bx], byte ptr 0 ; zera o numero de cima
    inc byte ptr [si] ; juntou, incrementa expoente do de baixo.
    call add_score 
    
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    je continue_down
    call manage_bot
    continue_down:
    
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento 
    call print_mat
    mov [bx+offset join_flag], byte ptr 1
    jump_down:
    mov bl, dh
    jmp next_down
    can_down:
    mov [si], al ; Seta expoente na celula de baixo
    xor [bx], ax ; Zera celula de cima
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    ;Celula nao esta vazia, entao determinar numero maximo de movimentos
    mov cx, 2
    mov ax, bx
    shr ax, 2
    sub cx, ax ; cl tem numero maximo de movimentos possiveis
    jz next_down
    mov bx, si
    jmp loop_down
return_down:
    pop_all
    ret
endp

arrow_left proc
    push_all
    xor bx, bx ;comeca na casa 1
    next_left:
    inc bx 
    mov ax, bx
    mov dx, 4
    div dl
    cmp ah, 0
    jnz jump_extra_inc
    inc bx
    jump_extra_inc:
    cmp bx, 15
    ja return_left
    mov dh, bl  ; dh guarda posicao analisada      
    cmp [bx], byte ptr  0 ;verifica se celula esta vazia
    jz next_left ; se = 0 celula esta vazia vai para proxima celula 

    ;Verificar se tem algo em baixo
    loop_left:
    xor ah,ah 
    mov al, [bx] ;AX recebe o expoente
    mov si, bx
    dec si
    cmp [si], byte ptr  0
    jz can_left;Nao tem nada na esquerda
    ;Tem coisa na esquerda, verifica se pode juntar
    cmp [si],al
    jnz jump_left
    cmp [bx+offset join_flag], byte ptr 1
    je jump_left
    mov [bx], byte ptr 0 ; zera o numero da direita
    inc byte ptr [si] ; juntou, incrementa expoente do da esquerda.
    call add_score
    
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    je continue_left
    call manage_bot
    continue_left:
    
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    mov [bx+offset join_flag], byte ptr 1
    jump_left:
    mov bl, dh
    jmp next_left
    can_left:
    mov [si], al ; Seta expoente na celula da esquerda
    xor [bx], ax ; Zera celula da direita
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    ;Celula nao esta vazia, entao determinar numero maximo de movimentos
    
    mov ax, si
    mov dl, 4
    div dl
    cmp ah, 0
    jz next_left
    mov bx, si
    jmp loop_left
    return_left:
    pop_all
    ret
endp

arrow_right proc
    push_all
    mov bx, 15
    next_right:
    mov ax, bx
    and ax, 3
    jnz jump_extra_dec
    dec bx
    jump_extra_dec:
    dec bx 
    cmp bx, 0
    js return_right
    mov dh, bl  ; dh guarda posicao analisada      
    cmp [bx], byte ptr  0 ;verifica se celula esta vazia
    jz next_right ; se = 0 celula esta vazia vai para proxima celula 
    loop_right:
    xor ax,ax 
    mov al, [bx] ;AX recebe o expoente
    mov si, bx
    inc si
    cmp [si], byte ptr  0
    jz can_right
    cmp [si],al
    jnz jump_right
    cmp [bx+offset join_flag], byte ptr 1
    je jump_right
    mov [bx], byte ptr 0 
    inc byte ptr [si]
    call add_score 
    
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    je continue_right
    call manage_bot
    continue_right:
    
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    mov [bx+offset join_flag], byte ptr 1
    jump_right:
    mov bl, dh
    jmp next_right
    can_right:
    mov [si], al 
    xor [bx], ax 
    mov [mov_flag], byte ptr 1 ;Aciona flag indicando que houve movimento
    call print_mat
    mov ax, si
    inc ax
    and ax, 3
    jz next_right
    mov bx, si
    jmp loop_right
    return_right:
    pop_all
    ret
endp

check_gameover proc
    push_all
    mov bx, offset Matriz
    
    check_zero: ;Verifica se tem posicao livre
    cmp [bx], byte ptr 0
    je return_check ;se tem posicao livre o jogo continua
    inc bx
    cmp bx, 15
    jle check_zero
    
    ;Todas posicoes estao ocupadas, verificar se ha como juntar
    next_check:
    dec bx
    cmp bx, 0
    je game_over
        
    cmp bx, 3
    jle beside_only
    
    mov al, [bx-4] ;compara em cima
    cmp [bx], al
    je return_check
    
    beside_only:
    
    mov ax, bx
    and ax, 3
    jz next_check 
      
    mov al, [bx-1]
    cmp [bx], al
    je return_check
    
    jmp next_check
  
    game_over:
    mov [gameover_flag], byte ptr 1
    cmp bot_mode_flag, byte ptr 0 ;verifica se esta no modo bot
    jne end_check
    ;call clear_screen
    mov ax,1124h ;seta cursor em 2 linhas
    int 10h
    
    mov ax,1301h
    mov bx,04h  ;Color
    mov bp, offset game_over_msg
    mov cx, offset game_over_len
    mov dx, 01208h
    int 10h
    mov ax,1123h ;retorna cursor para 1 linha
    int 10h
    mov ax,1301h
    mov bp, offset exit_msg
    mov cx, offset exit_len
    mov dx, 00d10h
    int 10h 
    xor ax, ax
    int 16h 
    cmp ah,01Fh
    jne game_over
    
    mov ax, score
    cmp ax, [best_scores + 8]
    jbe return_check
    call update_hiscore
    end_check:
    call clear_screen
    return_check:
    pop_all
    ret
endp

update_hiscore proc
    call clear_screen
    mov ax,1301h
    mov bx,4  ;Color
    mov bp, offset name_gameover_msg
    mov cx, offset name_gameover_len
    mov dx, 0701h
    int 10h
  
    mov cx, 4 
    mov bx, offset best_scores
    mov si, offset best_players
    mov di, offset best_jogadas
    add si, 30 ;posiciona no penultimo nome
    add bx, 6  ;posiciona no peultimo score
    add di, 6
    search_position: 
    mov ax, score
    cmp ax, [bx]
    jb change_score ;se menor pula pra fazer a troca
    mov dx, [bx] ;se maior move para baixo
    mov [bx+2], dx ;move pro de baixo
    mov dx, [di]
    mov [di+2], dx
    push di
    push cx
    ;move nome
    mov ax, ds ;copia ds para
    mov es, ax ;es
    mov di, si
    add di, 10 
    mov cx, 10
    cld
    move_player_name:
    movsb
    loop move_player_name
    pop cx
    pop di
    sub si, 20
    dec di
    dec di
    dec bx
    dec bx
    loop search_position  
    change_score:
    inc bx
    inc bx
    mov ax, score
    mov [bx], ax
    inc di
    inc di
    mov ax, jogadas
    mov [di], ax
    add si, 10  
    
    mov ax, 0200h
    xor bx,bx
    mov dx, 0714h
    int 10h
    
    mov cx, 10
    read_char:
    mov ax, 0100h
    int 21h
    cmp al, 000Dh ;Verifica se foi apertado ENTER
    je end_read_char
    mov [si], al
    inc si
    loop read_char
    
    end_read_char:
    mov [si], byte ptr 32 ;preenche o resto com espa?o  
    inc si
    loop end_read_char
    
    ret
endp

clear_flags proc
    mov bx, offset join_flag
    mov cx, 17
    
    clear_loop:    
    mov [bx], byte ptr 0
    inc bx
    loop clear_loop
    ret
endp

start:
    mov ax, @DATA
    mov ds, ax
    mov ax, @DATA
    mov es, ax   
      
    mov ax, 013h
    int 10h
    
    call set_memory
    
    call show_menu
    call getkey_menu   

end start