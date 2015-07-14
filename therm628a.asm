;__________________________________________________________________________________________________
;|-------------------------------------------------------------------------------------------------|
;| ����������: ��������� � ������������ ����������                                                 |
;|-------------------------------------------------------------------------------------------------|
;| �����:      picmaniac (picmaniac@rambler.ru)  FREEWARE					   |
;| ��������������:	Deman	(bzzzsmuv@rambler.ru)	������: 2.4b   ����: 21. 11. 2007 �.       |
;| �������������� ��� ���� ��������: Fifan (retrohobby@yandex.ru) ����: 04.03.2015 �.  	           |
;|-------------------------------------------------------------------------------------------------|
;|-------------------------------------------------------------------------------------------------|
;| ������ ����������:	                                                                           |
;|	�������� SLEEP ��� ������ �� �������� � ����������� �� ������ �� RB0 (6 �����)             |
;|-------------------------------------------------------------------------------------------------|
;| ��������� �� ���������� �����: ������ ��� PIC16F628A, ������� � ��� PIC16F628                   |
;|-------------------------------------------------------------------------------------------------|
;| ��������� �� ���������: ������� � ����� MPLAB 7.42 ��� WINDOWS XP SP1                           |
;|_________________________________________________________________________________________________|

                 LIST P=16F628A  
                 #include <P16F628A.inc>       	;��������� ����������� ���� ��������� MPLAB
 __CONFIG 3F10
		 radix    hex

	#define	BUT	PORTA,0
	#define	ds4	PORTA,4
	#define	SLS	PORTA,5
	#define	ds7	PORTA,7

	#define autsam	flag,0	
	#define V4_7	flag,1	
;                          --- ���������  ---

;                         --- ������������ ---

jnz	MACRO	metka1             		; �������� �������,
	btfss	STATUS,Z           		; ���� �� 0
	goto	metka1
	endm

jz	MACRO	metka2             		; �������� �������,
	btfsc	STATUS,Z           		; ���� 0
	goto	metka2
	endm

jnc	MACRO	metka3             		; �������� �������,
	btfss	STATUS,C	   		; ���� ��� ��������
	goto	metka3
	endm

jc	MACRO	metka4             		; �������� �������,
	btfsc	STATUS,C	   		; ���� �������
	goto	metka4
	endm

mov     MACRO   DEST1,SOURCE1      		; ��������� �������-�������
	movf    SOURCE1,W
	movwf   DEST1
	endm

mvi     MACRO   DEST2,CONST2       		; ��������� ��������� � �������
	movlw   CONST2
	movwf   DEST2
	endm

;                         --- �������� ��������� ---
W_copy		EQU	020h			; � ���� ��������� ����� 
ST_copy		EQU	021h			; ����������� ��������
FSR_copy	EQU	022h
ADDRESS		EQU	023h			; �������� ������ ������, �������� ��������� �����������
SELECTOR	EQU	024h			; ��� ������ ���������� (�.� ����������� �������)
TH		EQU	025h			; ����������� - ������� ����
TL		EQU 	026h			; ����������� - ������� ����
CRCPIC		EQU	027h			; ����������� �����, ������������ �����������������
TRY		EQU	028h			; ������� ������ �� 1-Wire
COUNTER		EQU	029h			; ������� (������������ ��� �������� ������ �� 1-Wire)
FIGX000		EQU	02Ah			; ������ ��� �������� 
FIG0X00		EQU	02Bh			; ��������
FIG00X0		EQU	02Ch			; �������-���������� ����,
FIG000X		EQU	02Dh			; ��������� �� ���������
OUTA		EQU	02Eh			; �������� ��������� ������� �����
TEMP1          	EQU   	03Ch              	;������ ��� ����������
TEMP2          	EQU     03Dh              	; �������� ������
FLAGS		EQU     03Fh		    	;����� ������������
TO_1		EQU	040h			;\
TO_2		EQU	041h			; \������
TO_3		EQU	042h
DS4_7		EQU	043h
AT1		EQU	044h
AT2		EQU	045h

AT_1		equ	.40 			;��� - ��������� �������� �� ������� � SLEEP
But		equ	0			;FLAGS,0, ������ ������ ��� ���

;				--- ���� ---
		ORG 0				;������ ������

Reset		bcf	STATUS,RP0		;��������� � ����� 0
		bcf	STATUS,RP1
		goto    Start			;������� ���������� ���������� � ������������
;--------------------------------------------------------------------------------------------------
;			--- ���������� ���������� ---
;--------------------------------------------------------------------------------------------------
		ORG 4				;������ ����������

Interrupt	movwf	W_copy			;��������� ��������
		mov	ST_copy,STATUS
		mov	FSR_copy,FSR
		call	BUTON
		movlw	B'10110000'		;����� ��� ���������� ��������� ���� 4 � 7 ****
		andwf	PORTA,F			;�����. ����, ����������� ������������ (iorwf PORTA,F ;�������� ���Ȕ)(PORTA)
						;�����
		movf	ADDRESS,W		;����� ������ � ���������� �� ������ ���� �������
		movwf	FSR			;������� � FSR (��������� ���������)
		movf	INDF,W			;��������� ������ �� ������ � ��������� ������� � W
		movwf	PORTB			;� ������ ����� PORTB �� �������� ����������
		movf	SELECTOR,W		;�������� �������
		iorwf 	PORTA,F			;������ ���������� (andwf PORTA,F ;�������� �Ȕ )
		bcf	STATUS,C		;****
		rrf	SELECTOR,F
						;����� ���������, ��������� ���� � �������� ���� (a,b)
		btfss	STATUS,C		;����� ���� ��������� � ���� �����, ���������� ������� (1)****
		goto	Int_label		;����� ��� �� ���������, ������� (2a) / nop(1b)
		movlw	FIGX000			;����� ������� ����� ������ (1b)
		movwf	ADDRESS			;� ������ ADDRESS - ������� ��������� ���� (1b)
		movlw	B'00001000'		;����� ��������� � ****     (1b)
		movwf	SELECTOR		;������ ��������� ����� (1b)
		goto	End_int			;(2b)  ���� �� b: 1b+1b+1b+1b+1b+2b = 7 �����

Int_label	incf   	ADDRESS,F             	;� ��������� ���������� ����� �������� ��������� ���� (1a)
		nop
		nop
		goto   	End_int              	 ;(2a)  ���� �� �: 2a+1a+1a+1a+2a = 7 �����

End_int		bcf	INTCON,T0IF		;���������� ���� ������� �� ���������� �� ������� TMR0
		mov	FSR,FSR_copy
		mov	STATUS,ST_copy		;��������������� ��������
		swapf	W_copy,F		;��� ���������� �������, ����� ��������� ��� Z � STATUS
		swapf	W_copy,W		;(movf ��� ����� ��������, � swapf - ���)
		retfie				;������� �� ����������� � ���������� ���� GIE

;--------------------------------------------------------------------------------------------------
;                          --- ������������ ---
;--------------------------------------------------------------------------------------------------
                ;������������ �������� ������ PORTB,0
BUTON		
		bcf	BUT
		bsf	STATUS,RP0		;��������� � ����� 1
		bsf	TRISA,0			;���� �� ����
		bcf	STATUS,RP0		;��������� � ����� 0
		btfss	BUT
		bcf	FLAGS,But
		btfsc	BUT
		bsf	FLAGS,But
		bsf	STATUS,RP0		;��������� � ����� 1
		bcf	TRISA,0			;���� �� �����
		bcf	STATUS,RP0		;��������� � ����� 0
	return 
;--------------------------------------------------------------------------------------------------
		;������������ ���������� ��� 7-����. ����������****

DC7		 clrwdt
		clrf   	PCLATH
		addwf	PCL,F		 	;��������� �����������

;                         .FADEGBC
		retlw  	B'10000100'		; 0  ;.FADEGBC ������� �����. �������-���
		retlw  	B'11111100'		; 1
		retlw  	B'11000001'		; 2
		retlw   B'11001000'		; 3
		retlw   B'10111000'		; 4
		retlw  	B'10001010'		; 5
		retlw  	B'10000010'		; 6
		retlw  	B'11011100'		; 7
		retlw  	B'10000000'		; 8
		retlw   B'10001000'		; 9
		retlw  	B'01111111'          	; �����

						;����� ������������ ���������� ��� 7-����. ����������
;--------------------------------------------------------------------------------------------------
                ;������������ ����� (������������ ������ TEMP1)

Pause            clrwdt
		 movwf	TEMP1            	;������������ ����� �������� ������ � W (�������� � ��)
		 movf   TEMP1,F          	;�������� �� 0
		 btfsc  STATUS,Z         	;���� ������������ �� ����� 0, �� Z=0 � ���������� return
		 return                     	;���� �� ������������ ����� 0, �� ����� �������

		 clrw                       	;������� W
P_label          addlw 	01h              	;���������� ���� �� W
		 jnz    P_label
                 decfsz TEMP1,F          	;������� ���� �� TEMP1
                 goto   P_label

		 clrwdt  
		 return                     	;����� ������������ �����
;--------------------------------------------------------------------------------------------------
		;������������ �������� ����������� DS18B20 (������������ ������ TEMP1)

TestDS		 movlw 	038h			;
;////////////////
		btfsc	DS4_7,0			;���� ������ ������� =0 �� ds4
		goto	DS7_0

		btfss  	ds4               	;��������� � ��������� ��������?
		goto    Test4_label		;���, ������� - �������, �������
		goto	sbros
DS7_0
		btfss  	ds7               	;��������� � ��������� ��������?
		goto   	Test4_label		;���, ������� - �������, �������		
		bcf     ds7	                ;����� 1-Wire
sbros		bcf     ds4	              	;������� ������ (�� ����� 480 ���)
		movlw  	050h
Test1_label    	addlw   01h
                btfss  	STATUS,Z              	;(�� ����� ���� ����� 3 ���� ����������
                goto    Test1_label           	; ���������� �� TMR0)

		bsf   	ds4
		bsf     ds7	                ;����� 1-Wire ��������
		movlw   D'239'
Test2_label     addlw   01h                   	;���� ������ �� DS18B20 (����� ~70 ���)
                btfss   STATUS,Z
                goto    Test2_label

		clrf    TEMP1
		movlw   D'252'
;///////////////
Test3_label      
		btfsc	DS4_7,0			;���� ������ ������� =0 �� ds4
		goto	DS7_1
		btfss   ds4               	;���� ������ (0) ?
		incf    TEMP1,F		 	;�� - ��������� TEMP1
		addlw   01h
                btfss   STATUS,Z
                goto    Test3_label

		goto  	Testend_label         	;����� Test3_label ��� DS4
DS7_1
		btfss   ds7               	;���� ������ (0) ?
		incf    TEMP1,F		 	;�� - ��������� TEMP1
		addlw   01h
                btfss   STATUS,Z
                goto    Test3_label

		goto    Testend_label         	;����� Test3_label ��� DS7
;\\\\\\\\\\\\\\
Test4_label     addlw   01h                   	;����� ��� ������������ �����
                jnz    	Test4_label
		movlw  	0

Testend_label	movlw   075h
		addlw   01h                   	;�������� ��������� ������� DS18B20
                jnz     Testend_label+1

		movlw   04h			;���� ������ DS18B20 ����������, �� TEMP1 = 4
		xorwf   TEMP1,W
		btfsc   STATUS,Z              	;TEMP1 = 4 ? 
		movlw   0FFh                  	;��  - ���������� ������� ����������� (W=0FFh)
Stop_label	return                          ;����� ������������ ��������

;--------------------------------------------------------------------------------------------------
		;������������ �����/������ �� ���� 1-Wire (��� ������ ������ W=0FFh). ������������ TEMP1
RW_1Wire	 
		movwf  	TEMP1		 	;�������� ������ � W
		movlw  	08h                   	;8 ���
		movwf  	COUNTER
RWLoop		bcf    	INTCON,GIE            	;������ ���� ����������
		bcf    	ds4                	;0 --> 1-Wire
		bcf     ds7
		btfsc  	TEMP1,0
		bsf     ds4                	;����������,���� ������� ��� TEMP1 = 1
		btfsc  	TEMP1,0
		bsf     ds7			;����������,���� ������� ��� TEMP1 = 1
		rrf    	TEMP1,F               	;����������� ��������� ���
		movlw   0FDh			;����� ~12 ���
RW_1label      	addlw   01h
		jnz     RW_1label

		bcf     TEMP1,7               	;��������� � ��� �� TEMP1
;//////////////
		btfsc	DS4_7,0			;���� ������ ������� =0 �� ds4
		goto	DS7_2

		btfsc   ds4
		goto	bsfTEMP

		goto	movlw220
DS7_2
		btfsc   ds7
bsfTEMP
		bsf     TEMP1,7
movlw220
		movlw   D'220'                	;����� �� ������������ ����� �������
RW_2label       addlw   01h
		jnz     RW_2label

		bsf     ds4                	;��������� ����
		bsf     ds7
		bsf     INTCON,GIE            	;��������� ����������
		decfsz  COUNTER,F		;8 ��� ����������?
		goto    RWLoop                	;��� ��� - �������

		movf    TEMP1,W               	;�������� ���� � W
		return				;����� ������������ �����/������ �� ���� 1-Wire
;--------------------------------------------------------------------------------------------------
		;������������ ���������� CRC. �������� � W. ������������ ������ TEMP1, TEMP2

NewCRC		clrwdt
		movwf  	TEMP2                 	;��������� W
		movlw   08h
		movwf   COUNTER               	;8 --> COUNTER
		movf    TEMP2,W               	;������������ �������� W
CRC_label	xorwf   CRCPIC,W              	;������.��� CRCPIC � W, ��������� � W
		movwf   TEMP1                 	;����������� ��������� � TEMP1
		rrf     TEMP1,W               	;����� TEMP1 ������ �� 1, ��������� � W, ������� ��� � �
		movf    CRCPIC,W              	;CRCPIC --> W (��� � �� ���������)
		btfsc   STATUS,0
		xorlw   018h                  	;���� �=0, �� ��� ���������� �� ���������
		movwf   TEMP1                 	;��������� � TEMP1
		rrf     TEMP1,W               	;����� �����, ��������� � W
		movwf   CRCPIC                	;��������� ��������� � CRCPIC
		bcf     STATUS,0              	;0 --> C
		rrf     TEMP2,F               	;����� TEMP2 ������ �� 1
		movf    TEMP2,W               	;� ����������� ���������� �������� � W
		clrwdt
		decfsz  COUNTER,F
		goto    CRC_label
 		return				;����� ������������ ���������� CRC
;--------------------------------------------------------------------------------------------------
		;������������ ����� ������ �������a AUTO ��� SAM � ������� ��������� � EEROM
		;��� ����� ds4 �� ds7
Auto_Sam
		movlw	AT_1			;����� �� ������� ������ 
		movwf	AT1			;�������� �� ������� � SLEEP
		movlw	.10			;�������� ������� �� ������������ ���������
		movwf	TO_3			;��������, ����������� ������
M_0
		mvi	FIGX000,B'01111111'	;���������� "...#"
		mvi	FIGX000,B'01111111'	; ".FADEGBC" ������� �����. �������-���
		mvi	FIGX000,B'01111111'
		mvi	FIG000X,B'01100010'
		call	Pause			;\������ ������������ ��������� ��.
		decfsz	TO_3,F			; \
		goto	M_1			;�� �������� "������ ��������" 
						;��� ����. ��������� ��. ������� AUTO<->SAM
		movlw	.3			;�������� ��������� ��� ����� 3	
		movwf	TO_3			;��� ����������� Label_Auto Sam
		btfss	DS4_7,1			;���� ������ =1 �� AUTO, ���� =0 �� SAM
		goto	Label_Auto
Label_Sam	
		bcf	DS4_7,1			;���� ������ ������ SAM
		mvi	FIGX000,B'10000111'	;���������� "CAnn"
		mvi	FIG0X00,B'10010000'	; ".FADEGBC" ������� �����. �������-���
		mvi	FIG00X0,B'11110010'
		mvi	FIG000X,B'11111010'
		goto	PP_03
Label_Auto
		bsf	DS4_7,1			;���� ������ ������ AUTO
		mvi	FIGX000,B'10010000'	;���������� "Auto"
		mvi	FIG0X00,B'11100110' 	; ".FADEGBC" ������� �����. �������-���
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'11100010'

PP_03		movlw	.250			;����� 3 ��� ����������� Label_Auto Sam
		call	Pause
		decfsz	TO_3,F
		goto	PP_03

		call	WriteEEROM
		return

M_1		btfsc	FLAGS,But		;�������� ������ =1 ��
		goto	M_0

		call	SAMds4_7		;"������ ��������" ������������� ��� DS4<->DS7
		return

;--------------------------------------------------------------------------------------------------
		;������������ ������� �� ������� � ds4 �� ds7

AUTOds4_7
		decfsz	TO_1,F			;������ �� ������� ds4 <-> ds7
		return			

		movlw	.2			;�������� ������ ��� ����� 2 ��� ����������� Label_DS
		movwf	TO_1
SAMds4_7	btfss	DS4_7,0			;���� ������ ������� =0 �� ������� �� ds7
		goto	Label_DS7

Label_DS4	bcf	DS4_7,0			;���� ������ ds4
		mvi	FIGX000,B'11111100'	;���������� "Into"
		mvi	FIG0X00,B'11110010' 	; ".FADEGBC" ������� �����. �������-���
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'11100010'
		goto	PP_02

Label_DS7	bsf	DS4_7,0			;������ ds7
		mvi	FIGX000,B'10000100'	;���������� "Outs"
		mvi	FIG0X00,B'11100110' 	; ".FADEGBC" ������� �����. �������-���
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'10001010'
PP_02		movlw	.80			;����� 2 ��� ����������� Label_DS
		call	Pause
		decfsz	TO_1,F
		goto	PP_02

		movlw	.8			;�������� ������� �� 
		movwf	TO_1			;����������� �������� DS 4<->7 ����� 1
		return

;=================================;������������ ������ � EEROM
WriteEEROM
		BCF 	INTCON,	GIE 		;���������� ���� ����������
		movf	DS4_7,w
		bsf	STATUS,RP0		;���� 1
    		MOVWF	EEDATA
		clrf	EEADR 
		BSF	EECON1,WREN		;���������� ������ � EEROM
		MOVLW	0x55	    		;��� ����� ������ ��� ������
		MOVWF	EECON2
		MOVLW	0xAA
		MOVWF	EECON2
		BSF	EECON1,WR
Zhdem		NOP		        	;�������� ����������� ������
		BTFSC	EECON1,WR
		GOTO	Zhdem
		BCF 	EECON1,WREN		;���������� ������ EEROM
		bcf	STATUS,RP0		;���� 0
		BSF	INTCON,GIE 		;������ ���� ������
		return
;=================================

;====================;������������ ������ �� EEPROM
ReadEEROM
		bsf	STATUS,RP0		;���� 1
		clrf	EEADR
		BSF 	EECON1,RD  		;������� �� ������ EEROM
		MOVF	EEDATA,w
		bcf	STATUS,RP0		;���� 0
		movwf	DS4_7
		return
;===================
;--------------------------------------------------------------------------------------------------
;__________________________________________________________________________________________________
;
;                --- ������ �������� ��������� ---
;__________________________________________________________________________________________________
Start
		movlw	.2			;�������� ������� �� 
		movwf	TO_1			;��������� ������� DS 4<->7 ����� 1
		movwf	TO_2			;�������� ������� �� ���� ��������� ���������� DS
		bsf	FLAGS,1
		call	ReadEEROM
Begin
		movlw 	7
		movwf 	CMCON			;��������� �����������
		movf	PORTA,F			;�������� � ������������
		movf	PORTB,F			;������� ������
		clrf	INTCON
		mvi	PORTA,B'10010000'	;����� ���
		mvi	PORTB,B'00000000'	;����������
		clrf	TMR0
		bsf	STATUS,RP0		;��������� � ����� 1 ��� ������� � TRIS � OPTION_REG
		bsf	PCON,OSCF		;=1 ������� -4���, =0  -32���
		mvi	TRISA,B'00100000'	;������������� ������ ����� � ��� 'OOOOOOOO' (I-in, O-out)
		clrf	TRISB			;������������� ������ ����� B ��� 'OOOOOOOO'
		mvi	OPTION_REG,B'11000111'	;���������� ������� TMR0 ����� ��������=256 � OSC
		mvi	OPTION_REG,B'11001101'	;����������� ������������ 32 � WDT, TMR0 - ������
		bcf	STATUS,RP0		;��������� � ����� 0
		mvi	ADDRESS,FIGX000		;������� � ADDRESS ����� ������ � ��������� ������
		mvi	SELECTOR,B'00001000'	;��������� � ������ ��������� ����� ****
		mvi	FIGX000,B'11111111'	;���������� "_.OFF"
		mvi	FIG0X00,B'11100010' 	;".FADEGBC" ������� �����. �������-���
		mvi	FIG00X0,B'10010011'	;F
		mvi	FIG000X,B'10010011'	;F
		mvi	INTCON,B'10100000'
		movlw	.240			
		call	Pause
		btfss	FLAGS,1			;����� ��� ���. ������� � �� ������ �� SLEEP
		call	SAMds4_7		;���������� ������ �������� ������ ������
		clrf	FLAGS
		clrwdt

;					
;	|- A -|						
;	F     B	 						
;	|- G -|	 .FADEGBC ������� �����. �������-���	
;	E     C	 ||||||||					
;	|- D -|  76543210						
;
									
;------------------------------------------------
Online_label    clrwdt		                 ;������ � ����������� DS18B20

;--------------------------------;������ �� ������� � SLEEP
ATO
		btfss	SLS			;=1 ��� ������� �� ���� ����� SLEEP	
		decfsz	AT1,F
		goto	BTC

		bcf	INTCON,GIE		;���������� ���� ����������
		movlw	AT_1			;�������� �� SLEEP
		movwf	AT1
		mvi	PORTA,B'10010000'	;����� ��, ��������� ds4 � ds7
		mvi	PORTB,B'00000000'
		bsf	STATUS,RP0		;��������� � ����� 1
		bsf	TRISA,0			;������������� ������ ����� (I-in, O-out)
		bcf	STATUS,RP0		;��������� � ����� 0
		bcf	PORTA,0			;
		bcf	INTCON,INTF		;����� �����
		bsf	INTCON,INTE		;������ ���������� INT
SLEEP
		bcf	INTCON,INTE
		bcf	INTCON,INTF
		goto	Start

BTC
		btfsc	FLAGS,But		;�������� ������������� =1 ��
		call	Auto_Sam		;����� ������ �������a � ds4 �� ds7 AUTO ��� SAM
		btfsc	DS4_7,1			;���� ������ =1 �� AUTO, ���� =0 �� SAM
		call	AUTOds4_7		;������������ AUTO �������a � ds4 �� ds7
		clrf   	TMR0
		call   	TestDS		 	;����� � �������� ����������
		xorlw   0FFh
		jnz     Begin		 	;������ - ������� �� ������ ���������
		movlw   0CCh			;������� "Skip ROM"
		call    RW_1Wire
		movlw   044h			 ;������� "Convert T"
		call    RW_1Wire
		movlw   0FFh 		 	;���� ������� ��������������
		call    Pause
		movlw   0FFh
		call    Pause
		movlw   0FFh
		call    Pause
		mvi     TRY,08h               	;8 ������� ������

Newtry_label	clrwdt                 	 	;�������� ������ ������ �� DS18B20
		clrf    TMR0
		call    TestDS		 	;����� � �������� ����������
		xorlw   0FFh
		jnz     Begin		 	;������ - ������� �� ������ ���������

		movlw   0CCh			;������� "Skip ROM"
		call    RW_1Wire
		movlw   0BEh			;������� "Read Scratchpad"
		call    RW_1Wire
		clrf    CRCPIC
		movlw   0FFh
		call    RW_1Wire
		movwf   TL                    	;������� ���� �����������
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		movwf   TH                    	;������� ���� �����������
		call    NewCRC
		movlw   0FFh                  	;����� �������� ����
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		xorwf   CRCPIC,W              	;�������� ���������� CRC
		jz      OKCRC_label           	;���������� - �������

		decfsz 	TRY,F
		goto	Newtry_label        	;������������ - ��������� �������

		goto    Begin                 	;������� ���������

OKCRC_label	clrwdt
		rrf	TH,F
		rrf	TL,F
		rrf	TH,F
		rrf	TL,F
		rrf	TH,F
		rrf	TL,F			; 64 | 32 | 16 | 8 || 4 | 2 | 1 | 0.5
		movlw	0FFh
		movwf	FIGX000		 	;����� ��� �����
		movwf	FIG0X00
		movwf	FIG00X0
		movwf	FIG000X

;------------------------------------------------
				;������� �� ���� label ��������� ���������� DS
		decfsz	TO_2,F
		goto	T100_Lb
		btfsc	DS4_7,0			;���� ������ ������� =0 �� ds4
		bcf	FIGX000,5		;����� �����. �������
		btfss	DS4_7,0			;���� ������ ������� =0 �� ds4
		bcf	FIGX000,4		;����� ����. �������
		movlw	.2			;�������� ������� 
		movwf	TO_2
;---------------
T100_Lb
		btfss	TH,0			;����������� �������������?
		goto	T100_label		;��� - ������� �� �������� "������/������ 100"
						;.FADEGBC ������� �����. �������-���
		bcf	FIGX000,2 	 	;�� - ���������� "-" � ������� �������
		comf	TL,F			;�������������� ��� �����������
		incf	TL,F			;����������� ������������� ����������
		goto	Tshow_label		;�������

;------------------------------------------------

T100_label	 bcf	STATUS,C
		 rrf	TL,W			; W = <0> | 64 | 32 | 16 || 8 | 4 | 2 | 1 
		 addlw	D'156'
		 jnc	Tshow_label		;���� ����������� ������ 100 �������� - �������

		 movlw	D'200'
		 subwf	TL,F			;� �� ����� 100 �������� - ����� ��������
		 mvi	FIG0X00,B'11111100'	;���������� "1" �� ������ �������

;------------------------------------------------

Tshow_label	 bcf	STATUS,C
		 rrf	TL,W		 	 ;W = <0> | 64 | 32 | 16 || 8 | 4 | 2 | 1
		 movwf	TEMP2
Divide		 bcf	INTCON,GIE
		 clrf	FIG00X0
		 movf   TEMP2,W		 	;����� TEMP2 �� 10 - �������� ������� � ������� ��������
		 movwf  TEMP1                 	;������� ������� TL � ����1 ����� W
		 bsf    STATUS,C              	;��������� ������� ��������
Div_label	 movf   TEMP1,W
		 movwf  FIG000X               	;������� �������� �� ���� ����� W � �������
		 incf   FIG00X0,F             	;������ ������ ����� ����������� ������� �� 1
		 movlw  D'10'                 	;10 -> W ������� �������� � W
		 subwf  TEMP1,F               	;(TEMP1 - W) -> TEMP1 � �������� ��� �� ��������
		 jc     Div_label             	;���� ����1 ��� �� ����� <0, �� �������� ����� � �.�.

		 decf  	FIG00X0,F		
		 movlw	B'11111100'
		 xorwf	FIG0X00,W		;����� ������������?
		 jnz	High_label		;��� - �������

		 movf	FIG00X0,W		;�� - ���������� ������� � ������� ��������
		 call	DC7
		 movwf	FIG00X0
		 movf	FIG000X,W		;.FADEGBC ������� �����. �������-���
		 call	DC7
		 movwf	FIG000X
		 goto	Finish_label

;------------------------------------------------
High_label	 movf	FIG00X0,W		;���������� ������� � ������� ��������
		 call	DC7
		 movwf	FIG0X00
		 movf	FIG000X,W
		 call	DC7
		 movwf	FIG00X0
		 bcf	FIG00X0,7		;���������� �����
		 mvi	FIG000X,B'10000100'	;� ������� ������� �� ��������� "0"
		 movlw	B'10001010'		;"5"
		 btfsc	TL,0
		 movwf	FIG000X		 	;� ���� ���������� ��� "0,5 �" - �� "5"

Finish_label	 bsf	INTCON,GIE
		 goto   Online_label

                 end