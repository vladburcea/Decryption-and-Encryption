extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main


; ================= My functions =================

; The only argument given to the function is 
; the string that has both the key and the code
; The key is returned in eax

parse_input:
        push ebp
        mov ebp, esp
        
        xor eax, eax
        mov eax, [ebp+8]    ; getting the argument from stack
        
        cmp byte [eax], 0x00 ; if it's null don't try anything
        je skip
        
get_key:        ; Separating the string from the key
        inc eax
        cmp byte[eax], 0x00
        jne get_key
        inc eax     ; Now eax points to the key
    
skip:
        leave
        ret 4
    
; Calculating the length of a string and saving the result in eax
; The function receives an argument -> the pointer to the string
    
get_length:
        push ebp
        mov ebp, esp
        
        ; Saving edi
        push edi
        
        xor edi, edi
        xor eax, eax                    ; eax will be incremented once for every char != '\0'
        mov edi, dword[ebp+8]           ; getting the string pointer
    
iterate_over_string:
        inc eax
        cmp byte[edi + eax], 0x00       ; Checking for null terminator
        jne iterate_over_string
        dec eax
    
        ; Restoring the value of edi
        pop edi
        
        leave
        ret 4                           ; Return with esp+4
    
    
; This function receives a single byte representing a string and
; transforms it into an integer. After that it makes the base change
; from hex to dec
; The change is done in place. No return value is needed

hex_to_binary:
        push ebp
        mov ebp, esp
    
        ; Saving value found in eax    
        push eax
        
        xor eax, eax
        mov eax, dword[ebp+8]
    
        ; If it's bigger than 0x39 ('9') than it is a letter
        cmp al, 0x39    ; '9'    
        ja is_letter
        
        sub al, 0x30    ; Any number in ascii - '0' (0x30) is equal to their integer value
        jmp skip_letter
        
is_letter:    
    
        ; For letters we need to subtract 87 to get their integer values
        sub al, 0x57     
    
skip_letter:
        
        mov dword[ebp+8], eax
        
        ; Restoring value found in eax
        pop eax
        
        leave 
        ret

; ==================== Tasks ====================
            
; Task 1

xor_strings:
        push ebp
        mov ebp, esp
    
        ; Saving the values found in eax, edi, ebx
        push eax
        push edi
        push ebx
        
        xor eax, eax
        xor edi, edi
        xor ebx, ebx
        
        mov ebx, [ebp+8]        ; the codified message
        mov edi, [ebp+12]       ; the key
    
decode:
        mov al, byte [edi]  ; Moving a byte from the key to al
        xor byte [ebx], al  ; Applying the key to the string
        inc edi
        inc ebx
        cmp byte [ebx], 0x00
        jne decode    
    
        ; Retrieving the values from the stack
        pop ebx
        pop edi    
        pop eax
        
        leave
        ret
    
; Task 2
    
rolling_xor:
        push ebp
        mov ebp, esp
        
        ; Saving the values in the registers
        push eax
        push edi
        
        xor edi, edi
        mov edi, dword [ebp+8]      ; the string to be decrypted
        
        ; Make edi point to the end of the string
        xor eax, eax
        push edi
        call get_length
        add edi, eax    
        
decipher:
        xor eax, eax
        mov al, byte[edi-1]         ; Get a byte of the string
        xor byte[edi], al           ; Apply the decryption
        dec edi                     ; Continiue iteration 
        cmp edi, dword [ebp+8]      ; Stop at the begining of the string
        jne decipher
        
        ; Retrieving the saved values        
        pop edi
        pop eax
        
        leave
        ret
    
; Task 3
    
xor_hex_strings:
        push ebp
        mov ebp, esp
    
        mov esi, dword[ebp+8]       ; [ebp+8] - string    
        mov edi, dword[ebp+12]      ; [ebp+12] - key
                
        ; EAX will be used as an iterator over the newly formed string
        xor eax, eax    
        lea eax, [esi]
        
        ; To apply the key at this task firstly you need to take the string
        ; and transform it to binary. TO do that 
        ; 0x12 = 1 * 16^1 + 2 * 16^0 = 18
        
iterate_over_strings:
        ; ================== Key ======================
        xor edx, edx
        mov dl, byte[edi]       ; solving the first part of the hex value
        push edx                ; parsing from string to integer (and from hex to bin)
        call hex_to_binary
        pop edx
        mov dh, dl              ; Store the calculated value in dh (hex_to_binary doesn't mess with the first 8bit register
        xor dl, dl
        
        ; As this is only the first part of the number it needs to be multiplied by 16 (2^4)
        shl dh, 4              ; shifting left 4 times is equal to multiplying by 16
        
        xor dl, dl           
        mov dl, byte[edi+1]     ; solving the 2nd part
        push edx
        call hex_to_binary
        pop edx
    
        add dl, dh          ; the 2nd part doesn't need to be shifted (16^0 = 1)
        xor dh, dh
        ; Now edx holds the value of a character from the key
        
        ; ================= String ====================
        
        xor ebx, ebx
        mov bl, byte[esi]       ; solving the first part of the hex value    
        push ebx                ; parsing from string to integer (and from hex to bin)
        call hex_to_binary
        pop ebx
    
        mov bh, bl
        shl bh, 4
        
        xor bl, bl              ; solving the 2nd part
        mov bl, byte[esi+1]
        push ebx
        call hex_to_binary
        pop ebx
    
        add bl, bh              
        xor bh, bh
        ; Now ebx holds the value of a character from the string        
        
        ; =============== Decryption ==================
    
        ; Applying the decryption key on the string                                
        xor edx, ebx
    
        ; Saving the decrypted message in the string 
        mov byte[eax], dl
        
        ; For each character from the decrypted message we use 
        ; 2 bytes from the string and from the key
        add esi, 2              
        add edi, 2
        inc eax                 ; Incrementing iterator over newly formed string
        cmp byte[esi], 0x00
        jne iterate_over_strings
        
        ; Adding a null terminator at the end of the new string
        mov byte[eax], 0x00
        
        leave
        ret
    
solve_encoding:
        push ebp
        mov ebp, esp    
    
        push edx
                
        xor edx, edx
        mov edx, dword[ebp+8]
        
        cmp dl, 0x41
        jl is_digit
        
        sub dl, 0x41
        jmp done
        
is_digit:    
        sub dl, 0x18
        
done:
        
        mov dword[ebp+8], edx
        
        pop edx
    
        leave
        ret

; Task 4    
    
base32decode:
        push ebp
        mov ebp, esp
    
        pushad
    
        mov esi, dword[ebp+8]           ; Encoded string
        xor edi, edi                    ; Iterator for the string while decoding
        
        ; In base32 encoding 'A' is 0x0. In ASCII 'A' is 0x41.
        ; So for the conversion of every byte from ASCII to base32 it's enough to
        ; subtract 0x41 if it's a letter, and 0x18 if it's a number from 2 to 7
        
        ; For every charcater in the string the value of the code can be stored on 5 bits
        ; 8 BYTES from the string correspond to 5 BYTES (40bits) of actual message 
        ; So when you iterate through the string you save 5 bits in a register, shift 
        ; said register to the left and continue storing until it's full. After that you 
        ; need another BYTE (4*8 -> one 32bit register, 8 -> one 8bit register)
        
        ; This algorithm works because for every 8 bytes of encoded string we have 5 bytes of
        ; actual message. The memory is enough, not to overflow.
        
continiue_iteration:
        xor ecx, ecx                    ; Use ecx to count 6 iterations
        xor eax, eax                    ; Use eax as a buffer
        
process_6_bytes:
        xor edx, edx
        mov dl, byte[esi]               ; Get one byte from the string
    
        push edx
        call solve_encoding             ; Figure out the code behind the character
        pop edx                         ; dl now has the value needed
        
        shl eax, 5                      ; Make space for the 5 new bits
        or eax, edx                     ; Save the 5 bits into the buffer
    
        inc esi                         ; Move on to the next byte
        inc ecx
        cmp ecx, 0x06
        jb process_6_bytes              ; Do this only for 6 bytes of the string at once
    
        ; At this point eax has 30bits of the message so 2 more need to be added so we could write it
        shl eax, 2                      ; Making space
    
        ; Getting the last 2 bits put into the buffer
        xor edx, edx
        mov dl, byte[esi]  
        push edx
        call solve_encoding
        pop edx
        
        push edx                        ; Save the 5 bits. The last 3 will be needed later
        shr edx, 3                      ; Getting rid of the 3 bits that don't fit into eax
        or eax, edx                     ; eax is now complete
        pop edx                         ; Get the value (we need the last 3 bits)
        and edx, 0x07                   ; Get rid of the first 2 bits
        shl edx, 5                      ; Make room for the last 5 bits
        inc esi
        
        push eax                        ; Saving the value of eax (4 bytes of the message at this iteration)
    
        ; Using eax to parse the last byte (of the 5)
        xor eax, eax                    
        mov al, byte[esi]
        push eax
        call solve_encoding
        pop eax                         ; In al is now stored the last byte from the string (at this iteration)
        
        or edx, eax                     ; dl now has the last byte(of the 5) from the message (at this iteration)
        
        pop eax                         ; Restore the value of the first 4 bytes of the message(at this iteration)
        
        xor ecx, ecx
        mov ecx, dword[ebp+8]           ; Using ecx to store the message over the old string
        
        mov byte[ecx+4+edi], dl         ; Put the first last byte of the 5 (resulted after decoding the string)
    
        ; Now to put eax into the output string
        mov byte[ecx+3+edi], al         ; Put the last 8 bits where they belong 
        shr eax, 8                      ; Get rid of the bits already copied and repeat 4 times
        mov byte[ecx+2+edi], al
        shr eax, 8
        mov byte[ecx+1+edi], al
        shr eax, 8
        mov byte[ecx+edi], al
        shr eax, 8    
    
        inc esi                         ; Move forward in the string
        add edi, 0x05                   ; I've just saved 5 bytes

        ; If the string that has to be decoded is a multiple of 8 then there won't be any padding 
        ; at the end of the string
        cmp byte[esi-1], 0x00           
        je finished_decoding
    
        cmp byte[esi-1], '='            ; Look for padding and if it's not found continue the loop
        jne continiue_iteration
        
        sub edi, 0x03                   ; In the case that the string is not a multiple of 8 account for that
    
finished_decoding:                
        mov ecx, dword[ebp+8]           
        mov byte[ecx+edi], 0x00         ; adding a null terminator at the end of the new string
        
        popad
        
        leave
        ret
        
; Task 5
    
bruteforce_singlebyte_xor:
        push ebp
        mov ebp, esp
        
        xor ecx, ecx        ; Key starts from 0x0
        mov ecx, 0x0
    
try_keys:
        ; esi starts from the begining of the string for every new key
        mov esi, dword[ebp+8]
        
try_key_on_string:
        ; Using the key on the string
        xor ebx, ebx
        mov bl, byte[esi]
        xor bl, cl
        
        ; Check if an 'f' is found so we can look for "force"
        cmp bl, 0x66    ; 'f' in ascii is 0x66
        jne skip_check
        
        xor eax, eax
        
        ; Supposed 'f'
        add eax, ebx
        inc esi
            
        ; Supposed 'o'
        mov bl, byte[esi]
        xor bl, cl
        add eax, ebx
        inc esi
            
        ; Supposed 'r'
        mov bl, byte[esi]
        xor bl, cl
        add eax, ebx
        inc esi
        
        ; Supposed 'c'
        mov bl, byte[esi]
        xor bl, cl
        add eax, ebx
        inc esi
        
        ; Supposed 'e'
        mov bl, byte[esi]
        xor bl, cl
        add eax, ebx
    
        ; If the sum is equal to 527 ('f' + 'o' + 'r' + 'c' + 'e')
        ; then the key is found
        cmp eax, 0x20F
        je found_key
    
        ; If "force" wasn't found return to the next character and continue looking
        sub esi, 4
    
skip_check:        
        inc esi                     ; Continue looking for "force" with this key
        cmp byte[esi], 0x00         ; Stop at the end of the string
        jne try_key_on_string
    
        inc ecx                     ; Try a new key
        cmp ecx, 0xFF               ; Stop at 255 (the key is only one byte long)
        jbe try_keys
        
found_key:
        ; When the key is found it remains in cl
        ; Now we iterate over the string and apply it
        mov esi, dword[ebp+8]
        
apply_key: 
        xor byte[esi], cl       
        inc esi
        cmp byte[esi], 0x00
        jne apply_key
        
        xor eax, eax
        mov eax, ecx                ; Return the key in eax

        leave        
        ret

; Task 6
            
decode_vigenere:
        push ebp
        mov ebp, esp
        
        xor edi, edi
        xor esi, esi
        
        mov esi, dword[ebp+8]     ; [ebp+8] = string
        mov edi, dword[ebp+12]    ; [ebp+12] = key
        
        ; Getting the length of the key
        push edi
        call get_length
        push eax            ; [ebp-4] -> length of the key
        
        xor eax, eax        ; key iterator
        xor ebx, ebx        ; string iterator    
        
resolve_cypher:
        cmp eax, dword[ebp-4]
        jbe skip_counter_reset
        
        ; If the iterator gets to the length of
        ; the key then we need to reset it 
        xor eax, eax
                
skip_counter_reset:            
        ; Get the right byte from the key
        xor edx, edx
        mov dl, byte[edi+eax]
        sub edx, 0x61        ; value of 'a'
        
        ; Getting the character from the string
        xor ecx, ecx
        mov cl, byte[esi+ebx]
          
        ; If the character isn't a letter then we need to skip it
        ; Ascii values: a = 97(0x61), z = 122(0x7A)
    
        cmp cl, 0x61        ; 'a'
        jb not_a_letter
        
        cmp cl, 0x7A        ; 'z'
        ja not_a_letter
    
    
        ; If the character is indeed a letter 
        ; we need to apply the decryption chypher    
        sub byte[esi+ebx], dl
        
        cmp byte[esi+ebx], 0x61
        jae skip_add
        
        ; If we get a value below 0x61('a') that means that 
        ; the letter had a smaller ascii value than the key 
        ; (after processing)
        
        add byte[esi+ebx], 26
        
skip_add:        
        ; We increment the iterator for the key only if use the key
        inc eax
    
not_a_letter:        
        inc ebx         ; Incrementing iterator over string    
        
        cmp byte[esi+ebx], 0x00 
        jne resolve_cypher
        
        ; Restoring stack
        add esp, 4
        
        leave
        ret
    
main:
        mov ebp, esp; for correct debugging
        push ebp
        mov ebp, esp
        sub esp, 2300
        
        ; test argc
        mov eax, [ebp + 8]
        cmp eax, 2
        jne exit_bad_arg
        
        ; get task no
        mov ebx, [ebp + 12]
        mov eax, [ebx + 4]
        xor ebx, ebx
        mov bl, [eax]
        sub ebx, '0'
        push ebx
        
        ; verify if task no is in range
        cmp ebx, 1
        jb exit_bad_arg
        cmp ebx, 6
        ja exit_bad_arg
        
        ; create the filename
        lea ecx, [filename + 7]
        add bl, '0'
        mov byte [ecx], bl
        
        ; fd = open("./input{i}.dat", O_RDONLY):
        mov eax, 5
        mov ebx, filename
        xor ecx, ecx
        xor edx, edx
        int 0x80
        cmp eax, 0
        jl exit_no_input
        
        ; read(fd, ebp - 2300, inputlen):
        mov ebx, eax
        mov eax, 3
        lea ecx, [ebp-2300]
        mov edx, [inputlen]
        int 0x80
        cmp eax, 0
        jl exit_cannot_read
        ; close(fd):
        mov eax, 6
        int 0x80
        
        ; all input{i}.dat contents are now in ecx (address on stack)
        pop eax
        cmp eax, 1
        je task1
        cmp eax, 2
        je task2
        cmp eax, 3
        je task3
        cmp eax, 4
        je task4
        cmp eax, 5
        je task5
        cmp eax, 6
        je task6
        jmp task_done
    
task1:
        ; TASK 1: Simple XOR between two byte streams
        xor eax, eax
        
        ; Resolving the format
        push ecx
        call parse_input
        ; Now eax points to the key
    
        push eax                    ; The key
        push ecx                    ; The codified message
        call xor_strings
        add esp, 8

        push ecx
        call puts                   ;print resulting string
        add esp, 4 
        
        jmp task_done
    
task2:
        ; TASK 2: Rolling XOR
        push ecx
        call rolling_xor
        add esp, 4
        
        push ecx
        call puts
        add esp, 4
    
        jmp task_done
    
task3:
        ; TASK 3: XORing strings represented as hex strings
        
        xor eax, eax
    
        push ecx
        call parse_input
            
        push eax
        push ecx
        call xor_hex_strings
        add esp, 8
        
        push ecx                     ;print resulting string
        call puts
        add esp, 4
        
        jmp task_done
    
task4:
        ; TASK 4: decoding a base32-encoded string
    
        push ecx
        call base32decode
        add esp, 4
        
        push ecx
        call puts                    ;print resulting string
        pop ecx
        	
        jmp task_done
    
task5:
        ; TASK 5: Find the single-byte key used in a XOR encoding
        push ecx
        call bruteforce_singlebyte_xor
        pop ecx
        push eax
        
        push ecx                    ;print resulting string
        call puts
        pop ecx
        
        pop eax
    
        push eax                    ;eax = key value
        push fmtstr
        call printf                 ;print key value
        add esp, 8
    
        jmp task_done
    
task6:
        ; TASK 6: decode Vignere cipher    
        push ecx
        call strlen
        pop ecx
    
        add eax, ecx
        inc eax
    
        push eax
        push ecx                   ;ecx = address of input string 
        call decode_vigenere
        pop ecx
        add esp, 4
    
        push ecx
        call puts
        add esp, 4
    
task_done:
        xor eax, eax
        jmp exit
    
exit_bad_arg:
        mov ebx, [ebp + 12]
        mov ecx , [ebx]
        push ecx
        push usage
        call printf
        add esp, 8
        jmp exit
    
exit_no_input:
        push filename
        push error_no_file
        call printf
        add esp, 8
        jmp exit
    
exit_cannot_read:
        push filename
        push error_cannot_read
        call printf
        add esp, 8
        jmp exit
    
exit:
        mov esp, ebp
        pop ebp
        ret
