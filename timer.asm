;Timer
[BITS 16]
[ORG 0x7C00]

TIMES_COUNTER DW 0                     ; 计数器
SECOND_SINGLE DD 0                     ; 秒数个位
SECOND_TENS DD 0                       ; 秒数十位
MINUTE_SINGLE DD 0                     ; 分钟数个位
MINUTE_TENS DD 0                       ; 分钟数十位

;寄存器初始化
CLI
MOV SP, 0x7C00
XOR AX, AX
MOV SS, AX
MOV ES, AX
MOV DS, AX

STI
CALL PRINT                             ; 打印00:00

CLI
CALL SET_INTERRUPT                     ; 设置中断向量表
CALL SET_TIMER                         ; 设置定时器
STI

JMP $                                  ; 无限循环

CLOCK_INTERRUPT:                       ; 时钟中断处理例程
    PUSHA

    INC WORD [TIMES_COUNTER]           ; 增加计数器的值
    CMP WORD [TIMES_COUNTER], 50       ; 当计数器值为50时打印文本
    JNE SKIP

    CALL PRINT
    MOV WORD [TIMES_COUNTER], 0        ; 重置计数器

    SKIP:
    MOV AL, 0x20
    OUT 0x20, AL                       ; 发送EOI命令给8259A中断控制器

    POPA
    IRET

SET_INTERRUPT:
    MOV AX, 0        
    MOV ES, AX
    MOV WORD [ES:4*0x08], CLOCK_INTERRUPT        ; 将自己编写的时钟中断处理例程写入中断向量表
    MOV WORD [ES:4*0x08+2], CS
    RET



SET_TIMER:                             ; 设置8253/4定时器芯片
    MOV AL, 0x36 
    OUT 0x43, AL                       ; 将AL寄存器中的值发送到端口0x43，用于向8253/4定时器芯片发送指令
    MOV AX, 0x5D37                     ; 每隔20ms产生一次时钟中断
    OUT 0x40, AL                       ; 将AX寄存器中的值发送到端口0x40，用于设置定时器初值（低8位）
    MOV AL, AH
    OUT 0x40, AL                       ; 将AX寄存器中的值发送到端口0x40，用于设置定时器初值（高8位）
    RET

PRINT:
    MOV AX, 0x0003
    INT 0x10                           ; 清屏

    MOV AX, 0x0600
    MOV BH, 0x02
    XOR CX, CX
    MOV DX, 0x184F
    INT 0x10                           ; 设置窗口大小及字体颜色

    MOV AH, 0x02
    MOV BX, 0
    MOV DX, 11*0x100+38
    INT 0x10                           ; 设置光标位置

    MOV AH, 0x0E
    MOV AL, [MINUTE_TENS]
    add AL,'0'                         ; 将数字转换为ASCII码
    INT 0x10                           ; 打印分钟数十位

    MOV AH, 0x0E
    MOV AL, [MINUTE_SINGLE]
    add AL,'0'
    INT 0x10                           ; 打印分钟数个位

    MOV AH, 0x0E
    MOV AL, ':'
    INT 0x10

    MOV AH, 0x0E
    MOV AL, [SECOND_TENS]
    add AL,'0'
    INT 0x10                           ; 打印秒数十位

    MOV AH, 0x0E
    MOV AL, [SECOND_SINGLE]
    add AL,'0'
    INT 0x10                           ; 打印秒数个位

    ; 递增当前数字
    INC WORD [SECOND_SINGLE]
    CMP WORD [SECOND_SINGLE],10        ; 秒数个位满10进1
    JNE PRINT_RET
    MOV WORD [SECOND_SINGLE], 0
    INC WORD [SECOND_TENS]
    CMP WORD [SECOND_TENS],6           ; 秒数十位满6进1
    JNE PRINT_RET
    MOV WORD [SECOND_TENS], 0
    INC WORD [MINUTE_SINGLE]
    CMP WORD [MINUTE_SINGLE],10        ; 分钟数个位满10进1
    JNE PRINT_RET
    MOV WORD [MINUTE_SINGLE], 0        ; 分钟数十位满6进1
    INC WORD [SECOND_TENS]

PRINT_RET:
    RET

TIMES 510-($-$$) DB 0
DW 0xaa55