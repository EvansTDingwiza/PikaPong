; #########################################################################
;
;   trig.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include trig.inc

.DATA

;;  These are some useful constants (fixed point values that correspond to important angles)
PI_HALF = 102943           	;;  PI / 2
PI =  205887	                ;;  PI 
TWO_PI	= 411774                ;;  2 * PI 
PI_INC_RECIP =  5340353        	;;  Use reciprocal to find the table entry for a given angle
	                        ;;              (It is easier to use than divison would be)


	;; If you need to, you can place global variables here
	
.CODE


;; helper that finds a sign value
TrueSin Proc USES ebx edx angle:FXPT
	
	;;LOCAL signval: WORD

	;;mov FXPT, 1   
	;;dealing with angles 0->pi/2


	;;mov ebx, angle;;
	xor eax, eax    
	xor edx, edx                           ;; clear edx
	mov eax, angle                         ;; put the angle in ebx
	mov ebx, PI_INC_RECIP                  ;; store 256/pi 
	mul ebx                                ;; [angle * 256/pi]
	mov cx, WORD PTR [SINTAB + edx*2]      ;; 2 bytes since its D word-> not sure why 4 seems to work best here
	movzx eax, cx                          ;; signval = SINTAB[index]

	ret   ;; return here
TrueSin ENDP


;;fixes the angle that is past pi 
FixAngle Proc USES ecx angle:FXPT
		;;angle is past pi reduce to within range
	
		mov ecx, angle     ;; move angle into exc
		;;xor ebx, ebx     ;; make this zero
							;;while the angle > 2pi == angle - 2pi
		jmp EvalsWhile    ;; 
	BodyofWhile:
		sub ecx, TWO_PI   ;; subtract angle - 2PI
	EvalsWhile:
		cmp ecx, TWO_PI  ;; check if this is > 2PI
		jge BodyofWhile   ;; repeat
		mov eax, ecx     ;; put into the return reg

	ret ;;
FixAngle ENDP

FixedSin PROC USES edx ebx ecx angle:FXPT 
	
		LOCAL Tempangle:DWORD, Result:DWORD, Quadrant:DWORD, sign:DWORD

		mov edx, angle;;
		;;check if it is below zero
		mov sign, 0;; init sign to be positive
		cmp edx, 0;;
		jge PositiveEval ;; if it is positive just do the job
		mov sign, 1 ;; turn on the flag
		xor ecx, ecx ;;
		sub ecx, edx ;; set to absolute value
		mov edx, ecx ;; change the angle to positive


	PositiveEval:
		mov Tempangle, edx ;;   make the angle into temp angle

		;;mov Tempangle, 634 ;; try with 634
		xor edx, edx ;;

		;;mov Tempangle, 360302;; past pi/2
		mov ebx, Tempangle ;; store the angle
		
		mov Quadrant, 1 ;; in the first quadrant

	CheckPast2Pi:
	;; the angle is past pi
		cmp ebx, TWO_PI         ;; remove the two pi
		jl FirstQuad            ;; no need to fix if it is less
		invoke FixAngle, Tempangle   ;; find the sin of angle - 2pi
		mov ebx, eax            ;; get the corrected angle

FirstQuad:
		cmp ebx, PI_HALF ;;
		jg CheckSecondQ ;;
	    mov Tempangle, ebx	;;		   ;; angle is in the first quadrant
		invoke TrueSin, Tempangle      ;; find the sin of the angle
		                            ;; if quad == 2, negate the result
		cmp Quadrant, 2 ;;
		jne Pastallchecks;;
		neg eax ;; negate the result
		jmp Pastallchecks ;;

CheckSecondQ:
	;;if its < PI and past PI/2 subtract find pi - angle

		cmp ebx, PI ;;
		jge CheckPastSecondQ ;;
		mov ecx, PI   ;; store pi
		sub ecx, ebx ;; find pi - x
		mov Tempangle, ecx ;; assign tempange = pi - x
		invoke TrueSin, Tempangle

		;; if we are past 180, then negate the result
		cmp Quadrant, 2 ;;
		jne Pastallchecks;;
		neg eax ;; negate the result
		jmp Pastallchecks ;; 
	
CheckPastSecondQ:
		mov Quadrant, 2       ;; past 180
		sub ebx, PI          ;; remove the PI and leave x
		                      ;;mov Tempangle, ebx;; change the value of tempangle
		jmp FirstQuad       ;; go do the evaluation

	;; the third quadrant and the 4th quadrant

	

	Pastallchecks:
		cmp sign, 1 ;; check if the angle was negative
		jne Doneall;; if not then it was positive then just return
		neg eax  ;; negate the result => sin(-x) = -sin(x)

	Doneall:

		


		ret			; Don't delete this line!!!
	FixedSin ENDP 
	
FixedCos PROC USES ebx ecx angle:FXPT

	LOCAL Tempval:DWORD
	;;mov eax, 10000h         ; Replace this with your own crazy code

	;; if angle is negative, turn it to positive


	mov ebx, angle;;
	cmp ebx, 0 ;;
	jge Positive ;; if positive just go to the evaluation
	xor ecx, ecx ;; make this zero
	sub ecx, ebx ;; get the absolute value
	mov ebx, ecx ;; change to positive and carry on

Positive:
	add ebx, PI_HALF ;; x + pi/2
	mov Tempval, ebx ;; tempval = x + pi/2
	invoke FixedSin, Tempval ;; find the cosine

	ret			; Don't delete this line!!!	
FixedCos ENDP	
END
