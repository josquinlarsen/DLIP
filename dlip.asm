TITLE Designing Low-Level I/0 Procedures     (dlip.asm)

; Author: Josquin Larsen
; Date: 10/dec/2023
; Description: Project 6 - Designing Low-Level I/O Procedures (DLIP) - DLIP prompts the user for 10 signed (+/-) integers; validates
;							that the user input is indeed a signed integer that can fit within an SDWORD [-2147483648d, 2147483647d]
;							then displays array of user's valid input; calculates and displays the sum of the valid input; 
;							and finally calculates and displays the truncated average of the value (e.g. 3.33 = 3). DLIP invokes macros
;							to receive (and display) input and to display all strings. Procedures are used to convert strings (ASCII) 
;							to integers; perform calculations; and reconvert integers to strings for display to the console. 
;							

INCLUDE Irvine32.inc

; ----- *<*>* -----
; mGetString
;
;		Macro which takes four parameters - prompt, user_num, input_size, and count_byte. Prompts user for a signed (+/-) integer, 
;		stores user input, and number of bytes.
;		 
; preconditions: Saves EAX, ECX, EDX registers. 
; postconditions: Restores EAX, ECX, EDX registers 
;					
; receives: EDX: prompt_1 (string); ECX: input_size - constant MAX_CHAR(12) + 1; EAX - stores byte count
;
; returns: Displays prompt_1, reads user input into EDX, stores byte count in EAX			
; ----- *<*>* -----

mGetString MACRO	prompt, user_num, input_size, count_byte
	push	EDX								; save registers
	push	ECX
	push	EAX

	mov		EDX, prompt
	call	WriteString

	xor		EDX, EDX						
	mov		EDX, user_num					; user_input 
	mov		ECX, input_size					; MAX_CHAR (12) + 1
	call	ReadString
	mov		count_byte, EAX					; number of bytes for length of string

	pop		EAX								; restore registers
	pop		ECX
	pop		EDX

ENDM
; ----- *<*>* -----
; mDisplayString
;
;		Macro which takes a string and displays it on the console
;
; preconditions: Saves EDX
; postconditions: Restores EDX 
;					
; receives: String
; returns: Displays string on console			
; ----- *<*>* -----
mDisplayString MACRO display_text
	
	push	EDX								; save register

	mov		EDX, display_text
	call	WriteString

	pop		EDX								; restore register 

ENDM

;constants
				
MAX_NUM			=		+2147483647			; SDWORD max postive number
MIN_NUM			=		-2147483648			; SDWORD max negative number 
MAX_CHAR		=		12					; max number of characters in SDWORD: sign, 10 digits, null terminator 
ARRAYSIZE		=		10					; user inputs 10 valid integers

.data

		intro_1			BYTE	"Designing Low-Level I/O Procedures (DLIP) by Josquin Larsen",13,10, 0
		intro_2			BYTE	"User inputs 10 signed decimal integers.",0
		intro_2a		BYTE	"Integers must be small enough to fit inside a 32-bit register.",0
		intro_2b		BYTE	"Once 10 valid integers are received, DLIP will display a list of valid integers, their sum, and their average value.",13,10,0
			
		error_1			BYTE	"ERROR! Invalid input (your number is too big, unsigned, or lacking digits)", 0

		header_1		BYTE	"You entered the following numbers: ",13,10,0
		header_2		BYTE	"The sum of these numbers is: ",0
		header_3		BYTE	"The truncated average is: ", 0

		goodbye			BYTE	"Until we meet again. Goodbye!",0

		prompt_1		BYTE	"Please enter a signed number: ",0

		user_input		BYTE	MAX_CHAR DUP(?)		;input buffer
		out_str			BYTE	MAX_CHAR DUP(?)		; store converted ascii string
		temp_str		BYTE	MAX_CHAR DUP(?)		; store converted ascii string

		comma			BYTE	", ", 0
		last_num		SDWORD	1 
		
		byte_count		DWORD	?					; number of bytes input by user
		valid_nums		SDWORD	10 DUP(?)			; array to place valid input 
		num_int			SDWORD	?					; numint = 0 from ascii conversion algorithm

		array_sum		SDWORD	?					; array to store sum
								
.code
; ----- * -----
; Main 
;
;		Calls procedures and manages loops to store and read value to/from valid_nums (array)
;
; preconditions: Macros defined; constants defined; variables defined in data segment
; postconditions: none 
;					
; receives: Variables and their offsets (when needed); constant (MAX_CHAR); constant integers:
;			10 (keep track of 10 valid numbers), 4 (to increment ESI); EDI (valid_nums) for ReadVal,
;			ESI (valid_nums) for WriteVal, ECX (10), EAX (for incrementing valid_nums) section headers
;			(invoked by mDisplayString) before procedure calls
;
; returns: Displays headers to console 			
; ----- * -----
main PROC

	push	OFFSET intro_2b					;INTRODUCTION
	push	OFFSET intro_2a
	push	OFFSET intro_2
	push	OFFSET intro_1
	call	Introduction

	mov		EDI, OFFSET valid_nums			;READVAL Loop
	mov		ECX, ARRAYSIZE					; user provides 10 valid integers

_valid_input:
	push	ECX								; save ECX counter

	push	OFFSET num_int			
	push	OFFSET error_1			
	push	OFFSET prompt_1			
	push	OFFSET user_input			
	push	MAX_CHAR + 1					; accommodate too big of signed integers (error check)
	push	OFFSET byte_count		
	call	ReadVal

	mov		[EDI], EAX
	add		EDI, 4

	pop		ECX								; restore ECX counter
	loop	_valid_input
	call	CrLf

	mov		ECX, ARRAYSIZE					; WRITEVAL loop (10 integers)
	mov		EDX, last_num
	mov		ESI, OFFSET valid_nums
	mDisplayString	OFFSET header_1

_write_valid_nums:

	push	ARRAYSIZE
	push	last_num			
	push	OFFSET comma		
	push	OFFSET out_str		
	call	WriteVal

	add		ESI, 4
	
	inc		last_num
	loop	_write_valid_nums
	call	CrLf
	call	CrLf
	
	mDisplayString OFFSET header_2			; ARRAYSUM 

	push	OFFSET out_str		
	push	array_sum			
	push	OFFSET valid_nums   
	call	ArraySum
	call	CrLf
	call	CrLf

	mDisplayString OFFSET header_3			;ARRAYAVG 

	push	ARRAYSIZE
	push	OFFSET temp_str		
	push	array_sum			
	push	OFFSET valid_nums	
	call	ArrayAvg
	call	CrLf
	call	CrLf

	push	OFFSET goodbye					;FAREWELL
	call	Farewell
	

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ----- * -----
; Introduction
;
;		Displays title and funcionality of DLIP by invoking macro mDisplayString
;
; preconditions: Preserve EBP register; intro strings stored in data segment 
; postconditions: Restores EBP
;					
; receives: Variables (all strings): intro_1, intro_2, intro_2a, intro_2b. 
;
;				[EBP +8]	= intro_1
;				[EBP + 12]	= intro_2
;				[EBP + 16]	= intro_2a
;				[EBP + 20]	= intro_2b
;
; returns: Displays the above strings to console 			
; ----- * -----

Introduction PROC
	push	EBP						; preserve EBP 
	mov		EBP, ESP

	mDisplayString [EBP + 8]		; intro_1
	call	CrLF

	mDisplayString [EBP + 12]		; intro_2
	call	CrLf

	mDisplayString [EBP + 16]		; intro_2a
	call	CrLf

	mDisplayString [EBP + 20]		; intro_2b
	call	CrLf

	pop		EBP

	RET 16
Introduction ENDP

; ----- * -----
; ReadVal
;		
;		Gets user input (string) by invoking macro mGetString. Converts the string to integer and validates that the user 
;		input is indeed a signed integer that can fit within an SDWORD. If the number entered is invalid, an error message 
;		is displayed. If valid, the integer is stored in the array valid_nums. Uses the stack to process bytes for conversion
;
;
; preconditions: Preserve EBP; clear out EAX, EBX, ECX, EDX registers; valid_nums array defined in data segment and ready to
;				receive validated input. 

; postconditions: EBP restored; stack rebalanced
;					
; receives: Constant: MAX_CHAR + 1; Variables: prompt_1, error_1, user_input (ESI), byte_count, num_int, valid_nums. 
;			EAX, EBX, ECX, EDX, ESI, EDI; integer constants: 10 (multiplication/counter), 0 (negative number check); 
;			ASCII 43 ('+'), 45 ('-'), 48 ('0'), 57 ('9') 
;
;					[EBP + 8] = byte_count
;					[EBP + 12] = MAX_SIZE + 1
;					[EBP + 16] = user_input
;					[EBP + 20] = prompt_1
;					[EBP + 24] = error_1
;					[EBP + 28] = num_int (for algorithm to convert string to interger)
;
; returns: error_1 message (if input is invalid); validated user input stored in EAX
; ----- * -----

ReadVal PROC
	push	EBP													;save EBP
	mov		EBP, ESP
														
_validate_loop:													; valid input = 1 char for sign + / - ; 10 char of digits ; 1 null terminator = 12 characters

	xor		EAX, EAX											; clear registers
	xor		EBX, EBX
	xor		ECX, ECX
	xor		EDX, EDX

	mov		[EBP + 28], EAX										;initialize num_int = 0 for ascii conversion

	mGetString [EBP + 20], [EBP + 16], [EBP + 12], [EBP + 8]	;prompt_1, user_input, MAXSIZE (12) + 1, byte_count
	call	CrLf
	
	;sign check
	mov		ECX, [EBP + 8]										; length of string as counter
	mov		ESI, [EBP + 16]										; move user input into ESI

	cld
	lodsb	
	cmp		AL, 45												; ASCII 45 = '-'
	je		_negative_num
	cmp		AL, 43												; ASCII 43 = '+'
	je		_positive_num
	jmp		_no_pos_sign

; negative number conversion
_negative_num:
	dec		ECX													; account for sign

	_negative_int:
		xor		EAX, EAX										; ASCII conversion algo
		lodsb
	
		cmp		AL, 48											; ASCII 48 = 0d
		jl		_error
		cmp		AL, 57											; ASCII 57 = 9d
		jg		_error

		push	ECX
		sub		EAX, 48											; sub ASCII 48 from number to get integer
		neg		EAX												; negate each byte to fit SDWORD negative bound
		push	EAX												; push result to stack									
		mov		EAX, [EBP + 28]									; num_int 
		mov		EBX, 10
		imul	EBX
		pop		ECX												; pop integer to ECX 
		jo		_big_error
		add		EAX, ECX
		jo		_big_error
		mov		[EBP + 28], EAX									; store new num_int
		jo		_big_error
		pop		ECX												; restore ECX counter
		loop	_negative_int

		jo		_error
		mov		[EBP + 28], EAX

	jmp	_exit

; positive number conversion 
_positive_num:	
	dec		ECX													; account for sign
	
	_positive_int:
		xor		EAX, EAX										; ASCII conversion algorithm
		lodsb
	
			_no_pos_sign:		
				cmp		AL, 48									; ASCII 48 = 0d
				jl		_error
				cmp		AL, 57									; ASCII 57 = 9d
				jg		_error

				push	ECX
				sub		EAX, 48				 
				push	EAX										; result to stack
				mov		EAX, [EBP + 28]							; num_int 
				mov		EBX, 10
				imul	EBX
				pop		ECX									
				jo		_big_error
				add		EAX, ECX								; add value from stack	
				jo		_big_error
				mov		[EBP + 28], EAX							; store new num_int
				pop		ECX				
				loop	_positive_int
				
			jmp _exit

_big_error:
	pop		ECX													; rebalance stack

_error: 
	mDisplayString	[EBP + 24]									;error message
	call	CrLf
	jmp		_validate_loop
		
_exit:
	pop		EBP

	RET	24

ReadVal ENDP

; ----- * -----
; WriteVal
;			
;		Takes an integer and converts it to a string for display on the console by invoking mDisplayString. 
;		Displays error message if integer is invalid input. Byte conversion happens via the stack
;
; preconditions: EBP preserved; All registers preserved (pushad) then cleared; 10 valid integers stored in valid_nums array
;				(established in main procedure); out_str variable defined in data segment; valid_nums data loaded in ESI in main
;				procedure via loop. 
;
; postconditions: Registers restored; EBP restored
;					
; receives: Constant: ARRAYSIZE(10) to check for last number; Variables: valid_nums (passed in ESI), out_str, comma (for display
;			formatting), last_num (counter for display of last integer); EAX, EBX, ECX, EDX, EDI, ESI; integer
;			constants: 12 (clear out string), 10 (division), 4 (to move through array), 0 (negative number check);
;			ASCII 45 ('-'), 48 ('0')
;
;					[EBP + 8] = out_str
;					[EBP + 12] = comma
;					[EBP + 16] = last_num
;					[EBP + 20] = ARRAYSIZE 
;
; returns: Displays valid_nums array as strings to console, separated by a comma and space (except the last number); out_str is cleared out
;			for next valid_num index. Registers restored (popad) to increment ESI in main procedure
; ----- * -----

WriteVal PROC
	push	EBP
	mov		EBP, ESP

	pushad

	xor		EAX, EAX				; clear registers
	xor		EBX, EBX
	xor		ECX, ECX
	xor		EDX, EDX

	mov		EDI, [EBP + 8]			; out_str

	mov		EAX, [ESI]				; move valid_num array value 

	cmp		EAX, 0
	js		_convert_negative

_convert_positive:					; positive interger to ASCII conversion algorightm
	xor		EDX, EDX
	mov		EBX, 10					; dividing by 10 to find place value (100, 10, 1 etc)
	cdq
	idiv	EBX
	push	DX						; push character to stack
	inc		ECX
	cmp		EAX, 0
	jne		_convert_positive

	cld
	jmp		_display_string

					
	_convert_negative:				; negative interger to ASCII conversion algorithm
		xor		EDX, EDX
		mov		EBX, 10
		cdq
		idiv	EBX
		neg		DX					; negate each byte
		push	DX
		inc		ECX
		cmp		EAX, 0
		jne		_convert_negative

	cld
	mov		AL, 45					; append '- 'sign  (ASCII 45)
	stosb

_display_string:
	
	pop		AX						; pop stored characters from stack
	add		AX, 48					; add 48 to integer to get ASCII number 
	stosb
	loop	_display_string

	mDisplayString [EBP + 8]

	mov		EAX, [EBP + 16]			;last_num check
	mov		EBX, [EBP + 20]			; compare to ARRAYSIZE (10)
	cmp		EAX, EBX
	je		_exit

	mDisplayString [EBP + 12]

	push	ESI						; save ESI 
	xor		ECX, ECX
	xor		EDI, EDI
	mov		EDI, [EBP + 8]			;clear out out_str
	mov		ECX, 12
	mov		EAX, 0
	rep		stosb					; replace string contents with 0's for next use
	pop		ESI						; restore ESI

_exit:

	popad
	pop		EBP

	RET 16
WriteVal ENDP

; ----- * -----
; ArraySum
;
;		Sums the value in valid_nums array and invokes mDisplayString to display the total as a string. 
;		Byte conversion processed via stack
;
; preconditions: EBP preserved; registers preserved and cleared; valid_nums, array_sum passed via main
; postconditions: All registers restored  
;					
; receives: Variables: out_str, array_sum, valid_nums; EAX, EBX, ECX, EDX, ESI (valid_nums), EDI(out_str); 
;			integer constants: 10 (division/counter), 4 (to move through array), 0 (negative number check); 
;			ASCII 45 ('-'), 48 ('0')
;
;				[EBP + 8] = valid_nums
;				[EBP + 12] = array_sum
;				[EBP + 16] = out_str
;
; returns: Displays out_str (sum) to console; restores all registers			
; ----- * -----

ArraySum PROC
	push	EBP
	mov		EBP, ESP

	pushad

	xor		EAX, EAX
	xor		EBX, EBX
	xor		ECX, ECX
	xor		EDX, EDX

	mov		ESI, [EBP + 8]		; valid_nums
	mov		EAX, [EBP + 12]		; array_sum
	mov		ECX, 10

	_sum_loop:					; add elements of valid_nums together
	add		EAX, [ESI]
	add		ESI, 4
	loop	_sum_loop

	mov		[EBP + 12], EAX
	mov		EDI, [EBP + 16]		;out_str

	cmp		EAX, 0
	js		_convert_negative

_convert_positive:				; positive integer to ASCII algorithm
	xor		EDX, EDX
	mov		EBX, 10
	cdq
	idiv	EBX
	push	DX					;push each byte to stack
	inc		ECX
	cmp		EAX, 0
	jne		_convert_positive

	cld
	jmp		_display_string

	
_convert_negative:				; negative integer to ASCII algorithm 
	xor		EDX, EDX
	mov		EBX, 10
	cdq
	idiv	EBX
	neg		DX					; negate each byte before pushing to stack
	push	DX
	inc		ECX
	cmp		EAX, 0
	jne		_convert_negative

_neg_sign:
	cld
	mov		AL, 45				; append '-' sign, ASCII 45
	stosb

_display_string:
	
	pop		AX				
	add		AX, 48				; add 48 to each byte to get proper ASCII representation
	stosb
	loop	_display_string

	mDisplayString [EBP + 16]

	popad
	pop EBP
	RET 12
ArraySum ENDP

; ----- * -----
; ArrayAvg
;
;		Calculates the sum of the value in valid_nums then calculates the average of values. Invokes mDisplayString to display
;		truncated average to console by converting integers to string. Byte conversion processed via stack
;
; preconditions: EBP preserved; EAX, EBX, ECX, EDX cleared
; postconditions: EBP restored
;					
; receives: Constant: ARRAYSIZE (10); Variables: temp_str, array_sum, valid_nums; EAX, EBX, ECX, ESI (valid_nums), EDI (temp_str); 
;			integer constants: 10 (division/counter), 4 (to move through array), 0 (negative number check); ASCII 45 ('-'), 48 ('0')
;
;				[EBP + 8] = valid_nums
;				[EBP + 12] = array_sum
;				[EBP + 16] = temp_str
;				[EBP + 20] = ARRAYSIZE
;
; returns: Displays temp_str to console; EDX value (if present) is thrown out
; ----- * -----

ArrayAvg PROC
	push	EBP
	mov		EBP, ESP
	
	xor		EAX, EAX			; clear registers
	xor		EBX, EBX
	xor		ECX, ECX

	mov		ESI, [EBP + 8]		; valid_nums	
	mov		EAX, [EBP + 12]		; array_sum
	mov		ECX, [EBP + 20]		; ARRAYSIZE (10)

	_sum_loop:					; add elements of valid_nums together
	add		EAX, [ESI]
	add		ESI, 4
	loop	_sum_loop

	xor		EDX, EDX			; get average by dividing sum by number of elements
	mov		EBX, [EBP + 20]		; ARRAYSIZE (10), number of elements to divide sum

	cdq
	idiv	EBX

	mov		EDI, [EBP + 16]		;temp_str
	
	xor		ECX, ECX

	cmp		EAX, 0
	js		_convert_negative

_convert_positive:				; positive integer to ASCII algorithm 
	xor		EDX, EDX
	mov		EBX, 10
	cdq
	idiv	EBX
	push	DX					; push each byte to the stack
	inc		ECX
	cmp		EAX, 0
	jne		_convert_positive

	cld
	jmp		_display_string


_convert_negative:				; negative integer to ASCII algorithm
	xor		EDX, EDX
	mov		EBX, 10
	cdq
	idiv	EBX
	neg		DX					; negate each byte before pushing to stack
	push	DX
	inc		ECX
	cmp		EAX, 0
	jne		_convert_negative

	cld
	mov		AL, 45				; add '-' sign (ASCII 45)
	stosb

_display_string:		
	
	pop		AX					
	add		AX, 48				; add 48 to get ASCII representation of integer
	stosb
	loop	_display_string

	mDisplayString [EBP + 16]

	pop	EBP
	RET	16
ArrayAvg ENDP

; ----- * -----
; Farewell
;		Invokes mDisplayString to displays goodbye message to console.
;
; preconditions: EBP preserved
; postconditions: EBP restored
;					
; receives: string: goodbye
;			
;				[EBP + 8] = goodbye
;
; returns: Displays goodbye to console				
; ----- * -----

Farewell PROC
	push	EBP
	mov		EBP, ESP

	mDisplayString[EBP + 8]		;goodbye
	call CrLf

	pop		EBP
	RET 4
Farewell ENDP

END main
