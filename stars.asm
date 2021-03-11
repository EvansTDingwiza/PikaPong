; #########################################################################
;
;   stars.asm - Assembly file for CompEng205 Assignment 1
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive


include stars.inc

.DATA

	;; If you need to, you can place global variables here

.CODE

DrawStarField proc
      ;;this code draws 2 vertical lines 
	invoke DrawStar, 150, 200 ;; draw a star at x, y
      invoke DrawStar, 150, 210;;
      invoke DrawStar, 150, 220;;
      invoke DrawStar, 150, 230;;
      invoke DrawStar, 150, 240;;
      invoke DrawStar, 150, 250;;
      invoke DrawStar, 150, 260;;
      invoke DrawStar, 150, 270;;
      invoke DrawStar, 150, 280;;
      invoke DrawStar, 150, 290;;
      invoke DrawStar, 150, 300;;
      invoke DrawStar, 150, 310;;
      invoke DrawStar, 150, 320;;
      invoke DrawStar, 150, 330;;
      invoke DrawStar, 150, 340;;
      invoke DrawStar, 150, 350;;
      invoke DrawStar, 150, 360;;
      invoke DrawStar, 150, 310;;
      invoke DrawStar, 150, 320;;
      invoke DrawStar, 150, 330;;
      invoke DrawStar, 150, 340;;
      invoke DrawStar, 150, 350;;
      invoke DrawStar, 150, 360;;
      invoke DrawStar, 150, 300;;
      invoke DrawStar, 150, 310;;
      invoke DrawStar, 150, 320;;
      invoke DrawStar, 150, 330;;
      invoke DrawStar, 150, 340;;
      invoke DrawStar, 150, 350;;
      invoke DrawStar, 150, 360;;
      invoke DrawStar, 150, 310;;
      invoke DrawStar, 150, 320;;
      invoke DrawStar, 150, 330;;
      invoke DrawStar, 150, 340;;
      invoke DrawStar, 150, 350;;
      invoke DrawStar, 150, 360;;

      ;; drawing the second line
      invoke DrawStar, 160, 210;;
      invoke DrawStar, 160, 220;;
      invoke DrawStar, 160, 230;;
      invoke DrawStar, 160, 240;;
      invoke DrawStar, 160, 250;;
      invoke DrawStar, 160, 260;;
      invoke DrawStar, 160, 270;;
      invoke DrawStar, 160, 280;;
      invoke DrawStar, 160, 290;;
      invoke DrawStar, 160, 300;;
      invoke DrawStar, 160, 310;;
      invoke DrawStar, 160, 320;;
      invoke DrawStar, 160, 330;;
      invoke DrawStar, 160, 340;;
      invoke DrawStar, 160, 350;;
      invoke DrawStar, 160, 360;;
      invoke DrawStar, 160, 310;;
      invoke DrawStar, 160, 320;;
      invoke DrawStar, 160, 330;;
      invoke DrawStar, 160, 340;;
      invoke DrawStar, 160, 350;;
      invoke DrawStar, 160, 360;;
      invoke DrawStar, 160, 300;;
      invoke DrawStar, 160, 310;;
      invoke DrawStar, 160, 320;;
      invoke DrawStar, 160, 330;;
      invoke DrawStar, 160, 340;;
      invoke DrawStar, 160, 350;;
      invoke DrawStar, 160, 360;;
      invoke DrawStar, 160, 310;;
      invoke DrawStar, 160, 320;;
      invoke DrawStar, 160, 330;;
      invoke DrawStar, 160, 340;;
      invoke DrawStar, 160, 350;;
      invoke DrawStar, 160, 360;;




	ret  			; Careful! Don't remove this line
DrawStarField endp



END
