INCLUDE Irvine32.inc
INCLUDE Macros.inc

DrawChar PROTO, charToWrite:BYTE, x:BYTE, y:BYTE, clr:BYTE

StartX = 39   ;center
StartY = 10


.data
xyPos COORD <39,10>

outHandle dword ?
cellsWritten dword ?

chToMove byte 'I'
clrToHide byte ?
clrToShow byte ?

maxX byte 75    ; rectangle dimensions 
minX byte 3
maxY byte 17
minY byte 5

.code
main3 PROC
INVOKE GetStdHandle,STD_OUTPUT_HANDLE
	mov outHandle,eax

call GetTextColor           
mov clrToShow,al                           

mov clrToHide,al 
and clrToHide,11110000b  ; make lower 4 bits same as upper 4 bits
shr al,4
or clrToHide,al

mWrite <"iMove Guide: ",0dh,0ah>
mWrite <"Press the F1 key for help...",0dh,0ah>


call DrawRectangle
INVOKE WriteConsoleOutputCharacter,      ; write first centered char
	  outHandle,ADDR chToMove, 1,
	  xyPos, ADDR cellsWritten

mov bl,StartX     ; move startx and starty to current pos.
mov bh,StartY

again:
mov xyPos.x,0                        ; always move cursor on top
mov xyPos.y,1
INVOKE SetConsoleCursorPosition,outHandle,xyPos

mov dl,bl
mov dh,bh
call ProcessKey             ; exit if CF set
jc quit

.IF bl == maxX || bl == minX  || bh == maxY || bh == minY     ;check out of boundary
	mov al,7h
	call WriteChar
	mov bl,dl			 ; reset x and y pos
	mov bh,dh
	jmp again
.ENDIF

INVOKE DrawChar, chToMove, dl, dh, clrToHide    ; previous 'I' at dx
INVOKE DrawChar, chToMove, bl, bh, clrToShow    ; current  'I' at bx
jmp again


quit:
	mov xyPos.x,0
	mov xyPos.y,20
	INVOKE SetConsoleCursorPosition,outHandle,xyPos
	call Waitmsg
	exit
main3 ENDP

;------------------------------------------------------------------
DrawChar PROC charToWrite:BYTE, x:BYTE, y:BYTE, clr:BYTE
; Draws a character at a given position. 
; Receives: charToWrite - the character used to represent
;           x, y - position at coordinate x, y (Col, Row)
;           clr - the color used to draw char
;-------------------------------------------------------------------
pushad

movzx ax,x
movzx bx,y
mov xyPos.x,ax
mov xyPos.y,bx
INVOKE WriteConsoleOutputAttribute, outHandle, ADDR clr, 1, xyPos, ADDR cellsWritten
INVOKE WriteConsoleOutputCharacter, outHandle, ADDR charToWrite, 1, xyPos, ADDR cellsWritten

popad
ret
DrawChar ENDP

;------------------------------------------------------------
DrawRectangle PROC
; Draws a boarder rectangle from MinX, MinY to MaxX MaxY. 
; Receives: Conctant symbils: MinX, MinY to MaxX MaxY
; Returns: nothing
;------------------------------------------------------------

mov dl,minX    ; move cursor to minx and miny to draw rectangle
mov dh,minY 
call Gotoxy
mov ecx,73
L1:
mov al, 0CDh  ;horizontal lines
call WriteChar
loop L1


inc dh         ; next line
call Gotoxy

mov ecx,11
L2:
mov al,0BAh           ;vertical lines
call WriteChar

mov dl,maxX           ; move at maxX and draw vertical lines again
call GotoXY

mov al,0BAh
call WriteChar

inc dh                ; move again at minX
mov dl,minX
call Gotoxy
loop L2

mov ecx,73
L3:
mov al, 0CDh   ;horizontal lines
call WriteChar
loop L3

ret
DrawRectangle ENDP

;----------------------------------------------------------------
ProcessKey PROC
; By reading a char, checks its scan code to recognize 
; Arrow, Control Arrow, Home, ESC, and F1 keys. Then take 
; the action accordingly
; Return: carry flage set if ESC pressed, else cleared
;------------------------------------------------------------------

call ReadChar
.IF AH == 48h ;up
	dec bh
.ELSEIF AH == 50h ;down
	inc bh
.ELSEIF AH == 4Bh ;left
	dec bl
.ELSEIF AH == 4Dh ;right
	inc bl
.ELSEIF AH ==8Dh   ;^up
	dec bh
	inc bl
.ELSEIF AH == 91h  ; ^down
	dec bl
	inc bh
.ELSEIF AH == 73h  ;^left
	dec bl
	dec bh
.ELSEIF AH == 74h  ; ^right
	inc bl
	inc bh
.ELSEIF AH == 47h  ;home
	mov bl,StartX
	mov bh,StartY
.ELSEIF AL == 1Bh   ;esc
	stc
.ELSEIF AH == 3Bh   ;F1
	call ToggleHelp
.ELSE				;clear CF
	clc
.ENDIF

ret
ProcessKey ENDP

;------------------------------------------------------
ToggleHelp PROC
; Turns on/off the help text when F1 pressed
;------------------------------------------------------
.data
str2 byte "1. Directly use four arrow keys for Up, Right, Down, Left.",0dh,0ah
     byte "2. ^Up: Up-Right, ^Right: Down-Right, ^Down: Down-Left, ^Left: Up-Left.",0dh,0ah
     byte "3. Home: back to center. ESC: Exit. F1: Toggle Help Text.",0
count = ($-str2)
toggle byte 1
strhide byte "Press the F1 key for help...",count dup(0ffh),0   ; fill the rest with blank to write over previous string
.code

.IF toggle == 1
	mov edx,offset str2
	call WriteString
	mov toggle,0
.ELSE
	mov edx,offset strhide
	call WriteString
	mov toggle,1
.ENDIF
ret
ToggleHelp ENDP

END main3
