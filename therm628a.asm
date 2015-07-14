;__________________________________________________________________________________________________
;|-------------------------------------------------------------------------------------------------|
;| УСТРОЙСТВО: термометр с динамической индикацией                                                 |
;|-------------------------------------------------------------------------------------------------|
;| АВТОР:      picmaniac (picmaniac@rambler.ru)  FREEWARE					   |
;| ОТРЕДАКТИРОВАЛ:	Deman	(bzzzsmuv@rambler.ru)	ВЕРСИЯ: 2.4b   ДАТА: 21. 11. 2007 г.       |
;| ОТРЕДАКТИРОВАЛ под свои сегменты: Fifan (retrohobby@yandex.ru) ДАТА: 04.03.2015 г.  	           |
;|-------------------------------------------------------------------------------------------------|
;|-------------------------------------------------------------------------------------------------|
;| Работа устройства:	                                                                           |
;|	Добавлен SLEEP для работы от батареек с прерыванием по фронту на RB0 (6 вывод)             |
;|-------------------------------------------------------------------------------------------------|
;| Замечания по аппаратной части: версия для PIC16F628A, годится и для PIC16F628                   |
;|-------------------------------------------------------------------------------------------------|
;| Замечания по программе: создана в среде MPLAB 7.42 под WINDOWS XP SP1                           |
;|_________________________________________________________________________________________________|

                 LIST P=16F628A  
                 #include <P16F628A.inc>       	;Добавляем стандартный файл заголовка MPLAB
 __CONFIG 3F10
		 radix    hex

	#define	BUT	PORTA,0
	#define	ds4	PORTA,4
	#define	SLS	PORTA,5
	#define	ds7	PORTA,7

	#define autsam	flag,0	
	#define V4_7	flag,1	
;                          --- Константы  ---

;                         --- Макрокоманды ---

jnz	MACRO	metka1             		; условный переход,
	btfss	STATUS,Z           		; если не 0
	goto	metka1
	endm

jz	MACRO	metka2             		; условный переход,
	btfsc	STATUS,Z           		; если 0
	goto	metka2
	endm

jnc	MACRO	metka3             		; условный переход,
	btfss	STATUS,C	   		; если нет переноса
	goto	metka3
	endm

jc	MACRO	metka4             		; условный переход,
	btfsc	STATUS,C	   		; если перенос
	goto	metka4
	endm

mov     MACRO   DEST1,SOURCE1      		; пересылка регистр-регистр
	movf    SOURCE1,W
	movwf   DEST1
	endm

mvi     MACRO   DEST2,CONST2       		; пересылка константы в регистр
	movlw   CONST2
	movwf   DEST2
	endm

;                         --- ОПИСАНИЕ РЕГИСТРОВ ---
W_copy		EQU	020h			; В этих регистрах будет 
ST_copy		EQU	021h			; сохраняться контекст
FSR_copy	EQU	022h
ADDRESS		EQU	023h			; Хранение адреса ячейки, задающей состояние светодиодов
SELECTOR	EQU	024h			; Код выбора знакоместа (т.е зажигаемого разряда)
TH		EQU	025h			; Температура - старший байт
TL		EQU 	026h			; Температура - младший байт
CRCPIC		EQU	027h			; Контрольная сумма, подсчитанная микроконтроллером
TRY		EQU	028h			; Попытки чтения по 1-Wire
COUNTER		EQU	029h			; Счетчик (используется при передаче данных по 1-Wire)
FIGX000		EQU	02Ah			; Ячейки для хранения 
FIG0X00		EQU	02Bh			; разрядов
FIG00X0		EQU	02Ch			; двоично-десятичных цифр,
FIG000X		EQU	02Dh			; выводимых на индикатор
OUTA		EQU	02Eh			; Хранение состояний защелок порта
TEMP1          	EQU   	03Ch              	;Ячейки для врЕменного
TEMP2          	EQU     03Dh              	; хранения данных
FLAGS		EQU     03Fh		    	;Флаги пользователя
TO_1		EQU	040h			;\
TO_2		EQU	041h			; \таймер
TO_3		EQU	042h
DS4_7		EQU	043h
AT1		EQU	044h
AT2		EQU	045h

AT_1		equ	.40 			;сек - Константа Задержки на переход в SLEEP
But		equ	0			;FLAGS,0, кнопка нажата или нет

;				--- ПУСК ---
		ORG 0				;Вектор сброса

Reset		bcf	STATUS,RP0		;Обращение к банку 0
		bcf	STATUS,RP1
		goto    Start			;Обходим обработчик прерываний и подпрограммы
;--------------------------------------------------------------------------------------------------
;			--- ОБРАБОТЧИК ПРЕРЫВАНИЙ ---
;--------------------------------------------------------------------------------------------------
		ORG 4				;Вектор прерываний

Interrupt	movwf	W_copy			;Сохраняем контекст
		mov	ST_copy,STATUS
		mov	FSR_copy,FSR
		call	BUTON
		movlw	B'10110000'		;Маска для сохранения состояния бита 4 и 7 ****
		andwf	PORTA,F			;устон. биты, управляющие светодиодами (iorwf PORTA,F ;побитное “ИЛИ”)(PORTA)
						;Гасим
		movf	ADDRESS,W		;Адрес ячейки с требуемыми на данном шаге данными
		movwf	FSR			;заносим в FSR (косвенная адресация)
		movf	INDF,W			;Переносим данные из ячейки с указанным адресом в W
		movwf	PORTB			;И выдаем через PORTB на сегменты индикатора
		movf	SELECTOR,W		;Зажигаем текущий
		iorwf 	PORTA,F			;разряд индикатора (andwf PORTA,F ;побитное “И” )
		bcf	STATUS,C		;****
		rrf	SELECTOR,F
						;Далее ветвление, посчитаем шаги и уравняем пути (a,b)
		btfss	STATUS,C		;Цифра была последней в этом цикле, пропускаем переход (1)****
		goto	Int_label		;Цифра еще не последняя, переход (2a) / nop(1b)
		movlw	FIGX000			;Снова заносим адрес ячейки (1b)
		movwf	ADDRESS			;в ячейку ADDRESS - начался следующий цикл (1b)
		movlw	B'00001000'		;Снова готовимся к ****     (1b)
		movwf	SELECTOR		;выводу начальной цифры (1b)
		goto	End_int			;(2b)  Путь по b: 1b+1b+1b+1b+1b+2b = 7 шагов

Int_label	incf   	ADDRESS,F             	;В следующем прерывании будем выводить следующий байт (1a)
		nop
		nop
		goto   	End_int              	 ;(2a)  Путь по а: 2a+1a+1a+1a+2a = 7 шагов

End_int		bcf	INTCON,T0IF		;Сбрасываем флаг запроса на прерывание от таймера TMR0
		mov	FSR,FSR_copy
		mov	STATUS,ST_copy		;Восстанавливаем контекст
		swapf	W_copy,F		;Тут приходится хитрить, чтобы сохранить бит Z в STATUS
		swapf	W_copy,W		;(movf его может изменить, а swapf - нет)
		retfie				;Возврат из обработчика с установкой бита GIE

;--------------------------------------------------------------------------------------------------
;                          --- ПОДПРОГРАММЫ ---
;--------------------------------------------------------------------------------------------------
                ;Подпрограмма проверки кнопки PORTB,0
BUTON		
		bcf	BUT
		bsf	STATUS,RP0		;Обращение к банку 1
		bsf	TRISA,0			;Порт на Вход
		bcf	STATUS,RP0		;Обращение к банку 0
		btfss	BUT
		bcf	FLAGS,But
		btfsc	BUT
		bsf	FLAGS,But
		bsf	STATUS,RP0		;Обращение к банку 1
		bcf	TRISA,0			;Порт на Выход
		bcf	STATUS,RP0		;Обращение к банку 0
	return 
;--------------------------------------------------------------------------------------------------
		;Подпрограмма дешифрации для 7-сегм. индикатора****

DC7		 clrwdt
		clrf   	PCLATH
		addwf	PCL,F		 	;Табличная конвертация

;                         .FADEGBC
		retlw  	B'10000100'		; 0  ;.FADEGBC порядок соотв. сегмент-бит
		retlw  	B'11111100'		; 1
		retlw  	B'11000001'		; 2
		retlw   B'11001000'		; 3
		retlw   B'10111000'		; 4
		retlw  	B'10001010'		; 5
		retlw  	B'10000010'		; 6
		retlw  	B'11011100'		; 7
		retlw  	B'10000000'		; 8
		retlw   B'10001000'		; 9
		retlw  	B'01111111'          	; точка

						;Конец подпрограммы дешифрации для 7-сегм. индикатора
;--------------------------------------------------------------------------------------------------
                ;Подпрограмма паузы (используется ячейка TEMP1)

Pause            clrwdt
		 movwf	TEMP1            	;Длительность паузы задается числом в W (примерно в мс)
		 movf   TEMP1,F          	;Проверка на 0
		 btfsc  STATUS,Z         	;Если длительность не равна 0, то Z=0 и пропускаем return
		 return                     	;Если же длительность равна 0, то сразу возврат

		 clrw                       	;Очищаем W
P_label          addlw 	01h              	;Внутренний цикл по W
		 jnz    P_label
                 decfsz TEMP1,F          	;Внешний цикл по TEMP1
                 goto   P_label

		 clrwdt  
		 return                     	;Конец подпрограммы паузы
;--------------------------------------------------------------------------------------------------
		;Подпрограмма проверки подключения DS18B20 (Используется ячейка TEMP1)

TestDS		 movlw 	038h			;
;////////////////
		btfsc	DS4_7,0			;флаг выбора датчика =0 то ds4
		goto	DS7_0

		btfss  	ds4               	;Термометр в состоянии ожидания?
		goto    Test4_label		;Нет, активен - переход, выходим
		goto	sbros
DS7_0
		btfss  	ds7               	;Термометр в состоянии ожидания?
		goto   	Test4_label		;Нет, активен - переход, выходим		
		bcf     ds7	                ;Сброс 1-Wire
sbros		bcf     ds4	              	;Импульс сброса (не менее 480 мкс)
		movlw  	050h
Test1_label    	addlw   01h
                btfss  	STATUS,Z              	;(за время этой паузы 3 раза происходит
                goto    Test1_label           	; прерывание от TMR0)

		bsf   	ds4
		bsf     ds7	                ;Сброс 1-Wire выполнен
		movlw   D'239'
Test2_label     addlw   01h                   	;Ждем ответа от DS18B20 (пауза ~70 мкс)
                btfss   STATUS,Z
                goto    Test2_label

		clrf    TEMP1
		movlw   D'252'
;///////////////
Test3_label      
		btfsc	DS4_7,0			;флаг выбора датчика =0 то ds4
		goto	DS7_1
		btfss   ds4               	;Есть отклик (0) ?
		incf    TEMP1,F		 	;Да - инкремент TEMP1
		addlw   01h
                btfss   STATUS,Z
                goto    Test3_label

		goto  	Testend_label         	;конец Test3_label для DS4
DS7_1
		btfss   ds7               	;Есть отклик (0) ?
		incf    TEMP1,F		 	;Да - инкремент TEMP1
		addlw   01h
                btfss   STATUS,Z
                goto    Test3_label

		goto    Testend_label         	;конец Test3_label для DS7
;\\\\\\\\\\\\\\
Test4_label     addlw   01h                   	;Пауза для выравнивания путей
                jnz    	Test4_label
		movlw  	0

Testend_label	movlw   075h
		addlw   01h                   	;Ожидание окончания отклика DS18B20
                jnz     Testend_label+1

		movlw   04h			;Если отклик DS18B20 правильный, то TEMP1 = 4
		xorwf   TEMP1,W
		btfsc   STATUS,Z              	;TEMP1 = 4 ? 
		movlw   0FFh                  	;Да  - установить признак присутствия (W=0FFh)
Stop_label	return                          ;Конец подпрограммы проверки

;--------------------------------------------------------------------------------------------------
		;Подпрограмма ввода/вывода по шине 1-Wire (для приема задаем W=0FFh). Используется TEMP1
RW_1Wire	 
		movwf  	TEMP1		 	;Исходные данные в W
		movlw  	08h                   	;8 бит
		movwf  	COUNTER
RWLoop		bcf    	INTCON,GIE            	;Запрет всех прерываний
		bcf    	ds4                	;0 --> 1-Wire
		bcf     ds7
		btfsc  	TEMP1,0
		bsf     ds4                	;Установить,если младший бит TEMP1 = 1
		btfsc  	TEMP1,0
		bsf     ds7			;Установить,если младший бит TEMP1 = 1
		rrf    	TEMP1,F               	;Подготовить следующий бит
		movlw   0FDh			;Пауза ~12 мкс
RW_1label      	addlw   01h
		jnz     RW_1label

		bcf     TEMP1,7               	;Принимаем в тот же TEMP1
;//////////////
		btfsc	DS4_7,0			;флаг выбора датчика =0 то ds4
		goto	DS7_2

		btfsc   ds4
		goto	bsfTEMP

		goto	movlw220
DS7_2
		btfsc   ds7
bsfTEMP
		bsf     TEMP1,7
movlw220
		movlw   D'220'                	;Время на освобождение линии ведомым
RW_2label       addlw   01h
		jnz     RW_2label

		bsf     ds4                	;Отпускаем шину
		bsf     ds7
		bsf     INTCON,GIE            	;Разрешить прерывания
		decfsz  COUNTER,F		;8 бит обработаны?
		goto    RWLoop                	;Еще нет - переход

		movf    TEMP1,W               	;Принятый байт в W
		return				;Конец подпрограммы ввода/вывода по шине 1-Wire
;--------------------------------------------------------------------------------------------------
		;Подпрограмма обновления CRC. Параметр в W. Используются ячейки TEMP1, TEMP2

NewCRC		clrwdt
		movwf  	TEMP2                 	;Сохранить W
		movlw   08h
		movwf   COUNTER               	;8 --> COUNTER
		movf    TEMP2,W               	;Восстановить значение W
CRC_label	xorwf   CRCPIC,W              	;Исключ.ИЛИ CRCPIC и W, результат в W
		movwf   TEMP1                 	;Скопировать результат в TEMP1
		rrf     TEMP1,W               	;Сдвиг TEMP1 вправо на 1, результат в W, младший бит в С
		movf    CRCPIC,W              	;CRCPIC --> W (бит С не изменился)
		btfsc   STATUS,0
		xorlw   018h                  	;Если С=0, то эту инструкцию не выполнять
		movwf   TEMP1                 	;Результат в TEMP1
		rrf     TEMP1,W               	;Снова сдвиг, результат в W
		movwf   CRCPIC                	;Сохранить результат в CRCPIC
		bcf     STATUS,0              	;0 --> C
		rrf     TEMP2,F               	;Сдвиг TEMP2 вправо на 1
		movf    TEMP2,W               	;И скопировать полученное значение в W
		clrwdt
		decfsz  COUNTER,F
		goto    CRC_label
 		return				;Конец подпрограммы обновления CRC
;--------------------------------------------------------------------------------------------------
		;Подпрограмма Выбор режима переходa AUTO или SAM с записью состояния в EEROM
		;или перех ds4 на ds7
Auto_Sam
		movlw	AT_1			;Сброс по нажатию кнопки 
		movwf	AT1			;задержки на переход в SLEEP
		movlw	.10			;Загрузка таймера на длительность удержания
		movwf	TO_3			;кнопкина, отображение кнопки
M_0
		mvi	FIGX000,B'01111111'	;Отображаем "...#"
		mvi	FIGX000,B'01111111'	; ".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIGX000,B'01111111'
		mvi	FIG000X,B'01100010'
		call	Pause			;\таймер длительности удержания кн.
		decfsz	TO_3,F			; \
		goto	M_1			;на проверку "кнопка отпущена" 
						;При длит. удержании кн. переход AUTO<->SAM
		movlw	.3			;Загрузка множителя для Паузы 3	
		movwf	TO_3			;для отображения Label_Auto Sam
		btfss	DS4_7,1			;Флаг выбора =1 то AUTO, если =0 то SAM
		goto	Label_Auto
Label_Sam	
		bcf	DS4_7,1			;флаг выбора режима SAM
		mvi	FIGX000,B'10000111'	;Отображаем "CAnn"
		mvi	FIG0X00,B'10010000'	; ".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIG00X0,B'11110010'
		mvi	FIG000X,B'11111010'
		goto	PP_03
Label_Auto
		bsf	DS4_7,1			;флаг выбора режима AUTO
		mvi	FIGX000,B'10010000'	;Отображаем "Auto"
		mvi	FIG0X00,B'11100110' 	; ".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'11100010'

PP_03		movlw	.250			;Пауза 3 для отображения Label_Auto Sam
		call	Pause
		decfsz	TO_3,F
		goto	PP_03

		call	WriteEEROM
		return

M_1		btfsc	FLAGS,But		;проверка кнопки =1 да
		goto	M_0

		call	SAMds4_7		;"кнопка отпущена" инвертировать бит DS4<->DS7
		return

;--------------------------------------------------------------------------------------------------
		;Подпрограмма таймера на переход с ds4 на ds7

AUTOds4_7
		decfsz	TO_1,F			;таймер на переход ds4 <-> ds7
		return			

		movlw	.2			;загрузка множит для Пауза 2 для отображения Label_DS
		movwf	TO_1
SAMds4_7	btfss	DS4_7,0			;флаг выбора датчика =0 то переход на ds7
		goto	Label_DS7

Label_DS4	bcf	DS4_7,0			;флаг выбора ds4
		mvi	FIGX000,B'11111100'	;Отображаем "Into"
		mvi	FIG0X00,B'11110010' 	; ".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'11100010'
		goto	PP_02

Label_DS7	bsf	DS4_7,0			;выбора ds7
		mvi	FIGX000,B'10000100'	;Отображаем "Outs"
		mvi	FIG0X00,B'11100110' 	; ".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIG00X0,B'10100011'
		mvi	FIG000X,B'10001010'
PP_02		movlw	.80			;Пауза 2 для отображения Label_DS
		call	Pause
		decfsz	TO_1,F
		goto	PP_02

		movlw	.8			;загрузка таймера на 
		movwf	TO_1			;последующие переходы DS 4<->7 Пауза 1
		return

;=================================;Подпрограмма записи в EEROM
WriteEEROM
		BCF 	INTCON,	GIE 		;Запрещение всех прерываний
		movf	DS4_7,w
		bsf	STATUS,RP0		;Банк 1
    		MOVWF	EEDATA
		clrf	EEADR 
		BSF	EECON1,WREN		;Разрешение записи в EEROM
		MOVLW	0x55	    		;Даём набор команд для записи
		MOVWF	EECON2
		MOVLW	0xAA
		MOVWF	EECON2
		BSF	EECON1,WR
Zhdem		NOP		        	;Ожидание заверешения записи
		BTFSC	EECON1,WR
		GOTO	Zhdem
		BCF 	EECON1,WREN		;Запрещение записи EEROM
		bcf	STATUS,RP0		;Банк 0
		BSF	INTCON,GIE 		;Разреш всех прерыв
		return
;=================================

;====================;Подпрограмма чтения из EEPROM
ReadEEROM
		bsf	STATUS,RP0		;Банк 1
		clrf	EEADR
		BSF 	EECON1,RD  		;Команда на чтение EEROM
		MOVF	EEDATA,w
		bcf	STATUS,RP0		;Банк 0
		movwf	DS4_7
		return
;===================
;--------------------------------------------------------------------------------------------------
;__________________________________________________________________________________________________
;
;                --- НАЧАЛО ОСНОВНОЙ ПРОГРАММЫ ---
;__________________________________________________________________________________________________
Start
		movlw	.2			;Загрузка таймера на 
		movwf	TO_1			;первичный переход DS 4<->7 Пауза 1
		movwf	TO_2			;Загрузка таймера на мояк индикацию выбронного DS
		bsf	FLAGS,1
		call	ReadEEROM
Begin
		movlw 	7
		movwf 	CMCON			;Отключаем компараторы
		movf	PORTA,F			;Приводим в соответствие
		movf	PORTB,F			;защелки портов
		clrf	INTCON
		mvi	PORTA,B'10010000'	;Гасим все
		mvi	PORTB,B'00000000'	;светодиоды
		clrf	TMR0
		bsf	STATUS,RP0		;Обращение к банку 1 для доступа к TRIS и OPTION_REG
		bsf	PCON,OSCF		;=1 частота -4Мгц, =0  -32кгц
		mvi	TRISA,B'00100000'	;Устанавливаем выводы порта А как 'OOOOOOOO' (I-in, O-out)
		clrf	TRISB			;Устанавливаем выводы порта B как 'OOOOOOOO'
		mvi	OPTION_REG,B'11000111'	;Подключаем сначала TMR0 через делитель=256 к OSC
		mvi	OPTION_REG,B'11001101'	;Переключаем предделитель 32 к WDT, TMR0 - таймер
		bcf	STATUS,RP0		;Обращение к банку 0
		mvi	ADDRESS,FIGX000		;Заносим в ADDRESS адрес ячейки с начальной цифрой
		mvi	SELECTOR,B'00001000'	;Готовимся к выводу начальной цифры ****
		mvi	FIGX000,B'11111111'	;Отображаем "_.OFF"
		mvi	FIG0X00,B'11100010' 	;".FADEGBC" порядок соотв. сегмент-бит
		mvi	FIG00X0,B'10010011'	;F
		mvi	FIG000X,B'10010011'	;F
		mvi	INTCON,B'10100000'
		movlw	.240			
		call	Pause
		btfss	FLAGS,1			;Обход при вкл. питания и по выходу из SLEEP
		call	SAMds4_7		;отсутствие одного выбираем другой датчик
		clrf	FLAGS
		clrwdt

;					
;	|- A -|						
;	F     B	 						
;	|- G -|	 .FADEGBC порядок соотв. сегмент-бит	
;	E     C	 ||||||||					
;	|- D -|  76543210						
;
									
;------------------------------------------------
Online_label    clrwdt		                 ;Работа с термометром DS18B20

;--------------------------------;Таймер на переход в SLEEP
ATO
		btfss	SLS			;=1 При питании от сети обход SLEEP	
		decfsz	AT1,F
		goto	BTC

		bcf	INTCON,GIE		;Глобальное запр прерываний
		movlw	AT_1			;Задержка на SLEEP
		movwf	AT1
		mvi	PORTA,B'10010000'	;Гасим всё, Подпираем ds4 и ds7
		mvi	PORTB,B'00000000'
		bsf	STATUS,RP0		;Обращение к банку 1
		bsf	TRISA,0			;Устанавливаем выводы порта (I-in, O-out)
		bcf	STATUS,RP0		;Обращение к банку 0
		bcf	PORTA,0			;
		bcf	INTCON,INTF		;Сброс флага
		bsf	INTCON,INTE		;Разреш прерывания INT
SLEEP
		bcf	INTCON,INTE
		bcf	INTCON,INTF
		goto	Start

BTC
		btfsc	FLAGS,But		;проверка кнопкифдрюкен =1 да
		call	Auto_Sam		;Выбор режима переходa с ds4 на ds7 AUTO или SAM
		btfsc	DS4_7,1			;флаг выбора =1 то AUTO, если =0 то SAM
		call	AUTOds4_7		;Подпрограмма AUTO переходa с ds4 на ds7
		clrf   	TMR0
		call   	TestDS		 	;Сброс и проверка термометра
		xorlw   0FFh
		jnz     Begin		 	;Ошибка - переход на начало программы
		movlw   0CCh			;Команда "Skip ROM"
		call    RW_1Wire
		movlw   044h			 ;Команда "Convert T"
		call    RW_1Wire
		movlw   0FFh 		 	;Идет процесс преобразования
		call    Pause
		movlw   0FFh
		call    Pause
		movlw   0FFh
		call    Pause
		mvi     TRY,08h               	;8 попыток чтения

Newtry_label	clrwdt                 	 	;Начинаем чтение данных из DS18B20
		clrf    TMR0
		call    TestDS		 	;Сброс и проверка термометра
		xorlw   0FFh
		jnz     Begin		 	;Ошибка - переход на начало программы

		movlw   0CCh			;Команда "Skip ROM"
		call    RW_1Wire
		movlw   0BEh			;Команда "Read Scratchpad"
		call    RW_1Wire
		clrf    CRCPIC
		movlw   0FFh
		call    RW_1Wire
		movwf   TL                    	;Младший байт температуры
		call    NewCRC
		movlw   0FFh
		call    RW_1Wire
		movwf   TH                    	;Старший байт температуры
		call    NewCRC
		movlw   0FFh                  	;Шесть ненужных байт
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
		xorwf   CRCPIC,W              	;Проверка совпадения CRC
		jz      OKCRC_label           	;Совпадение - переход

		decfsz 	TRY,F
		goto	Newtry_label        	;Несовпадение - следующая попытка

		goto    Begin                 	;Попытки исчерпаны

OKCRC_label	clrwdt
		rrf	TH,F
		rrf	TL,F
		rrf	TH,F
		rrf	TL,F
		rrf	TH,F
		rrf	TL,F			; 64 | 32 | 16 | 8 || 4 | 2 | 1 | 0.5
		movlw	0FFh
		movwf	FIGX000		 	;Гасим все цифры
		movwf	FIG0X00
		movwf	FIG00X0
		movwf	FIG000X

;------------------------------------------------
				;Таймера на мояк label индикацию выбронного DS
		decfsz	TO_2,F
		goto	T100_Lb
		btfsc	DS4_7,0			;флаг выбора датчика =0 то ds4
		bcf	FIGX000,5		;зажеч верхн. сегмент
		btfss	DS4_7,0			;флаг выбора датчика =0 то ds4
		bcf	FIGX000,4		;зажеч нижн. сегмент
		movlw	.2			;Загрузка таймера 
		movwf	TO_2
;---------------
T100_Lb
		btfss	TH,0			;Температура отрицательная?
		goto	T100_label		;Нет - переход на проверку "больше/меньше 100"
						;.FADEGBC порядок соотв. сегмент-бит
		bcf	FIGX000,2 	 	;Да - отображаем "-" в старшем разряде
		comf	TL,F			;Преобразование для правильного
		incf	TL,F			;отображения отрицательных температур
		goto	Tshow_label		;Переход

;------------------------------------------------

T100_label	 bcf	STATUS,C
		 rrf	TL,W			; W = <0> | 64 | 32 | 16 || 8 | 4 | 2 | 1 
		 addlw	D'156'
		 jnc	Tshow_label		;Если температура меньше 100 градусов - переход

		 movlw	D'200'
		 subwf	TL,F			;Т не менее 100 градусов - сотню вычитаем
		 mvi	FIG0X00,B'11111100'	;Отобразить "1" во втором разряде

;------------------------------------------------

Tshow_label	 bcf	STATUS,C
		 rrf	TL,W		 	 ;W = <0> | 64 | 32 | 16 || 8 | 4 | 2 | 1
		 movwf	TEMP2
Divide		 bcf	INTCON,GIE
		 clrf	FIG00X0
		 movf   TEMP2,W		 	;Делим TEMP2 на 10 - получаем десятки и единицы градусов
		 movwf  TEMP1                 	;Заносим делимое TL в ТЕМР1 через W
		 bsf    STATUS,C              	;Установим признак переноса
Div_label	 movf   TEMP1,W
		 movwf  FIG000X               	;Заносим значение из ТЕМР через W в остаток
		 incf   FIG00X0,F             	;Каждый проход цикла увеличивает частное на 1
		 movlw  D'10'                 	;10 -> W заносим делитель в W
		 subwf  TEMP1,F               	;(TEMP1 - W) -> TEMP1 и вычитаем его из делимого
		 jc     Div_label             	;Если ТЕМР1 еще не стало <0, то вычитаем снова и т.д.

		 decf  	FIG00X0,F		
		 movlw	B'11111100'
		 xorwf	FIG0X00,W		;Сотня отображается?
		 jnz	High_label		;Нет - переход

		 movf	FIG00X0,W		;Да - отображаем десятки и единицы градусов
		 call	DC7
		 movwf	FIG00X0
		 movf	FIG000X,W		;.FADEGBC порядок соотв. сегмент-бит
		 call	DC7
		 movwf	FIG000X
		 goto	Finish_label

;------------------------------------------------
High_label	 movf	FIG00X0,W		;Отображаем десятки и единицы градусов
		 call	DC7
		 movwf	FIG0X00
		 movf	FIG000X,W
		 call	DC7
		 movwf	FIG00X0
		 bcf	FIG00X0,7		;Отображаем точку
		 mvi	FIG000X,B'10000100'	;В младшем разряде по умолчанию "0"
		 movlw	B'10001010'		;"5"
		 btfsc	TL,0
		 movwf	FIG000X		 	;А если установлен бит "0,5 С" - то "5"

Finish_label	 bsf	INTCON,GIE
		 goto   Online_label

                 end