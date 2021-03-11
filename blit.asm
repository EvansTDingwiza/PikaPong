; #########################################################################
;
;   blit.asm - Assembly file for CompEng205 Assignment 3
;
;
; #########################################################################

      .586
      .MODEL FLAT,STDCALL
      .STACK 4096
      option casemap :none  ; case sensitive

include stars.inc
include lines.inc
include trig.inc
include blit.inc
include game.inc

.DATA

	;; If you need to, you can place global variables here
	
.CODE

DrawPixel PROC USES ebx ecx eax x:DWORD, y:DWORD, color:DWORD  
	;; check if x or y are out of bounds

	;;LOCAL Colr:DWORD  ;;, Xoffset:DWORD
	mov ebx, x ;; mov x into a register edx
	mov ecx, y ;; mov y into reg ecy

	cmp ebx, 639 ;; check if [x,y] x is within bounds [0 -> 639]
	jg Restofcode;;
	cmp ebx, 0 ;;
	jl Restofcode ;;

	;;check for y
	cmp ecx, 479 ;; check if [x,y] y is within bounds [0->479]
	jg Restofcode ;;
	cmp ecx, 0 ;;
	jl Restofcode ;;

	;; do the operation here
	
	imul ecx, 640 ;; find y*640 bytes
	add ecx, ebx ;; get the total offset
	mov eax, color ;; set edi to color

	mov ebx, [ScreenBitsPtr] ;; move the ptr into a register
	mov Byte PTR [ebx + ecx], al ;; assign color to arr + y*640 bytes + x byte

Restofcode:

	ret 			; Don't delete this line!!!
DrawPixel ENDP


;;checks if [x,y] is/not one of the transparent pixel by looping and comparing with point in 
;;btransparency
;;CheckTransparency Proc ptrBitmap:PTR EECS205BITMAP , x:DWORD, y:DWORD
;;give it the ptr to the ptrBitmap: to the background bitmap

Clearprev Proc USES edi edx ebx ecx esi eax ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	;; this function is called to clear the previos thing at a position
	;; no need to clear the whole screen
	LOCAL orgx:DWORD, startx:DWORD, starty:DWORD, colorforpoint:DWORD, yoffset:DWORD, bitmapwidth:DWORD, bitmapheight:DWORD

	mov edi, xcenter ;;
	mov startx, edi ;; x and y are coords on the screen
	mov edi, ycenter ;;
	mov starty, edi ;; 

	mov edx, [ptrBitmap] ;; move the address pointed to into edx
	mov ebx, (EECS205BITMAP PTR [edx]).dwWidth   ;; get the width
	mov edi, (EECS205BITMAP PTR [edx]).dwHeight   ;; get the hieght 
	mov bitmapwidth, ebx ;;
	mov bitmapheight, edi ;;

	;; find the start of the map
	shr ebx, 1  ;; devide the height and width by 2 
	shr edi, 1 ;;

	sub startx, ebx ;; x-wdth/2
	mov ebx, startx ;;
	mov orgx, ebx ;; the original start x
	sub starty, edi ;; y-hght/2

	xor edi, edi ;; clear edi
	;;xor ebx, ebx ;; clear ebx

	;; loop throught the whole bitmap
	;; while starty < dwhght
	;;    while starty < dwWdth

	xor ecx, ecx ;; for the ybitmap
	xor ebx, ebx ;; for the xbitmap

	jmp EvalOutsideloop;;
Bodyofouter:

		xor ebx, ebx ;; x= 0--> get back to the start
		jmp EvalofInner ;; this is the loop for the width

	BodyofInner:
		

		mov eax, starty ;; prepare for mul 
		imul eax, ScreenBack.dwWidth                ;; three reg mul, ybitmap*dwidth
		add eax, startx                                  ;; this is the ybitoffset
		mov esi, eax ;; add the x offset
		;;shl yoffset, 1
		xor eax, eax ;;

		mov edi, ScreenBack.lpBytes ;; move the address of IpBytes
		;;mov esi, starty ;; 
		mov al, Byte PTR [edi +  esi] ;; get what is at the location
		movsx eax, al ;; do the thing
		mov colorforpoint, eax ;; assign the color
		
		;;get the pixel at a point if it is withing the 
		invoke DrawPixel, startx, starty, colorforpoint    ;; draw this pixel if in screen range
		                                ;;increment startx

	Increments:
		inc ebx;; increment xbitmap
		add startx, 1 ;; move x val

	EvalofInner:
		
		cmp ebx, bitmapwidth ;; check if we are still within the width of the map
		jl BodyofInner ;; go back

	;;increment starty
	mov ebx, orgx ;; reinit begin
	mov startx, ebx;; reinit xval
	add starty, 1 ;; increment this too
	inc ecx ;; increment ybitmap
EvalOutsideloop:
	cmp ecx, bitmapheight ;;check if we reached the end of the bitmap
	jl Bodyofouter  
	

	ret 			; Don't delete this line!!!	
Clearprev ENDP
	

	

BasicBlit PROC USES edi edx ebx ecx esi eax ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	
	LOCAL orgx:DWORD, startx:DWORD, starty:DWORD, colorforpoint:DWORD, yoffset:DWORD, bitmapwidth:DWORD, bitmapheight:DWORD

	mov edi, xcenter ;;
	mov startx, edi ;; x and y are coords on the screen
	mov edi, ycenter ;;
	mov starty, edi ;; 

	mov edx, [ptrBitmap] ;; move the address pointed to into edx
	mov ebx, (EECS205BITMAP PTR [edx]).dwWidth   ;; get the width
	mov edi, (EECS205BITMAP PTR [edx]).dwHeight   ;; get the hieght 
	mov bitmapwidth, ebx ;;
	mov bitmapheight, edi ;;

	;; find the start of the map
	shr ebx, 1  ;; devide the height and width by 2 
	shr edi, 1 ;;

	sub startx, ebx ;; x-wdth/2
	mov ebx, startx ;;
	mov orgx, ebx ;; the original start x
	sub starty, edi ;; y-hght/2

	xor edi, edi ;; clear edi
	;;xor ebx, ebx ;; clear ebx

	;; loop throught the whole bitmap
	;; while starty < dwhght
	;;    while starty < dwWdth

	xor ecx, ecx ;; for the ybitmap
	xor ebx, ebx ;; for the xbitmap

	jmp EvalOutsideloop;;
Bodyofouter:

		xor ebx, ebx ;; x= 0--> get back to the start
		jmp EvalofInner ;; this is the loop for the width

	BodyofInner:
		
		
		mov eax, ecx ;; prepare for mul
		imul eax, bitmapwidth              ;; three reg mul, ybitmap*dwidth
		
		mov yoffset, eax                                       ;; this is the ybitoffset
		add yoffset, ebx   ;; add the x offset
		;;shl yoffset, 1
		xor eax, eax ;;
		mov edi, (EECS205BITMAP PTR [edx]).lpBytes ;; move the address of IpBytes

		mov esi, yoffset ;; 
		mov al, Byte PTR [edi +  esi] ;; get what is at the location
		movsx eax, al ;; do the thing
		mov colorforpoint, eax ;; assign the color

		xor eax, eax ;;
		mov al, (EECS205BITMAP PTR [edx]).bTransparent
		movsx eax, al;;
		cmp eax, colorforpoint           ;; check if it is a transparent color
		
		
		jne NoAdjustment                      ;; do the increments, do not draw anything at this point

		mov eax, starty ;; prepare for mul 
		imul eax, ScreenBack.dwWidth                ;; three reg mul, ybitmap*dwidth
		add eax, startx                                  ;; this is the ybitoffset
		mov esi, eax ;; add the x offset
		;;shl yoffset, 1
		xor eax, eax ;;

		mov edi, ScreenBack.lpBytes ;; move the address of IpBytes
		;;mov esi, starty ;; 
		mov al, Byte PTR [edi +  esi] ;; get what is at the location
		movsx eax, al ;; do the thing
		mov colorforpoint, eax ;; assign the color


NoAdjustment:                                   ;;check if it is not transparent
		invoke DrawPixel, startx, starty, colorforpoint    ;; draw this pixel if in screen range
		                                ;;increment startx

	Increments:
		inc ebx;; increment xbitmap
		add startx, 1 ;; move x val

	EvalofInner:
		
		cmp ebx, bitmapwidth ;; check if we are still within the width of the map
		jl BodyofInner ;; go back

	;;increment starty
	mov ebx, orgx ;; reinit begin
	mov startx, ebx;; reinit xval
	add starty, 1 ;; increment this too
	inc ecx ;; increment ybitmap
EvalOutsideloop:
	cmp ecx, bitmapheight ;;check if we reached the end of the bitmap
	jl Bodyofouter  
	

	ret 			; Don't delete this line!!!	
BasicBlit ENDP


RotateBlit PROC USES ebx eax ecx edi esi lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT
	
	LOCAL cosa:DWORD, sina:DWORD, shiftX:DWORD, shiftY:DWORD, dstWidth:DWORD, dstHeight:DWORD, srcX:DWORD, srcY:DWORD, colorpixel:DWORD, x:DWORD, y:DWORD;;, Testangle:DWORD

	;;mov Testangle, 726fch;; test angle 

	invoke FixedCos, angle ;; call cosine(angle)
	mov cosa, eax;; cosa => eax, return reg

	invoke FixedSin, angle;; call sin(angle)
	mov sina, eax;; sina => eax, return reg

	mov esi, [lpBmp] ;; move the address pointed to into edx

	;;find shiftX fixedpoint
	mov ebx, (EECS205BITMAP PTR [esi]).dwWidth ;; store the value 
	shl ebx, 16 ;; change this val to fixed point

	mov ecx, cosa ;; store the cosine value here
	sar ecx, 1 ;; cosine(x)/2

	mov eax, ebx  ;;
	imul ecx ;; dwidth * cosine(x)*2

	;;intermediate move result to shiftX
	;;can use all registers at this 
	mov shiftX, edx  ;;

	mov edi, (EECS205BITMAP PTR [esi]).dwHeight ;; 
	shl edi, 16     ;; change to fixed point


	mov ecx, sina   ;; store the val of cos
	sar ecx, 1 ;; sin(x)/2

	mov eax, edi    ;; move the widtth here
	imul ecx   ;; dwHeight* sin(x)/2

	                               ;;buggy because shiftX is 2^16
	;;sar eax, 16 ;; move back to int
	sub shiftX, edx ;; find the fixed point value of shiftX
	mov eax, shiftX ;;

	;;
	;;sar shiftX, 32  ;; turn this back to int
	

	;;find shiftY fixed point
	mov ebx, (EECS205BITMAP PTR [esi]).dwHeight ;; 
	shl ebx, 16         ;; change to fixed point

	mov ecx, cosa       ;; store the cosine value here
	sar ecx, 1         ;; cosine(x)/2

	mov eax, ebx      ;; 
	imul ecx          ;; dwidth * cosine(x)*2

	mov shiftY, edx    ;;

	mov edi, (EECS205BITMAP PTR [esi]).dwWidth ;; 
	shl edi, 16     ;; change to fixed point already been done

	mov ecx, sina   ;; store the val of cos
	sar ecx, 1      ;; sin(x)/2

	mov eax, edi    ;; move the widtth here
	imul ecx   ;; dwHeight* sin(x)/2

	add shiftY, edx ;; find the fixed point value of shiftY
	mov eax, shiftY ;;
	;;sar shiftY, 16 ;; make shiftY an interger again

	;;find dstWidth
	mov edi, (EECS205BITMAP PTR [esi]).dwWidth;;
	mov ebx, (EECS205BITMAP PTR [esi]).dwHeight;; 

	add edi, ebx ;;
	mov dstWidth, edi ;; assign dstWidth = dwWidth + dwHeight
	mov dstHeight, edi ;; assign dstWidth == dstHeight

	;;do the for loop


	;;dstx ==> ebx 
	;;dsty ==> edi 

	xor ebx, ebx ;; clear
	xor edi, edi ;; clear 

	mov ebx, dstWidth ;; assign ebx to dstWidth

	neg ebx ;; negate - dstWidth
	jmp EvalOuterLoop ;;

BodyOuterLoop:
			;;the inner loop
			mov edi, dstHeight ;; assign to dstHeight
			neg edi ;; change to - dstHeight
			jmp EvalInnerLoop ;;

		BodyInnerLoop:
			
			;;src = dstX*cosa + dstY*sina

			mov eax, ebx ;; load value of dstX
			sal eax, 16  ;; change to fixed point dstX* 2^16
			imul cosa     ;; multiply and put the result in edx 
			mov srcX, edx ;; load the dstX * cosa

			;;find dstY*sina
			mov eax, edi  ;; load the value of dstY
			sal eax , 16  ;; change to fixed point
			imul sina     ;; dstY * sina
			add srcX, edx ;; get dstX * Cosa + dstY*sina fixed point
			mov eax, srcX  ;; for checking purpose

			;;change to int
			;;sar srcX, 16  ;; ----->change to integer

			;;get srcY
			;;find dstY*cosa
			mov eax, edi  ;; load the dstY 
			sal eax, 16   ;; change the value to fixed point 
			imul cosa     ;; dstY*cosa 
			mov srcY, edx ;; move the first piece into srcY

			;;find dstX*sina
			mov eax, ebx  ;; load the value of dstX
			sal eax, 16   ;; change it to fixed point
			imul sina     ;; dstX*sina
			sub srcY, edx ;; dstY*cosa - dstX*sina
			mov eax, srcY;; for checking purpose

			;;change to int
			;;sar srcY, 16 

			;; the big if statement starts here
			cmp srcX, 0 ;; check srcX>= 0
			jl Increment ;; if not skip to increment

			mov edx, (EECS205BITMAP PTR [esi]).dwWidth ;;load dwidth check srcX < dwWidth
			cmp srcX, edx  ;;
			jge Increment  ;; if not skip to increment

			cmp srcY, 0 ;; check srcY >= 0 
			jl Increment ;; if not skip to increment

			mov edx, (EECS205BITMAP PTR [esi]).dwHeight ;; load dHeight srcY < dwHeight
			cmp srcY, edx ;;
			jge Increment     ;;if not jump to increment

			;;check=> xcenter+dstX-shiftX >= 0
			mov edx, xcenter ;; load xcenter into the 
			add edx, ebx   ;; xcenter + dstX
			sub edx, shiftX ;; xcenter + dstX - shiftY

			cmp edx, 0 ;; check xcenter + dstX - shiftY >= 0
			jl Increment ;; if not go to increment

			cmp edx, 639 ;; check xcenter + dstX - shiftX < 639 
			jge Increment ;;

			;;check=> xcenter+dstY-shiftY >= 0
			mov edx, ycenter ;; load ycenter into the reg
			add edx, edi    ;; add ycenter + dstY
			sub edx , shiftY ;; ycenter + dstY - shiftY

			cmp edx, 0 ;; check ycenter + dstY - shiftY >=0
			jl Increment ;; if less jump to increment
			
			cmp edx, 479 ;; check ycenter + dstY - shiftY < 479 
			jge Increment ;; if not go to Increment


			;;check for transparency
			;get the pixel

			mov ecx, srcY ;; get the y value
			imul ecx, (EECS205BITMAP PTR [esi]).dwWidth ;; the offset in the y direction

			;;add the x offset 
			add ecx, srcX ;; srcY*dwWidth + srcX

			mov edx, (EECS205BITMAP PTR [esi]).lpBytes ;; move the address of IpBytes

			mov al, Byte PTR [edx +  ecx] ;; get what is at the location
			movsx eax, al ;;

			mov colorpixel, eax ;; get the pixel at srcX, srcY

			xor eax, eax ;;
			mov al, (EECS205BITMAP PTR [esi]).bTransparent ;; get the transparency value
			movsx eax, al;;

			cmp eax, colorpixel ;; check if colorpixel is transparent
			je Increment ;; if they are equal move to increment

			;;otherwise

			mov ecx, xcenter ;; find xcenter +dstX-shiftX
			add ecx, ebx ;;
			sub ecx, shiftX  ;; remove shiftX
			mov x, ecx ;; assign the x value

			mov ecx, ycenter  ;; find ycenter + dstX -shiftY 
			add ecx, edi ;;
			sub ecx, shiftY ;; remove shiftY 
			mov y, ecx ;; assign the y value 

			
			invoke DrawPixel, x, y, colorpixel  ;; call the function


		Increment:
			inc edi;; dstY++
		EvalInnerLoop:
			cmp edi, dstHeight ;; check dstY < dstHeight
			jl BodyInnerLoop ;;


	inc ebx;; dstx++
EvalOuterLoop:
	 cmp ebx, dstWidth  ;; dstX<dstWidth
	 jl BodyOuterLoop



	
	ret 			; Don't delete this line!!!		
RotateBlit ENDP



END
