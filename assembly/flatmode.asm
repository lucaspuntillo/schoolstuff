; flatmode.asm
;
;  This program demonstrates flat real mode, which is simply real mode
;  with 4G descriptors for some segments.  In this code it's done by
;  going into protected mode, setting the FS register to a descriptor
;  with 4G limits and then returning to real mode.  The protected mode
;  limit stays in effect, giving "flat real mode."
;
;  The demonstration part of this code writes the first 160 bytes from
;  the system ROM at F0000h (linear) to the color screen which is assumed
;  to be at B8000h (linear) using a flat real mode selector.  Since that
;  range of the system ROM typically contains a copyright notice, one
;  can easily see that the code is truly working as advertised.
;
;  This code is intended to be run on a Pentium or better.
;
;  To assemble:
;
; using Microsoft's MASM 6.11 or better
;   ml /Fl flatmode.asm
;
;----------------------------------------------------------------------
        .model tiny
        .code
        .586P

DESC386 STRUC
        limlo   dw      ?
        baselo  dw      ?
        basemid db      ?
        dpltype db      ?       ; p(1) dpl(2) s(1) type(4)
        limhi   db      ?       ; g(1) d/b(1) 0(1) avl(1) lim(4)
        basehi  db      ?
DESC386 ENDS

;----------------------------------------------------------------------
        ORG 100h
start:
        call  flatmode          ; go into flat real mode (fs reg only)
;        mov dx,5                ;
;        mov fs,dx               ;
        call  fillscreen        ; fill the screen using 4G descriptor
        mov ax,4c00h            ; do a standard DOS exit
        int 21h                 ;
;----------------------------------------------------------------------
fillscreen proc
        mov     esi,0F0050h     ; point to ROM
ifdef BEROSET
        mov     edi,0B8000h     ; point to screen
else
        mov     di,0b800h       ;
        mov     es,di           ;
        xor     edi,edi         ;
endif
        mov     cx,160          ; just two lines
        mov     ah,1Eh          ; yellow on blue screen attrib
myloop:
        mov     al,fs:[esi]     ; read ROM byte
ifdef BEROSET
        mov     fs:[edi],ax     ; store to screen with attribute
else
        mov     es:[di],ax      ; store to screen with attribute
endif
        inc     esi             ; increment source ptr
        inc     edi             ; increment dest ptr by two
        inc     edi             ;
        loop    myloop          ; keep going
        ret                     ; and quit
fillscreen endp
;----------------------------------------------------------------------
flatmode proc
        ; first, calculate the linear address of GDT
        xor     edx,edx         ; clear edx
        xor     eax,eax         ; clear edx
        mov     dx,ds           ; get the data segment
        shl     edx,4           ; shift it over a bit
        add     dword ptr [gdt+2],edx   ; store as GDT linear base addr

        ; now load the GDT into the GDTR
        lgdt    fword ptr gdt   ; load GDT base (286-style 24-bit load)
        mov     bx,1 * size DESC386 ; point to first descriptor
        mov     eax,cr0         ; prepare to enter protected mode
        or      al,1            ; flip the PE bit
        cli                     ; turn off interrupts
        mov     cr0,eax         ; we're now in protected mode
        mov     fs,bx           ; load the FS segment register
        and     al,0FEh         ; clear the PE bit again
        mov     cr0,eax         ; back to real mode
        sti                     ; resume handling interrupts
        ret                     ;
flatmode endp
;----------------------------------------------------------------------
GDT     DESC386 <GDT_END - GDT - 1, GDT, 0, 0, 0, 0>  ; the GDT itself
        DESC386 <0ffffh, 0, 0, 091h, 0cfh, 0>          ; 4G data segment
GDT_END:
end start
