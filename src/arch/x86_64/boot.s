
global start

section .text
bits 32
start:
    mov dword [0xb8000], 0x2f4b2f4f
    ; Call system checks
    call check_multiboot
    call check_cpuid
    
    hlt



; Prints `ERR: ` and the given error code to screen and hangs.
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al         ; Move error code (al) to 0xb800a
    hlt

; Multiboot check
; Checks for a feature and jump to error if it's not available.
; According to the Multiboot specification, the bootloader must write the magic value 0x36d76289 to it before loading a kernel. To verify that we can add a simple function
check_multiboot:
    cmp eax, 0x36d76289 ; Compare general purpose register (eax) with value 0x36d76289
                        ; If the values are equal, the cmp instruction sets the zero flag in the FLAGS register.

    jne .no_multiboot   ; jump if not equal
    ret
.no_multiboot:
    mov al, "0"
    jmp error

; CPUID check
check_cpuid:
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.

    ; Copy FLAGS in to EAX via stack
    pushfd ; Push flag doubles on to the stack, as you can't operate on the flags reg
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax

    ; Restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

section .bss
stack_bottom:
    resb 64     ; reserve 64 bytes
stack_top: