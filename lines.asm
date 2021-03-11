; #########################################################################
;
;   lines.asm - Assembly file for CompEng205 Assignment 2
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE
	

;; Don't forget to add the USES the directive here
;;   Place any registers that you modify (either explicitly or implicitly)
;;   into the USES list so that caller's values can be preserved

;;   For example, if your procedure uses only the eax and ebx registers
;;      DrawLine PROC USES eax ebx x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD

;;use any registers besides esp, ebp
DrawLine PROC USES ebx edx eax edi x0:DWORD, y0:DWORD, x1:DWORD, y1:DWORD, color:DWORD
	;; Feel free to use local variables...declare them here
	;; For example:
	;; 	LOCAL foo:DWORD, bar:DWORD
	LOCAL delta_x:DWORD, delta_y:DWORD, inc_x:DWORD, inc_y:DWORD, error:DWORD, curr_x:DWORD, curr_y:DWORD, prev_error:DWORD
	;; Place your code here

	;;mov x0, 50
	;;mov y0, 10
	;;mov x1, 50
	;;mov y1, 20

	mov ebx, x0 ;; change the value of ebx
	mov edx, y0 ;; chang the value of edx

	;;find delta_x and inc_x using if/else block  

	cmp ebx, x1 ;; check if x0 is 
	jb ElseforDx   ;; if x0 is < x1 
	;; x0>x1
	sub ebx, x1 ;;  x0 - x1 = delta_x
	mov delta_x, ebx ;; assign delta_x 
	mov inc_x, -1
	jmp ContinuetoDy

ElseforDx: ;;x1> x0
	mov eax, x1;; change eax, put x1 in it
	sub eax, ebx ;; delta_x = x1 - x0
	mov delta_x, eax ;; assign delta_x
	mov inc_x, 1

ContinuetoDy:
;; y coordinates
	cmp edx, y1 ;; check if y0 > y1
	jb ElseforDy   ;; if false go to else 
	;; y0>y1
	sub edx, y1 ;;  y0 - y1 = delta_y
	mov delta_y, edx ;; assign delta_y
	mov inc_y, -1
	;;test code
	jmp ContinuetoRest1

ElseforDy: ;;y1> y0
	mov edi, y1  ;; change eax, put y1 in it
	sub edi, edx ;; delta_y = x1 - x0
	mov delta_y, edi ;; assign delta_y
	mov inc_y, 1

;;Note all registers can be used at this point, inc_x, inc_y, dx,dy have been assigned in mem
ContinuetoRest1:
	mov edx, delta_x ;; change edx
	mov edi, delta_y ;; change edi
	cmp edx,edi
	jbe Elsedeltygreater
	;; how to devide??
	sar edx, 1       ;;delta/2
	mov error, edx ;;assign error
	jmp ContinuetoRest2

Elsedeltygreater:
	;;mov eax, 0
	;;sub eax, edi;; create  -delta_y
	neg edi ;; get -delta_y
	sar edi, 1;; -delta_y/2
	mov error, edi ;; assign error

ContinuetoRest2:
	mov eax, x0 ;; change eax
	mov edi, y0 ;; change edi
	mov curr_x, eax ;; assign curr_x
	mov curr_y, edi;; assign curr_y

	;;call the color function
	invoke DrawPixel, curr_x, curr_y, color

	;;while loop
	;;put x1 and y1 in registers

	;;mov eax, x1 ;; change eax
	;;mov edi, y1 ;; change edi
	;;two evals 
	jmp Evalwhile1

doforwhile1:
	invoke DrawPixel, curr_x, curr_y, color ;; call the function DrawPixel(curr_x, curr_y, color)
	mov edx, error ;; change edx to error
	mov prev_error, edx ;; assign prev_err = error

	mov ebx, delta_x
	neg ebx ;; get - delta_x
	;; if prev_error > -delta_x
	cmp prev_error, ebx ;; compare them
	jl restpart1 ;; skip if prev_error < -delta_x
	mov eax, delta_y   
	sub error, eax   ;; error = error - delta_y
	mov eax, inc_x
	add curr_x, eax    ;; curr_x = curr_x + inc_x

restpart1:
	mov ebx, delta_y
	cmp prev_error, ebx   ;;if prev_error < delta_y
	jg Evalwhile1  
	mov eax, delta_x
	add error, eax ;; error = error + delta_x
	mov eax, inc_y
	add curr_y, eax  ;; curr_y 

;;restpart2:
Evalwhile1:
	mov eax, curr_x
	cmp eax, x1   ;; curr_x != x1
	jne doforwhile1  ;; go to action parts(loop)
	mov eax, curr_y 
	cmp eax, y1   ;; curr_y != y1
	jne doforwhile1 ;; the or condition 

	ret        	;;  Don't delete this line...you need it
DrawLine ENDP

END
