

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;; P-Book                                            ;;
 ;; Prosta ksiazka telefoniczna z pseudo-graficznym   ;;
 ;; interfejsem uzytkownika.                          ;;
 ;; Potrafi                                           ;;
 ;;  * dodawac,                                       ;;   
 ;;  * przegladac,                                    ;;
 ;;  * usuwac wpisy.                                  ;;
 ;; by gronki (c) 2005 www.gronki.teleskopy.pl        ;;
 ;; cdev@teleskopy.pl                                 ;;
 ;; on GNU GPL                                        ;;
 ;; Jezyk asemblerowy kompatybilny z:                 ;;
 ;;  * Borland Turbo Assembler                        ;;
 ;;  * Microsoft Macro Assembler                      ;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



.MODEL SMALL
.STACK 80H
.DATA
	SZ_PROGNAME	DB 'P-Book$'
	SZ_ABOUT1	DB 'by gronki (c) 2005. cdev@teleskopy.pl$'
	SZ_ABOUT2	DB 'http://www.gronki.teleskopy.pl$'
	SZ_ABOUT3	DB 'Potrzebujesz pomocy? Wpisz: type help.txt |more$'
	SZ_SRCH1	DB 'Wytypuj kryterium wyszukiwania.$'
	SZ_SRCH2	DB 'Zakonczono wyszukiwanie. Wpisz ID wpisu aby go zazn.:$'
	SZ_ADDE1	DB 'Wpisz dane nowej osoby.$'
	SZ_ADDE2	DB ' Imie:     $'
	SZ_ADDE3	DB ' Nazwisko: $'
	SZ_ADDE4	DB ' Tel#1:    $'
	SZ_ADDE5	DB ' Tel#2:    $'
	SZ_ADDE6	DB ' E-Mail:   $'
	SZ_ADDE7	DB 'Dodawanie nowego wpisu zakonczone pomyslnie.$'
	SZ_ADDE8	DB 'Dodanie wpisu nie powiodlo sie.$'
	SZ_BRWS1	DB 'Aby zaznaczyc wpis, nacisnij [enter].$'
	SZ_BRWS2	DB 'Aby nie zmieniac zaznaczenia nacisnij [esc].$'
	SZ_NO_RECORDS	DB 'Brak jakichkolwiek wpisow w bazie.$'
	SZ_DELT1	DB '[T/N] Czy na pewno usunac wpis "$'
	SZ_NOSELECT	DB 'Aby zaznaczyc wpis, wybierz polecenie "Przegladaj".$'
	SZ_INTEGR_ERR	DB 'Przeprowadzany test integralnosci wykazal niepoprawna dlugosc pliku bazy. Moze  to oznaczac uszkodzenie bazy danych.',0AH,0DH
			DB ' WSKAZOWKA: Dlugosc pliku bazy jest wielokrotnoscia dlugosci jednego rekordu.$'
	SZ_CANNOT_LOAD	DB 'Otworzenie pliku bazy danych do odczytu okazalo sie niemozliwe. Byc moze plik zostal usuniety lub jego nazwa zostala zmieniona.$'
	SZ_DELETED	DB 'Nie mozna przeprowadzic operacji na usunietym wpisie.$'

	SZ_WINDOW	DB 0C9H,19 DUP (0CDH),0CBH,42 DUP (0CDH),' P-Book 1.0 ',0CDH,0CDH, 0BBH,0AH,0DH
			DB 020H, 0BAH, '    MENU',11 DUP (020H),0BAH,56 DUP (020H), 0BAH,0AH,0DH
			DB 20 DUP ( 020H, 0BAH,19 DUP (020H),0BAH,56 DUP (020H), 0BAH,0AH,0DH )
			DB 020H,0C8H,19 DUP (0CDH),0CAH,56 DUP (0CDH) , 0BCH
			DB '$'

	ATTRIB_OFF	EQU 00011111B
	ATTRIB_ON	EQU 01001110B
	ATTRIB_NOTACT	EQU 01111111B
	SELECT_CHAR	EQU 0AFH
	DELETE_CHAR	EQU 0E5H
	MENU_ITEMS_IND	EQU 2
	MENU_ITEMS_TOP	EQU 3
	MENU_ITEMS_LEN	EQU 20
	MENU_ITEMS_CNT	EQU 7
	RECORD_LEN	EQU 15+20+12+12+30
	MENU_ITEMS	DB '  Nowy rekord      $'  ; 0
			DB '  Przegladaj wpisy $'  ; 1
			DB '  Zmien zazn. wpis $'  ; 3
			DB '  Usun zazn. wpis  $'  ; 4
			DB '  O programie      $'  ; 5
			DB '  Wymus zapisanie  $'  ; 6
			DB '  Zakoncz prace    $'  ; 7
	GMODE		DB ?
	USER_SELECT	DB 1
	SELECTED_ENT	DW 3
	FILE_HANDLE	DW ?
	ERROR		DB 0
	MEM_SIZE	DW ?
	DB_FILENAME	DB 'DATA.DAT',00H
	TEMP1		DW ?

	EDITPAR		LABEL BYTE
	 ED_MAX_LEN	DB 20
	 ED_CUR_LEN	DB 2
	 ED_CURSOR_POS	DB ?
	 ED_BUFFER	DB 30 DUP (' ')

	 RECORD_NAME_LEN	EQU 15
	 RECORD_LNAME_LEN	EQU 20
	 RECORD_TEL1_LEN	EQU 12
	 RECORD_TEL2_LEN	EQU 12
	 RECORD_EMAIL_LEN	EQU 30

	ONE_RECORD LABEL BYTE
	 RECORD_NAME	DB 15 DUP (?)
	 RECORD_LNAME	DB 20 DUP (?)
	 RECORD_TEL1	DB 12 DUP (?)
	 RECORD_TEL2	DB 12 DUP (?)
	 RECORD_EMAIL	DB 30 DUP (?)

	NAME_OFF	EQU (OFFSET RECORD_NAME) - (OFFSET ONE_RECORD)
	LNAME_OFF	EQU (OFFSET RECORD_LNAME) - (OFFSET ONE_RECORD)
	TEL1_OFF	EQU (OFFSET RECORD_TEL1) - (OFFSET ONE_RECORD)
	TEL2_OFF	EQU (OFFSET RECORD_TEL2) - (OFFSET ONE_RECORD)
	EMAIL_OFF	EQU (OFFSET RECORD_EMAIL) - (OFFSET ONE_RECORD)

	MAX_ENTRIES	EQU 50
	MEMORY_MAX	EQU MAX_ENTRIES*RECORD_LEN
	MEMORY		DB MEMORY_MAX DUP ( DELETE_CHAR )

.386
.CODE
MAIN:
	MOV AX,@data
	MOV DS,AX
	MOV ES,AX

	MOV AH,0FH
	INT 10H
	MOV GMODE,AL
	MOV AH,00H
	MOV AL,03H
	INT 10H

	CALL LOAD_DATABASE
	CMP ERROR,0
	JE _CHECK_I
	MOV AH,09H
	LEA DX,SZ_CANNOT_LOAD
	INT 21H
	JMP _PROG_HALT
_CHECK_I:
	CALL CHECK_INTEGRITY
	CMP ERROR,0
	JE _SETGRAPH
	MOV AH,09H
	LEA DX,SZ_INTEGR_ERR
	INT 21H
	JMP _PROG_HALT

_SETGRAPH:
	MOV AX,0600H
	MOV BH,ATTRIB_OFF
	MOV CX,0101H
	MOV DX,174EH
	INT 10H
	MOV AH,02H
	MOV BH,0
	MOV DX,0101H
	INT 10H

	MOV AH,09H
	LEA DX,SZ_WINDOW
	INT 21H

	CALL SHOWMENU
	MOV AL,ATTRIB_ON
	CALL HIGHLIGHT

MAIN_KEYLOOP:
	CALL MENU
	CALL CLEAR_SCREEN

	MOV AL,ATTRIB_NOTACT
	CALL HIGHLIGHT

	CMP USER_SELECT,0
	JNE MAIN_KEYLOOP_1
	CALL FUNCTION_NEW_ENTRY
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_1:
	CMP USER_SELECT,1
	JNE MAIN_KEYLOOP_2
	CALL FUNCTION_VIEW_ENTRIES
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_2:
	CMP USER_SELECT,2
	JNE MAIN_KEYLOOP_3
	CALL FUNCTION_EDIT_ENTRY
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_3:
	CMP USER_SELECT,3
	JNE MAIN_KEYLOOP_4
	CALL FUNCTION_DELETE_ENTRY
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_4:
	CMP USER_SELECT,4
	JNE MAIN_KEYLOOP_05
	CALL FUNCTION_ABOUT
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_05:
	CMP USER_SELECT,5
	JNE MAIN_KEYLOOP_5
	CALL SAVE_DATABASE
	JMP MAIN_KEYLOOP_Q
MAIN_KEYLOOP_5:
	CMP USER_SELECT,6
	JE _PROG_EXIT
	
MAIN_KEYLOOP_Q:
	MOV AL,ATTRIB_ON
	CALL HIGHLIGHT
	JMP MAIN_KEYLOOP

_PROG_EXIT:
	CALL SAVE_DATABASE
	MOV AX,0600H
	MOV BH,111B
	MOV CX,0000H
	MOV DX,184FH
	INT 10H
	MOV AH,02H
	MOV BH,0
	MOV DX,0000H
	INT 10H
	MOV AH,00H
	MOV AL,GMODE
	INT 10H
_PROG_HALT:
	MOV AX,4C00H
	INT 21H


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;      procedury      ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CHECK_INTEGRITY:
	MOV AX,MEM_SIZE
	MOV DX,0
	MOV BX,RECORD_LEN
	DIV BX
	CMP DX,0
	SETNE ERROR
	RET


LOAD_DATABASE:
	MOV AX,3D00H
	LEA DX,DB_FILENAME
	INT 21H
	JNC LOAD_DATABASE_1
	MOV ERROR,1
	RET
LOAD_DATABASE_1:
	MOV FILE_HANDLE,AX
	MOV AX,4202H
	MOV BX,FILE_HANDLE
	MOV CX,0000H	
	MOV DX,0000H
	INT 21H
	MOV MEM_SIZE,AX
	CMP MEM_SIZE,0
	JE LOAD_DATABASE_2
	MOV AX,4200H
	MOV BX,FILE_HANDLE
	MOV CX,0000H
	MOV DX,0000H
	INT 21H
	MOV AH,3FH
	MOV CX,MEM_SIZE
	LEA DX,MEMORY
	INT 21H
	JNC LOAD_DATABASE_2
	MOV ERROR,1
	RET
LOAD_DATABASE_2:
	; zamykamy plik
	MOV AH,32H
	MOV BX,FILE_HANDLE
	INT 21H
	RET


SAVE_DATABASE:
	MOV AH,3DH
	MOV AL,01H
	LEA DX,DB_FILENAME
	INT 21H
	SETC ERROR
	MOV FILE_HANDLE,AX
	MOV AH,40H
	MOV BX,FILE_HANDLE
	MOV CX,MEM_SIZE
	LEA DX,MEMORY
	INT 21H
	SETC ERROR
	MOV AH,3EH
	MOV BX,FILE_HANDLE
	INT 21H
	RET


FUNCTION_NEW_ENTRY:
	LEA DX,SZ_ADDE1
	MOV AH,09H
	INT 21H

	MOV AL,5
	CALL SET_CURSOR
	LEA DX,SZ_ADDE2
	MOV AH,09H
	INT 21H
	LEA DX,RECORD_NAME
	MOV AX,15
	CALL READSTR

	MOV AL,6
	CALL SET_CURSOR
	LEA DX,SZ_ADDE3
	MOV AH,09H
	INT 21H
	LEA DX,RECORD_LNAME
	MOV AX,20
	CALL READSTR

	MOV AL,7
	CALL SET_CURSOR
	LEA DX,SZ_ADDE4
	MOV AH,09H
	INT 21H
	LEA DX,RECORD_TEL1
	MOV AX,12
	CALL READSTR

	MOV AL,8
	CALL SET_CURSOR
	LEA DX,SZ_ADDE5
	MOV AH,09H
	INT 21H
	LEA DX,RECORD_TEL2
	MOV AX,12
	CALL READSTR

	MOV AL,9
	CALL SET_CURSOR
	LEA DX,SZ_ADDE6
	MOV AH,09H
	INT 21H
	LEA DX,RECORD_EMAIL
	MOV AX,30
	CALL READSTR

	CMP MEM_SIZE,0
	JE FUNCTION_NEW_ENTRY_CNEW
	; najpierw szukamy czy nie ma usunietych wpisow do uzycia
	LEA BX,MEMORY
	MOV SI,0
FUNCTION_NEW_ENTRY_1:
	CMP SI,MEMORY_MAX
	JNB FUNCTION_NEW_ENTRY_NOMEM
	CMP SI,MEM_SIZE
	JNB FUNCTION_NEW_ENTRY_CNEW
	CMP BYTE PTR [BX+SI],DELETE_CHAR
	JE FUNCTION_NEW_ENTRY_3
	ADD SI,RECORD_LEN
	JMP FUNCTION_NEW_ENTRY_1

FUNCTION_NEW_ENTRY_NOMEM:
	MOV ERROR,1
	RET
FUNCTION_NEW_ENTRY_CNEW:
	MOV DI,MEM_SIZE
	ADD MEM_SIZE,RECORD_LEN
	JMP FUNCTION_NEW_ENTRY_4
FUNCTION_NEW_ENTRY_3:
	MOV DI,SI
FUNCTION_NEW_ENTRY_4:
	MOV CX,RECORD_LEN
	LEA SI,ONE_RECORD
	ADD DI,OFFSET MEMORY
REP	MOVSB
FUNCTION_NEW_ENTRY_Q:
	CALL CLEAR_SCREEN
	LEA DX,SZ_ADDE7
	MOV AH,09H
	INT 21H
	RET


FUNCTION_VIEW_ENTRIES:
	CMP MEM_SIZE,0				; dlugosc == 0?
	JE FUNCTION_VIEW_ENTRIES_NODATA		;  tak, brak wpisow
	LEA BX,MEMORY				; wpisy sa ale nei wiemy czy nieusuniete
	MOV SI,0
FUNCTION_VIEW_ENTRIES_1:
	CMP SI,MEM_SIZE				; to koniec danych?
	JNB FUNCTION_VIEW_ENTRIES_NODATA	;  tak, nie znaleziono wpisow aktywnych
	CMP BYTE PTR [BX+SI],DELETE_CHAR	; czy to wpis usuniety?
	JNE FUNCTION_VIEW_ENTRIES_3		;  nie, jednak cos jest
	ADD SI,RECORD_LEN			; nastepny wpis
	JMP FUNCTION_VIEW_ENTRIES_1

FUNCTION_VIEW_ENTRIES_3:
	MOV AH,09H
	LEA DX,SZ_BRWS1
	INT 21H
	MOV AL,2
	CALL SET_CURSOR
	LEA DX,SZ_BRWS2
	INT 21H

FUNCTION_VIEW_ENTRIES_2:
	MOV DX,BX
	ADD DX,SI
	CALL REFRESH_ENTRY_WINDOW
	CALL VE_DISPLAY_ENTRY
	MOV AH,10H
	INT 16H
	CMP AH,01H				; escape?
	JE FUNCTION_VIEW_ENTRIES_Q
	CMP AH,1CH				; enter?
	JE FUNCTION_VIEW_ENTRIES_SEL
	CMP AL,'n'
	JE FUNCTION_VIEW_ENTRIES_REMSEL
	CMP AL,'N'
	JE FUNCTION_VIEW_ENTRIES_REMSEL
	; <- = 4Bh; -> = 4Dh
	CMP AH,4BH				; w lewo?
	JNE FUNCTION_VIEW_ENTRIES_21
	CALL FUNCTION_VIEW_ENTRIES_LEFT
	JMP FUNCTION_VIEW_ENTRIES_2
FUNCTION_VIEW_ENTRIES_21:
	CMP AH,4DH				; w prawo?
	JNE FUNCTION_VIEW_ENTRIES_22
	CALL FUNCTION_VIEW_ENTRIES_RIGHT
	JMP FUNCTION_VIEW_ENTRIES_2
FUNCTION_VIEW_ENTRIES_22:
	JMP FUNCTION_VIEW_ENTRIES_2

FUNCTION_VIEW_ENTRIES_SEL:
	MOV SELECTED_ENT,SI
	JMP FUNCTION_VIEW_ENTRIES_Q

FUNCTION_VIEW_ENTRIES_REMSEL:
	MOV SELECTED_ENT,3
	JMP FUNCTION_VIEW_ENTRIES_Q

FUNCTION_VIEW_ENTRIES_NODATA:
	LEA DX,SZ_NO_RECORDS
	MOV AH,09H
	INT 21H
FUNCTION_VIEW_ENTRIES_Q:
	RET


FUNCTION_VIEW_ENTRIES_LEFT:
	MOV TEMP1,SI
	CMP SI,0
	JE FUNCTION_VIEW_ENTRIES_LEFT_Q
FUNCTION_VIEW_ENTRIES_LEFT_SUB:
	SUB SI,RECORD_LEN
	CMP BYTE PTR [BX+SI],DELETE_CHAR
	JNE FUNCTION_VIEW_ENTRIES_LEFT_Q
	CMP SI,0
	JNE FUNCTION_VIEW_ENTRIES_LEFT_SUB
	MOV SI,TEMP1
FUNCTION_VIEW_ENTRIES_LEFT_Q:
	RET


FUNCTION_VIEW_ENTRIES_RIGHT:
	MOV TEMP1,SI
	MOV AX,MEM_SIZE
	SUB AX,RECORD_LEN
	CMP SI,AX
	JNB FUNCTION_VIEW_ENTRIES_RIGHT_Q
FUNCTION_VIEW_ENTRIES_RIGHT_ADD:
	ADD SI,RECORD_LEN
	CMP BYTE PTR [BX+SI],DELETE_CHAR
	JNE FUNCTION_VIEW_ENTRIES_RIGHT_Q
	CMP SI,AX
	JB FUNCTION_VIEW_ENTRIES_RIGHT_ADD
	MOV SI,TEMP1
FUNCTION_VIEW_ENTRIES_RIGHT_Q:
	RET


VE_DISPLAY_ENTRY:
	PUSH BX
	MOV BX,DX

	MOV AL,5
	CALL SET_CURSOR
	LEA DX,SZ_ADDE2
	MOV AH,09H
	INT 21H
	MOV DX,BX
	CALL PRINTSTR

	MOV AL,6
	CALL SET_CURSOR
	LEA DX,SZ_ADDE3
	MOV AH,09H
	INT 21H
	MOV DX,BX
	ADD DX,LNAME_OFF
	CALL PRINTSTR

	MOV AL,7
	CALL SET_CURSOR
	LEA DX,SZ_ADDE4
	MOV AH,09H
	INT 21H
	MOV DX,BX
	ADD DX,TEL1_OFF
	CALL PRINTSTR

	MOV AL,8
	CALL SET_CURSOR
	LEA DX,SZ_ADDE5
	MOV AH,09H
	INT 21H
	MOV DX,BX
	ADD DX,TEL2_OFF
	CALL PRINTSTR

	MOV AL,9
	CALL SET_CURSOR
	LEA DX,SZ_ADDE6
	MOV AH,09H
	INT 21H
	MOV DX,BX
	ADD DX,EMAIL_OFF
	CALL PRINTSTR

	POP BX
	RET


REFRESH_ENTRY_WINDOW:
	PUSHA
	MOV AX,0600H
	MOV BH,(ATTRIB_OFF and 0F0H or 1110B)
	MOV CX,0818H
	MOV DX,0C40H
	INT 10H
	POPA
	RET


FUNCTION_EDIT_ENTRY:
	CMP SELECTED_ENT,3
	JE FUNCTION_EDIT_ENTRY_NOSEL
	LEA SI,MEMORY
	ADD SI,SELECTED_ENT
	CMP BYTE PTR [SI],DELETE_CHAR
	JE  FUNCTION_EDIT_ENTRY_DELT

	COL_CNT = 0
IRP	L,<RECORD_NAME_LEN,RECORD_LNAME_LEN,RECORD_TEL1_LEN,RECORD_TEL2_LEN,RECORD_EMAIL_LEN>
	MOV [ED_BUFFER],00H
	LEA DI,ED_BUFFER
	MOV CX,L
	PUSH SI
	PUSH DI
REP	MOVSB
	MOV ED_MAX_LEN,L
	PUSH OFFSET EDITPAR
	CALL EDIT_TEXT
	ADD SP,2
	POP DI
	POP SI
	PUSH SI
	MOV DI,SI
	LEA SI,ED_BUFFER
	MOVZX CX,ED_CUR_LEN
	INC CX
REP	MOVSB
	COL_CNT = COL_CNT + 2
	MOV AL,COL_CNT
	CALL SET_CURSOR
	POP SI
	ADD SI,L
	ENDM


	JMP FUNCTION_EDIT_ENTRY_Q
FUNCTION_EDIT_ENTRY_DELT:
	LEA DX,SZ_DELETED
	MOV AH,09H
	INT 21H
	JMP FUNCTION_EDIT_ENTRY_Q
FUNCTION_EDIT_ENTRY_NOSEL:
	LEA DX,SZ_NOSELECT
	MOV AH,09H
	INT 21H
FUNCTION_EDIT_ENTRY_Q:
	RET


FUNCTION_SEARCH:
	LEA DX,SZ_SRCH1
	MOV AH,09H
	INT 21H
	RET


FUNCTION_DELETE_ENTRY:
	CMP SELECTED_ENT,3
	JE FUNCTION_DELETE_ENTRY_ERR
	LEA BX,MEMORY
	MOV SI,SELECTED_ENT
	CMP BYTE PTR [BX+SI],DELETE_CHAR
	JE FUNCTION_DELETE_ENTRY_DELT
	MOV AH,09H
	LEA DX,SZ_DELT1
	INT 21H
	MOV DX,BX
	ADD DX,SI
	ADD DX,LNAME_OFF
	CALL PRINTSTR
	MOV AH,0EH
	MOV AL,'"'
	INT 10H
	MOV AL,'?'
	INT 10H
	MOV AH,10H
	INT 16H
	CMP AL,'N'
	JE FUNCTION_DELETE_ENTRY_Q
	CMP AL,'n'
	JE FUNCTION_DELETE_ENTRY_Q
	MOV BYTE PTR [BX+SI],DELETE_CHAR
	JMP FUNCTION_DELETE_ENTRY_Q
FUNCTION_DELETE_ENTRY_DELT:
	LEA DX,SZ_DELETED
	MOV AH,09H
	INT 21H
	JMP FUNCTION_DELETE_ENTRY_Q
FUNCTION_DELETE_ENTRY_ERR:
	LEA DX,SZ_NOSELECT
	MOV AH,09H
	INT 21H
FUNCTION_DELETE_ENTRY_Q:
	RET


FUNCTION_ABOUT:
	MOV AH,09H
	LEA DX,SZ_PROGNAME
	INT 21H
	MOV AL,1
	CALL SET_CURSOR
	MOV AH,09H
	LEA DX,SZ_ABOUT1
	INT 21H
	MOV AL,2
	CALL SET_CURSOR
	MOV AH,09H
	LEA DX,SZ_ABOUT2
	INT 21H
	MOV AL,4
	CALL SET_CURSOR
	MOV AH,09H
	LEA DX,SZ_ABOUT3
	INT 21H
	RET



CLEAR_SCREEN:
	PUSHA
	MOV AX,0600H
	MOV BH,ATTRIB_OFF
	MOV CX,0217H
	MOV DX,164CH
	INT 10H
	MOV AL,0
	CALL SET_CURSOR
	POPA
	RET


;;;;;;;;;;;;;;;;;; menu start ;;;;;;;;;;;;;;;;;;;
SHOWMENU:
	PUSHA
	MOV CX,0
	LEA SI,MENU_ITEMS
SHOWMENU_1:
	CMP CX,MENU_ITEMS_CNT
	JNB SHOWMENU_2
	MOV AH,02H
	MOV BH,00H
	MOV DH,CL
	ADD DH,MENU_ITEMS_TOP
	MOV DL,MENU_ITEMS_IND
	INT 10H
	MOV DX,SI
	MOV AH,09H
	INT 21H
	ADD SI,MENU_ITEMS_LEN
	INC CX
	JMP SHOWMENU_1
SHOWMENU_2:
	POPA
	RET



MENU:
MENU_KBDLOOP:
	MOV AH,10H
	INT 16H
	CMP AH,48H
	JNE MENU_C1
	CALL MENU_ARROW_UP
	JMP MENU_Q1
MENU_C1:
	CMP AH,50H
	JNE MENU_C2
	CALL MENU_ARROW_DN
	JMP MENU_Q1
MENU_C2:
	CMP AH,1CH
	JE MENU_Q
MENU_Q1:
	JMP MENU_KBDLOOP
MENU_Q:
	RET

SET_CURSOR:
	PUSH AX
	PUSH BX
	PUSH DX
	MOV DH,AL
	ADD DH,03H
	MOV DL,18H
	MOV AH,02H
	MOV BH,00H
	INT 10H
	POP DX
	POP BX
	POP AX
	RET


MENU_ARROW_UP:
	MOV AL,ATTRIB_OFF
	CALL HIGHLIGHT
	CMP USER_SELECT,0
	JE MENU_ARROW_UP_1
	DEC USER_SELECT
	JMP MENU_ARROW_UP_2
MENU_ARROW_UP_1:
	MOV USER_SELECT,MENU_ITEMS_CNT-1
MENU_ARROW_UP_2:
	MOV AL,ATTRIB_ON
	CALL HIGHLIGHT
	RET


MENU_ARROW_DN:
	MOV AL,ATTRIB_OFF
	CALL HIGHLIGHT
	CMP USER_SELECT,MENU_ITEMS_CNT-1
	JE MENU_ARROW_DN_1
	INC USER_SELECT
	JMP MENU_ARROW_DN_2
MENU_ARROW_DN_1:
	MOV USER_SELECT,0
MENU_ARROW_DN_2:
	MOV AL,ATTRIB_ON
	CALL HIGHLIGHT
	RET



HIGHLIGHT:
	PUSH ES
	PUSH DI
	PUSH CX
	PUSH AX
	MOV AL,USER_SELECT
	ADD AL,MENU_ITEMS_TOP
	MOV CL,0A0H
	MUL CL
	ADD AX,MENU_ITEMS_IND*2
	MOV DI,AX
	MOV AX,0B800H
	MOV ES,AX
	POP AX
	MOV CX,MENU_ITEMS_LEN-1
	CMP AL,ATTRIB_OFF
	JE HIGHLIGHT_2
	MOV BYTE PTR ES:[DI],SELECT_CHAR
	JMP HIGHLIGHT_1
HIGHLIGHT_2:
	MOV BYTE PTR ES:[DI],020H
HIGHLIGHT_1:
	MOV ES:[DI+1],AL
	ADD DI,2
	LOOP HIGHLIGHT_1
	POP CX
	POP DI
	POP ES
	RET

;;;;;;;;;;;;;;;;;; menu koniec ;;;;;;;;;;;;;;;;;;



; EDIT_TEXT pozwala edytowac tekst podobnie niczym
; w windowsowym polu edycji
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
	JE EDIT_TEXT_02
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
	MOV BL,ATTRIB_OFF
	INT 10H
	POP BX
	JMP EDIT_TEXT_1
EDIT_TEXT_02:
	MOV PARAM_LEN,2
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




; PRINTSTR drukuje ciag ASCIIZ
; DX = adres
PRINTSTR:
	PUSH AX
	PUSH SI
	PUSH DX
	MOV SI,DX
PRINTSTR_1:
	CMP BYTE PTR [SI],0
	JE PRINTSTR_2
	MOV AL,[SI]
	MOV AH,0EH
	INT 10H
	INC SI
	JMP PRINTSTR_1
PRINTSTR_2:
	POP DX
	POP SI
	POP AX
	RET

; READSTR pobiera ciag znakow ASCIIZ
; DX = BUFOR; AX = MAX DLUGOSC;
READSTR:
	PUSHA
	MOV DI,DX
	MOV DX,AX
	DEC DX			; o 1 znak mniej
	MOV CX,0
READSTR_1:
	MOV AH,10H
	INT 16H
	CMP AL,0DH
	JE READSTR_EOL
	CMP AL,08H
	JE READSTR_BCKSP
	CMP CX,DX
	JNB READSTR_ALM
	MOV AH,0EH
	INT 10H
	MOV BYTE PTR [DI],AL
	INC CX
	INC DI
	JMP READSTR_1
READSTR_EOL:
	MOV BYTE PTR [DI],00H
	JMP READSTR_END
READSTR_BCKSP:
	CMP CX,0
	JE READSTR_ALM
	DEC DI
	DEC CX
	MOV AX,0E08H
	INT 10H
	XOR BX,BX
	PUSH CX
	MOV AX,0A20H
	MOV CX,01H
	INT 10H
	POP CX
	JMP READSTR_1
READSTR_ALM:
	MOV AX,0E07H
	INT 10H
	JMP READSTR_1
READSTR_END:
	POPA
	RET

END MAIN
