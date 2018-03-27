.286

ASTACK SEGMENT stack
db 100h dup(?)
ASTACK ENDS

DATA SEGMENT
    INT_LOAD DB 'INTERRUPTION JUST LOADED',0AH,0DH,'$'
    INT_IS_LOADED DB 'INTERRUPTION IS ALREADY LOADED !!!',0AH,0DH,'$'
    EXIT_FROM_INTERR DB 'EXIT FROM INTERRUPTION',0AH,0DH,'$'
    INT_NOT_LOADED DB 'INTERRUPTION NOT LOADED!!!',0AH,0DH,'$'
	
DATA ENDS

CODE SEGMENT
	 ASSUME CS:CODE, DS:CODE, ES:CODE, SS:ASTACK     

PRINT PROC NEAR 
    pusha
    push ds
    mov ax, DATA
    mov ds, ax
    mov ah, 09h
    int 21h
    pop ds
    popa

    ret
PRINT ENDP

outputAL PROC NEAR

	mov ah, 09h		 
	mov cx, 1      
	mov bh, 0        
	int 10h  

	ret
outputAL ENDP

ROUT PROC FAR
    jmp entry
    	STRN DB 'ABC'
    entry:
    	pusha
	push es
	push ds
	
	;getCurs

	mov ah,03h   
	mov bh, 0    
	int 10h        
	push dx      
	push cx      

	call outputAL 

	; setCurs  
	pop cx            
	pop dx            
	mov ah, 02h       
	int 10h           
	 
	inc cs:COUNTER
		
    ; end of code
	pop ds
	pop es
    popa
    mov al, 20h
    out 20h, al
    iret
    KEEP_CS DW 0
    KEEP_IP DW 0
    KEEP_PSP DW 0h
    COUNTER DW 0h
    last_byte:
ROUT ENDP


SET_INT	 PROC NEAR
    pusha
    push ds
    push es
   
    mov ah, 35h
    mov al, 1Ch
    int 21h
 
    mov cs:KEEP_IP, bx   
    mov cs:KEEP_CS, es
    
    mov ax, SEG ROUT
    mov ds, ax
    mov dx, offset ROUT
    mov ah, 25h
    mov al, 1Ch
    int 21h
    ;end
    mov dx, offset last_byte
    shr dx, 4
    inc dx
    add dx, CODE
    sub dx, cs:KEEP_PSP
    mov ah, 31h
    int 21h
    
    pop es
    pop ds
    popa

    ret
SET_INT ENDP

CHECK_INT PROC NEAR ; if set then al=1, else al=0
    cli
    pusha
    push ds
    push es

    mov ah, 35h
    mov al, 1Ch
    int 21h

    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
    
    cmp word ptr es:STRN+0, 'BA'
    jne no
    cmp byte ptr es:STRN+2, 'C'
    jne no
    
    yes:
    pop es
    pop ds
    popa
    mov al, 1
    sti
    jmp end_ch
    no:
    pop es
    pop ds
    popa
    mov al, 0
    sti
    end_ch:

    ret
CHECK_INT ENDP

DELETE_INT PROC NEAR
    cli
    pusha
    push ds
    push es
    mov ah, 35h
    mov al, 1Ch
    int 21h

    push es
    mov dx, es:KEEP_IP
    mov ax, es:KEEP_CS
    mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h

    pop es
    mov es, es:KEEP_PSP
    push es
    mov es, es:[2Ch] 
    mov ah, 49h
    int 21h

    pop es
    mov ah, 49h
    int 21h
    pop es
    pop ds
    popa
    sti

    ret
DELETE_INT ENDP

EXIT_FROM_INTER PROC NEAR
  pusha                             
  cmp byte ptr ES:[82H], '/'
  jne exit_from_int
  cmp byte ptr es:[83H], 'u'
  jne exit_from_int
  cmp byte ptr es:[84H], 'n'
  jne exit_from_int
  
  popa
  mov al, 1
  jmp end_ex
  exit_from_int:
  popa
  mov al, 0
  end_ex:

  ret 
EXIT_FROM_INTER ENDP 


BEGIN:
	push DS 
	sub AX,AX 
	push AX 
    mov cs:KEEP_PSP, ds

    ;checking /un to exit or not

    call EXIT_FROM_INTER
    cmp al, 1
    je end_int
    call CHECK_INT
    cmp ax, 0
    jne loading
    mov dx, offset INT_LOAD
    call PRINT
    call SET_INT
    jmp exit
	
    ;already loaded
    loading:
    mov dx, offset INT_IS_LOADED
     call PRINT
    jmp exit
    call CHECK_INT
    cmp al, 1
    jne already_loaded
    ;exit from int
     end_int:
     call DELETE_INT
     mov dx, offset EXIT_FROM_INTERR
     call PRINT
    jmp exit
    already_loaded:
     mov dx, offset INT_LOAD
     call PRINT
	
    exit:
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
END BEGIN
