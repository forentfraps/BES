
global Encrypt16Bytes
global Decrypt16Bytes


section .text

Encrypt16Bytes:
  ;rdi block_enc (16 byte)
  ;rsi seed (16 byte)
  ;rdx dest (32 byte)
  ;xmm3-4 output

  xorps xmm3, xmm3
  xorps xmm4, xmm4
  movdqa xmm2, [rdi]
  movdqa xmm5, [rsi]
  ;xmm3 lower part
  mov rcx, 8
  movaps xmm0, xmm5
  xor r9, r9
Encrypt16Bytes_win_cycle:
  inc r9
  aesenc xmm0, xmm5
  vpcmpeqb xmm1, xmm0, xmm2
  pmovmskb eax, xmm1
  test al, 1
  jz Encrypt16Bytes_win_cycle
  movaps xmm5, xmm0
  cmp r9, 65535
  jge CRITICAL_ERROR
  movq xmm0, r9
  xor r9, r9
  pslldq xmm3, 2
  psrldq xmm2, 1
  por xmm3, xmm0

  dec rcx
  movaps xmm0, xmm5
  jnz Encrypt16Bytes_win_cycle
  ;xmm4 higher part
  mov rcx, 8
  xor r9, r9
Encrypt16Bytes_win_cycle2:
  inc r9
  aesenc xmm0, xmm5
  vpcmpeqb xmm1, xmm0, xmm2
  pmovmskb eax, xmm1
  test al, 1
  jz Encrypt16Bytes_win_cycle2
  movaps xmm5, xmm0
  cmp r9, 65535
  jge CRITICAL_ERROR
  movq xmm0, r9
  xor r9, r9
  pslldq xmm4, 2
  por xmm4, xmm0
  psrldq xmm2, 1
  dec rcx
  movaps xmm0, xmm5
  jnz Encrypt16Bytes_win_cycle2
  movdqa xmm1, [reverse_word_mask]
  pshufb xmm3, xmm1
  pshufb xmm4, xmm1
  movdqa [rdx], xmm3
  movdqa [rdx+ 0x10], xmm4
  xor eax, eax
  ret



Decrypt16Bytes:
  ;rdi - encrrypted_buffer 32 bytes
  ;rsi - seed 16 bytes
  ;rdx - dest 16 bytes

  movdqa xmm2, [rsi]
  xor r9, r9 
  xor rax, rax
  movdqa xmm0, xmm2
Decrypt16Bytes_cycle_outer:
  mov ax, [rdi + r9 * 2]
  and rax, 0xffff

Decrypt16Bytes_cycle_inner:
  aesenc xmm0, xmm2
  dec rax
  jnz Decrypt16Bytes_cycle_inner

  pextrb rax, xmm0, 0
  movdqa xmm2, xmm0
  mov [rdx + r9], al
  inc r9
  cmp r9, 16
  jb Decrypt16Bytes_cycle_outer
  xor eax, eax
  ret





CRITICAL_ERROR:
  hlt


section .data
reverse_word_mask db 14, 15, 12, 13, 10, 11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1
