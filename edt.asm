.MODEL SMALL
.STACK 64
.DATA

	EDITPAR		LABEL BYTE
	MAX_LEN		DB 20
	CUR_LEN		DB 2
	CURSOR_POS	DB ?
	BUFFER		DB 'hello',00h
			DB 30 DUP (' ')

.386
.CODE
MAIN:
	MOV AX,@data
	MOV DS,AX
	MOV ES,AX

	PUSH OFFSET EDITPAR
	CALL EDIT_TEXT
	ADD SP,2

	MOV AH,13H
	MOV AL,00H
	MOV BH,00H
	MOV BL,0F0H
	LEA BP,BUFFER
	MOVZX CX,CUR_LEN
	MOV DH,5
	MOV DL,10
	INT 10H

	MOV AX,4C00H
	INT 21H


;;;;;;;;;;;;;;; edycja start ;;;;;;;;;;;;;;;;
	PARAM_MAX EQU <BYTE PTR [BX]>
	PARAM_LEN EQU <BYTE PTR [BX+1]>
	PARAM_CUR EQU <BYTE PTR [BX+2]>
EDIT_TEXT:
	PUSH BP
	MOV BP,SP
	PUSHA
	MOV BX,[BP+4]
	; najpierw obliczamy dlugosc
	MOV PARAM_LEN,0
	MOV DI,3
EDIT_TEXT_0:
	MOV AL,PARAM_LEN
	CMP AL,PARAM_MAX
	JNB EDIT_TEXT_01
	CMP BYTE PTR [BX+DI],0
	JE EDIT_TEXT_01
	INC PARAM_LEN
	INC DI
	JMP EDIT_TEXT_0
EDIT_TEXT_01:
	MOV PARAM_CUR,0
	CMP PARAM_LEN,0
	JE EDIT_TEXT_1
	; jezeli jest tekst poczatkowy to go wypisyjemy
	PUSH BX
	MOV AH,03H
	MOV BH,00H
	INT 10H
	POP BX
	MOV AX,1300H
	MOV BP,BX
	ADD BP,3
	MOVZX CX,BYTE PTR [BX+1]
	PUSH BX
	MOV BH,00H
	MOV BL,0FH
	INT 10H
	POP BX
EDIT_TEXT_1:
EDIT_TEXT_L:
	MOV AH,10H
	INT 16H
	CMP AH,0EH
	JE EDIT_TEXT_L01		; backspace tez przesuwa w lewo
	CMP AH,4BH			; lewo
	JNE EDIT_TEXT_L1
EDIT_TEXT_L01:
	CALL EDIT_TEXT_LEFT
	JMP EDIT_TEXT_L
EDIT_TEXT_L1:
	CMP AH,4DH			; prawo
	JNE EDIT_TEXT_L3
	CALL EDIT_TEXT_RIGHT
	JMP EDIT_TEXT_L
EDIT_TEXT_L3:
	CMP AH,1CH
	JE EDIT_TEXT_FINALIZE
	CMP AL,20H
	JB EDIT_TEXT_L
	CALL EDIT_TEXT_APP
	JMP EDIT_TEXT_L
EDIT_TEXT_FINALIZE:
	; finalizujemy ciag, tzn.usuwamy spacje z prawej
	; i wstawiamy zero
	MOV DI,BX
	ADD DI,2
	MOVZX AX,BYTE PTR [BX+1]
	ADD DI,AX
	MOVZX CX,BYTE PTR [BX+1]
	MOV AL,20H
	STD
REPE	SCASB
	CLD
	MOV BYTE PTR [DI+2],00H
EDIT_TEXT_Q:
	POPA
	POP BP
	RET


EDIT_TEXT_LEFT:
	CMP BYTE PTR [BX+2],0
	JE EDIT_TEXT_LEFT_Q
	PUSH BX
	MOV AH,03H
	MOV BH,00H
	INT 10H
	MOV AH,02H
	MOV BH,00H
	DEC DL
	INT 10H
	POP BX
	DEC BYTE PTR [BX+2]
EDIT_TEXT_LEFT_Q:
	RET


EDIT_TEXT_RIGHT:
	MOV AL,[BX+1]
	CMP AL,[BX+2]
	JNA EDIT_TEXT_RIGHT_Q
	PUSH BX
	MOV AH,03H
	MOV BH,00H
	INT 10H
	MOV AH,02H
	MOV BH,00H
	INC DL
	INT 10H
	POP BX
	INC BYTE PTR [BX+2]
EDIT_TEXT_RIGHT_Q:
	RET

EDIT_TEXT_APP:
	MOV AH,PARAM_MAX
	DEC AH
	CMP AH,PARAM_CUR
	JNA EDIT_TEXT_APP_Q
	CMP PARAM_LEN,0
	JE EDIT_TEXT_APP_1
	MOV AH,PARAM_LEN
	CMP AH,PARAM_CUR
	JNE EDIT_TEXT_APP_1
	CMP AH,PARAM_MAX
	JNB EDIT_TEXT_APP_Q
	INC PARAM_LEN
EDIT_TEXT_APP_1:
	MOVZX DI,PARAM_CUR
	MOV BYTE PTR [BX+DI+3],AL
	MOV AH,0AH
	PUSH BX
	MOV BX,0000H
	MOV CX,0001H
	INT 10H
	POP BX
	MOV AH,PARAM_MAX
	DEC AH
	CMP PARAM_CUR,AH
	JNB EDIT_TEXT_APP_Q
	CALL EDIT_TEXT_RIGHT
EDIT_TEXT_APP_Q:
	RET
;;;;;;;;;;;;;;; edycja koniec ;;;;;;;;;;;;;;;

END MAIN

