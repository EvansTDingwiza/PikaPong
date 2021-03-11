; #########################################################################
;
;   game.asm - Assembly file for CompEng205 Assignment 4/5
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

include windows.inc
include winmm.inc
includelib winmm.lib
includelib masm32.lib ;;masm32.lib
include masm32.inc
include user32.inc
includelib user32.lib

;; Has keycodes
include keys.inc

	
.DATA


gamestate struct

	playpause BYTE 0
	explDuration DWORD 05h ;;the delay between explosion transitions
	blastDelay DWORD  0h  ;;the delay between successive blasts
	Rockspeed   DWORD ?
	NumberRocks DWORD ?
	GameOver    DWORD ?
	ProjTimer DWORD 0 ;;this is the timer for the projectile
						;;starts of as zero
	Gravity    DWORD 131072;;fixed point 
	CreationTimer DWORD 5 ;; create the rock after some time
	gamescore DWORD ? ;;this is a function of time, inc for every t/10
	gametime DWORD 0 ;;this is the timer for the whole game
	score DWORD 0 ;;this is the score displayed on the screen

gamestate ENDS

newgame gamestate<>

;;the template for a ball
ballobject struct 
;; this is the ball object, that has the state of pikachu
	ballxpos DWORD ?  ;;the xcenter of the ball
	ballypos DWORD ?  ;; the ycenter of the ball
	ballangle DWORD ?  ;; if the angle rotates
	ballptr DWORD ?
	ballstate BYTE 10  ;;  b1 set => vertical, 0 ==> moving down ,,b2 =>set North, 0=>south b3 set => east, unset => west
	;;ball starts off moving down

	BallV   DWORD  0    ;;the intial velocity of the ball     ;;b1 b
	Theta DWORD 102943    ;;the ball is falling down 
	BallVx   DWORD  ?  ;;VcosTheta
	BallVy   DWORD ?    ;;VsinTheta
	Timer    DWORD 0

ballobject ENDS

;;the template for pikachu
Pikaobject struct
	;; this is the pika object that has the state of pikachu
	pikaxpos DWORD ? ;; the xcenter
	pikaypos DWORD ?  ;; the ycenter
	pikaangle DWORD ?  ;; the angle if pika rotates
	pikaptr DWORD ?  ;; maybe if we have other bitmaps for pika
	pikastates BYTE 0h
	;; pika states b1=> 0 stationery b1=> 1 jump  b2 => 0 up b2=> 1 => down 
	;;b3 => 0, facing right ;; 1 facing left

	Life BYTE 11111b    ;;4 bits from 1111 => 4 lives
					;;game over at 0000
	turnDuration DWORD 0h ;; this is supposed to make turning smooth

Pikaobject ENDS


rockobject struct 

	rockxpos DWORD ?
	rockypos DWORD ?
	rockangle DWORD ?
	rockvelocity DWORD ?
	rockstates Byte 0   ;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	RockexplD DWORD 03h

	rockbitmaps DWORD OFFSET rock, OFFSET Explosion1, OFFSET Explosion2, OFFSET Explosion3, OFFSET Explosion4;; this is an array of pointers corresponding to the bitmaps to draw when the 
	;;the rock is in a particular state

rockobject ENDS

fireblast struct 

	fireblastxpos DWORD ?
	fireblastypos DWORD ?
	fireblastvelocity DWORD ?
	fireblaststates Byte 0    ;;b1 => 1 active, b1 => 0 inactive
	fireblastptr DWORD ?

fireblast ENDS

;;make a ball instance
ballA ballobject <> ;; 
ballB ballobject <> ;; init two ball objects
Pikachu Pikaobject <> ;; init a pickachu object

;;put these in a list 
;;pikachu can fire a maximum of 5 fireballs at any frame
;;go through the list, return a pointer to the inactive fireball
;;modify that, when it gets to the end dectivate it 
;; use 1 for now and submit
Rock1 rockobject <>
Fire1 fireblast <>

rockobject struct 

	rockxpos DWORD ?
	rockypos DWORD ?
	rockangle DWORD ?
	rockvelocity DWORD ?
	rockstates Byte 0   ;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	RockexplD DWORD 03h

	rockbitmaps DWORD OFFSET rock, OFFSET Explosion1, OFFSET Explosion2, OFFSET Explosion3, OFFSET Explosion4;; this is an array of pointers corresponding to the bitmaps to draw when the 
	;;the rock is in a particular state

rockobject ENDS
RockArr  rockobject < 30, 100 , ? , 0 , 1000000b > , < 400, 75, ?, 0, 1000000b > ,< 150, 250, ?, 0, 1000000b > ,<?, ?, ?, 0, ? > ,<?, ?, ?, 0, ? > ,< 450, 180, ?, 0, 1000000b > ,<?, ?, ?, 0, ? > ,<?, ?, ?, 0, ? > ,<?, ?, ?, 0, ? > 
FireArr fireblast <>, <>, <>, <>, <> ;; assume it inits to default
ExplosionPath BYTE "Explosion+3.wav", 0
BlastPath  Byte "cannon_x.wav", 0

PikaShock Byte "electricshock.wav", 0
newgameDrums Byte "Cymbal_Groove.wav", 0
;;going to create an array of rocks 
;;active rocks instanciated 
;;can do the same for rocks


;;creating bounding box objects for checking intersections
Pos Struct 
	x DWORD ?
	y DWORD ?
Pos Ends

;;conner Pos <>
Box Struct 
	Tlc Pos <?,?>
	Trc Pos <?,?> 
	Blc Pos <?,?>
	Brc Pos <?,?>
Box ENDS

Boxone Box <>
Boxtwo Box <>
;;
fmtStr Byte "Score: %d", 0
outStr Byte 256 DUP(0)

.CODE

;; might need a way to calculate the trajectory of things (vertical)

CheckIntersect Proc USES ebx ecx edi edx oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP
      
	  LOCAL Width1:DWORD, Height1:DWORD, Width2:DWORD, Height2:DWORD
	  ;; check for the intersection of sprites
	  ;; bounding box A <> bounding box b
	  ;; coords are the centers of sprites

	
	mov ebx, oneBitmap
	mov ecx, (EECS205BITMAP PTR [ebx]).dwWidth   ;; get the width
	mov edi, (EECS205BITMAP PTR [ebx]).dwHeight   ;; get the hieght 
	mov Width1, ecx ;;
	sub Width1, 10
	mov Height1, edi ;;
	sub Height1, 10
	
	;;TL
	mov ebx, Width1
	shr ebx, 1 ;; width/ 2
	mov edx, oneX
	sub edx, ebx  ;;x - width/2
	mov Boxone.Tlc.x, edx 
	
	mov edx, oneY
	mov edi, Height1 ;; get the height
	shr edi, 1
	sub edx, edi ;; y - height/2
	mov Boxone.Tlc.y, edx
	;;TR
	mov ebx,Width1
	shr ebx, 1 ;; width/ 2
	mov edx, oneX
	add edx, ebx  ;;x + width/2
	mov Boxone.Trc.x, edx 
	mov edx, oneY
	mov edi, Height1 ;; get the height
	shr edi, 1
	sub edx, edi ;; y - height/2
	mov Boxone.Trc.y, edx
	;;BL
	mov ebx, Width1
	shr ebx, 1 ;; width/ 2
	mov edx, oneX
	sub edx, ebx  ;;x - width/2
	mov Boxone.Blc.x, edx 
	mov edx, oneY
	mov edi, Height1 ;; get the height
	shr edi, 1
	add edx, edi ;; y + height/2
	mov Boxone.Blc.y, edx
	;;BR
	mov ebx, Width1
	shr ebx, 1 ;; width/ 2
	mov edx, oneX
	add edx, ebx  ;;x + width/2
	mov Boxone.Brc.x, edx 
	mov edx, oneY
	mov edi, Height1 ;; get the height
	shr edi, 1
	add edx, edi ;; y + height/2
	mov Boxone.Brc.y, edx
	
	;;instantiate box 1


	mov ebx, twoBitmap
	mov ecx, (EECS205BITMAP PTR [ebx]).dwWidth   ;; get the width
	mov edi, (EECS205BITMAP PTR [ebx]).dwHeight   ;; get the hieght 
	mov Width2, ecx ;;
	sub Width2, 10
	mov Height2, edi ;;
	sub Height2, 10

	;;TL
	mov ebx, Width2
	shr ebx, 1 ;; width/ 2
	mov edx, twoX
	sub edx, ebx  ;;x - width/2
	mov Boxtwo.Tlc.x, edx 
	mov edx, twoY
	mov edi, Height2 ;; get the height
	shr edi, 1
	sub edx, edi ;; y - height/2
	mov Boxtwo.Tlc.y, edx
	;;TR
	mov ebx, Width2
	shr ebx, 1 ;; width/ 2
	mov edx, twoX
	add edx, ebx  ;;x + width/2
	mov Boxtwo.Trc.x, edx 
	mov edx, twoY
	mov edi, Height2 ;; get the height
	shr edi, 1
	sub edx, edi ;; y - height/2
	mov Boxtwo.Trc.y, edx
	;;BL
	mov ebx, Width2
	shr ebx, 1 ;; width/ 2
	mov edx, twoX
	sub edx, ebx  ;;x - width/2
	mov Boxtwo.Blc.x, edx 
	mov edx, twoY
	mov edi, Height2 ;; get the height
	shr edi, 1
	add edx, edi ;; y + height/2
	mov Boxtwo.Blc.y, edx
	;;BR
	mov ebx, Width2
	shr ebx, 1 ;; width/ 2
	mov edx, twoX
	add edx, ebx  ;;x + width/2
	mov Boxtwo.Brc.x, edx 
	mov edx, twoY
	mov edi, Height2 ;; get the height
	shr edi, 1
	add edx, edi ;; y + height/2
	mov Boxtwo.Brc.y, edx
	
xor eax, eax  ;; eax is zero to start with
	;; intersections 
	;;different situations, s1->s4
S1:
	mov edx, Boxtwo.Tlc.x 
	cmp Boxone.Trc.x, edx 
	jl S2
	mov edx, Boxtwo.Trc.x
	cmp Boxone.Trc.x, edx
	jg S2

	;;===>
S1cmp1:
	mov edx, Boxtwo.Tlc.y
	cmp Boxone.Trc.y, edx
	jl S1cmp2 
	mov edx, Boxtwo.Blc.y
	cmp Boxone.Trc.y, edx
	jg S1cmp2
	mov eax, 01b ;; there is an intersection
	jmp PastAllchecks

S1cmp2:
	mov edx, Boxtwo.Blc.y
	cmp Boxone.Brc.y, edx
	jg S2
	mov edx, Boxtwo.Tlc.y
	cmp Boxone.Brc.y, edx
	jl S2
	mov eax, 01b ;; there is an intersection
	jmp PastAllchecks

S2:
	mov edx, Boxtwo.Tlc.y
	cmp Boxone.Blc.y, edx 
	jl S3
	mov edx, Boxtwo.Blc.y
	cmp Boxone.Blc.y, edx
	jg S3
	;;8 j  yuuy uy   
	;;===>
S2cmp1:
	mov edx, Boxtwo.Trc.x
	cmp Boxone.Blc.x, edx
	jg S2cmp2 
	mov edx, Boxtwo.Tlc.x
	cmp Boxone.Blc.x, edx
	jl S2cmp2
	mov eax, 10b ;; there is an intersection
	jmp PastAllchecks

S2cmp2:
	mov edx, Boxtwo.Trc.x
	cmp Boxone.Brc.x, edx
	jg S3
	mov edx, Boxtwo.Tlc.x
	cmp Boxone.Brc.x, edx
	jl S3
	mov eax, 10b ;; there is an intersection
	jmp PastAllchecks

S3:
	mov edx, Boxtwo.Tlc.x 
	cmp Boxone.Trc.x, edx 
	jl S4
	mov edx, Boxtwo.Trc.x
	cmp Boxone.Tlc.x, edx
	jg S4

	;;===>
S3cmp1:
	mov edx, Boxtwo.Trc.y
	cmp Boxone.Tlc.y, edx
	jl S3cmp2 
	mov edx, Boxtwo.Brc.y
	cmp Boxone.Tlc.y, edx
	jg S3cmp2
	mov eax, 11b ;; there is an intersection
	jmp PastAllchecks

S3cmp2:
	mov edx, Boxtwo.Brc.y
	cmp Boxone.Blc.y, edx
	jg S4
	mov edx, Boxtwo.Trc.y
	cmp Boxone.Blc.y, edx
	jl S4
	mov eax, 11b ;; there is an intersection
	jmp PastAllchecks

S4:
	mov edx, Boxtwo.Blc.y
	cmp Boxone.Tlc.y, edx 
	jg PastAllchecks
	mov edx, Boxtwo.Tlc.y
	mov ecx, Boxone.Tlc.y
	cmp Boxone.Tlc.y, edx
	jl PastAllchecks

	;;===>
S4cmp1:
	mov edx, Boxtwo.Blc.x
	cmp Boxone.Tlc.x, edx
	jl S4cmp2 
	mov edx, Boxtwo.Brc.x
	cmp Boxone.Tlc.x, edx
	jg S4cmp2
	mov eax, 100b ;; there is an intersection
	jmp PastAllchecks

S4cmp2:
	mov edx, Boxtwo.Brc.x
	cmp Boxone.Trc.x, edx
	jg PastAllchecks
	mov edx, Boxtwo.Blc.x
	cmp Boxone.Trc.x, edx
	jl PastAllchecks
	mov eax, 100b ;; there is an intersection
	;;jmp PastAllchecks

PastAllchecks:

      ret
CheckIntersect ENDP
;; Note: You will need to implement CheckIntersect!!!

GameInit PROC USES ecx edi ebx eax
	;; the one called at the beginning to initialize stuff
	LOCAL ptrPika:PTR	EECS205BITMAP, initxPika:DWORD, inityPika:DWORD, ptrballA:PTR EECS205BitMAP, inityballA:DWORD, initxballA:DWORD, x:DWORD, y:DWORD
	
	rdtsc
	invoke nseed , eax
	;;pikachu at the bottom
	;; the ball in the sky

	;;invoke PlaySound, offset newgameDrums, 0, SND_FILENAME OR SND_ASYNC 
	mov ecx, 320
	mov edi, 230
	mov ebx, OFFSET ScreenBack
	invoke	BasicBlit, ebx , ecx, edi
	;;mov ecx, 1 
	;; init pika position 
	mov ecx, OFFSET Pikachu ;; load the address of pika
	mov (Pikaobject PTR [ecx]).pikaxpos, 300 ;; init the pos to 200
	mov (Pikaobject PTR [ecx]).pikaypos, 385 ;; init the pos to 200
	mov  edi, OFFSET pikaright;; load the address of pika bitmap
	mov (Pikaobject PTR [ecx]).pikaptr, edi ;; load the address of the bitmap

	;;init ball position
	mov edx, OFFSET ballA ;; load the address of ballA
	mov (ballobject PTR [edx]).ballxpos , 300 ;; above pika
	mov (ballobject PTR [edx]).ballypos , 50  ;; above pika
	mov edi, OFFSET pball ;; load the address to the ball bitmap
	mov (ballobject PTR [edx]).ballptr, edi ;; load the address to the ballbitmap
	mov (ballobject PTR [edx]).ballangle, -200000000 ;; the ball is 0 rotated

	;; =====================> this is only for now, we will need to activate rocks at different times 
	;;init the rock at the opposite end of the screen
	;;go through the list of all the rocks and render the active ones
StationeryRocks:

;;loop starts here
;;i ==> edi
xor edi, edi
jmp ForStationeryRockEval

ForStationerybody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	;;;;check for an active rock
	test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementLOOP1;;if not
	;;test (rockobject PTR [RockArr + edi]).rockstates, 01h  ;; rock already exploding
	;;jnz IncrementLOOP

	mov ebx,  (rockobject PTR [RockArr + edi]).rockbitmaps ;;
	mov ptrPika, ebx
	mov ebx,(rockobject PTR [RockArr + edi]).rockxpos
	mov x, ebx 
	mov ebx,(rockobject PTR [RockArr + edi]).rockypos
	mov y, ebx

	invoke	BasicBlit, ptrPika , x , y 
	
IncrementLOOP1:
	add edi, TYPE RockArr
	
ForStationeryRockEval:
 cmp edi, SiZEOF RockArr
 jl ForStationerybody



;;loop ends here
	

	;;BasicBlit PROC USES edi edx ebx ecx esi eax ptrBitmap:PTR EECS205BITMAP , xcenter:DWORD, ycenter:DWORD
	mov ebx, Pikachu.pikaptr ;;
	mov ptrPika, ebx
	mov ebx, Pikachu.pikaxpos
	mov initxPika, ebx 
	mov ebx, Pikachu.pikaypos
	mov inityPika, ebx

	mov ebx, ballA.ballptr ;;
	mov ptrballA, ebx
	mov ebx, ballA.ballxpos
	mov initxballA, ebx 
	mov ebx, ballA.ballypos
	mov inityballA, ebx

	invoke	BasicBlit, ptrPika , initxPika, inityPika ;; lets try to draw Pika 
	invoke BasicBlit, ptrballA, initxballA, inityballA ;; lets draw the ball

	
	ret	

GameInit ENDP

;;motion functions here
;; their goal is to find the next position of the ball
;;parabolic motion needs
;; horizontal velocity
;; vertical velocity
;;angle 

;; init random angle



ExplodeRock Proc USES ebx ecx edx edi  ptrRock:DWORD
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  
;;this function goes through the rocks and blows updates the explosions


   mov edi, ptrRock
   ExplodeRocks:

	 ;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is Deactivated and off
						

RenderRockStates:
	;;check the state of the render accordingly
	test (rockobject PTR [edi]).rockstates, 01h ;; is it active and exploding 
	jz ballRender

Explode1:
	test (rockobject PTR [edi]).rockstates, 02h;; explosion 1
	jz Explode2
	;;mov ecx, newgame.explDuration
	;;mov Rock1.RockexplD, ecx ;; the rock stays in this state until count runs out

	mov ebx, (rockobject PTR [edi]).rockxpos
	mov x, ebx 
	mov ebx,(rockobject PTR [edi]).rockypos
	mov y, ebx

	mov ebx,  (rockobject PTR [edi]).rockbitmaps ;;
	mov ptrPika, ebx
	invoke Clearprev, ptrPika, x, y

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 4];;
	mov ptrPika, ebx
	;;invoke Clearprev, balladd  , x, y
	invoke	BasicBlit, ptrPika , x , y

	dec (rockobject PTR [edi]).RockexplD
	;;mov ebx, Rock1.RockexplD
	jnz ballRender
	xor (rockobject PTR [edi]).rockstates, 110b  ;; activate exp 2 and dectivate 1
	mov ecx, newgame.explDuration
	mov (rockobject PTR [edi]).RockexplD, ecx ;;reset
	;;mov (rockobject PTR [RockArr + edi]).RockexplD, 4h

Explode2:
	test (rockobject PTR [edi]).rockstates, 100b ;;explosion 2
	jz Explode3
	;;mov ecx, newgame.explDuration
	;;mov Rock1.RockexplD, ec ;; the rock stays in this state until count runs out
	mov ebx, (rockobject PTR [edi]).rockxpos
	mov x, ebx 
	mov ebx, (rockobject PTR [edi]).rockypos
	mov y, ebx

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 4] ;;
	mov ptrPika, ebx
	invoke Clearprev, ptrPika, x, y

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 8] ;;
	mov ptrPika, ebx
	invoke	BasicBlit, ptrPika , x , y
	;;invoke Clearprev, balladd  , x, y
	dec (rockobject PTR [edi]).RockexplD
	;;mov ebx, Rock1.RockexplD
	jnz ballRender
	xor (rockobject PTR [edi]).rockstates, 1100b  ;; activate exp 3 and dectivate 2
	mov ecx, newgame.explDuration
	mov (rockobject PTR [edi]).RockexplD, ecx ;;reset
	;;mov (rockobject PTR [RockArr + edi]).RockexplD, 4h

Explode3:
	test (rockobject PTR [edi]).rockstates, 1000b ;; explosion 3
	jz Explode4
	;;mov ecx, newgame.explDuration
	;;mov Rock1.RockexplD, ecx ;; the rock stays in this state until count runs out

	mov ebx, (rockobject PTR [edi]).rockxpos
	mov x, ebx 
	mov ebx, (rockobject PTR [edi]).rockypos
	mov y, ebx

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 8] ;;
	mov ptrPika, ebx
	invoke Clearprev, ptrPika, x, y

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 12] ;;
	mov ptrPika, ebx
	invoke	BasicBlit, ptrPika , x , y
	dec (rockobject PTR [edi]).RockexplD

	;;mov ebx, Rock1.RockexplD
	jnz ballRender
	;;invoke Clearprev, balladd  , x, y
	xor (rockobject PTR [edi]).rockstates, 11000b  ;; activate exp 4 and dectivate 3 
	mov ecx, newgame.explDuration
	mov (rockobject PTR [edi]).RockexplD, ecx ;;reset


Explode4:
	test (rockobject PTR [edi]).rockstates, 10000b ;;explosion 4
	jz ResetandDeactivateRock
	;;mov ecx, newgame.explDuration
	;;mov Rock1.RockexplD, ecx ;; the rock stays in this state until count runs out

	mov ebx, (rockobject PTR [edi]).rockxpos
	mov x, ebx 
	mov ebx, (rockobject PTR [edi]).rockypos
	mov y, ebx

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 12] ;;
	mov ptrPika, ebx
	invoke Clearprev, ptrPika, x, y

	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 16] ;;
	mov ptrPika, ebx
	;;invoke Clearprev, balladd  , x, y
	invoke	BasicBlit, ptrPika , x , y

	dec (rockobject PTR [edi]).RockexplD
	;;mov ebx, Rock1.RockexplD
	jnz ballRender
	xor (rockobject PTR [edi]).rockstates, 110000b  ;; deactivate and dectivate 4
	mov ecx, newgame.explDuration
	mov (rockobject PTR [edi]).RockexplD, ecx ;;reset

ResetandDeactivateRock:
	test (rockobject PTR [edi]).rockstates, 100000b ;;explosion 4
	jz ballRender

	mov ebx, (rockobject PTR [edi]).rockxpos
	mov x, ebx 
	mov ebx, (rockobject PTR [edi]).rockypos
	mov y, ebx
	mov ebx,  [(rockobject PTR [edi]).rockbitmaps + 16] ;;
	mov ptrPika, ebx
	invoke Clearprev, ptrPika, x, y
	mov (rockobject PTR [edi]).rockstates,  0  ;;reset
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;and Fire1.fireblaststates, 0h


	;;;;;;;;;;;;;;;;;;;;;;============================
ballRender: ;; ==>out

ret
ExplodeRock ENDP


CreateMovingRocks Proc 
;; creates moving rocks at random points on the screen
;; is called after a certain time passes 
;; have to use the random function
ret
CreateMovingRocks ENDP



UpdateRocks Proc USES edi ebx eax edx
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  
;;goes through the list of rocks and updates them accordingly

;;checks for collisions with the blasts
;;checks for collisions with Pikachu

;;checks the state
;;uses the velocity
;;find the next position ?? (rocks move in straight lines)


;;Loop to go through all the rocks
xor edi, edi
jmp ForRockEval

ForRockbody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	;;;;check for an active rock
RockActive:
	test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementLOOP2     ;;if not


RockAlreadyExploding:
	test (rockobject PTR [RockArr + edi]).rockstates, 01h  ;; rock already exploding
	jz ActiveButNotExploding
	mov ecx, OFFSET RockArr
	add ecx, edi

	;; set the timer here ???
	
	;;cmp (rockobject PTR [RockArr + edi]).RockexplD, 0
	;;jg PastState
	Invoke ExplodeRock , ecx
	

PastState:
	;;dec (rockobject PTR [RockArr + edi]).RockexplD
	jmp IncrementLOOP2;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ExitRockFunc
	;;jnz IncrementLOOP

ActiveButNotExploding:

	;; for now the rocks only move in the x plane
	mov ebx,  (rockobject PTR [RockArr + edi]).rockbitmaps ;;
	mov ptrPika, ebx
	mov ebx,(rockobject PTR [RockArr + edi]).rockxpos
	;;update x with velocity
	mov xprev, ebx ;;store for clearence

	add ebx, (rockobject PTR [RockArr + edi]).rockvelocity  ;; Vx is 0 for stationery rocks
	mov (rockobject PTR [RockArr + edi]).rockxpos, ebx
	mov x, ebx 

	;;update y with velocity
	mov ebx,(rockobject PTR [RockArr + edi]).rockypos
	mov yprev, ebx
	mov y, ebx


;;check for collision with Pika
CollisionWithPika:
    ;;blow up

    mov ebx, Pikachu.pikaxpos
	mov twoX, ebx
	mov ebx, Pikachu.pikaypos
	mov twoY, ebx
	mov ebx, Pikachu.pikaptr
	mov twoBitmap, ebx
	 
	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov oneX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov oneY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov oneBitmap, ebx

	invoke CheckIntersect, oneX, oneY, oneBitmap, twoX, twoY, twoBitmap
	cmp eax, 1 
	jne CollisionWithBlast ;;skip the explosion
	;;put the rock in explosion mode
	xor (rockobject PTR [RockArr + edi]).rockstates, 11b ;;set to exploding
	mov ecx, OFFSET RockArr
	add ecx, edi

	Invoke ExplodeRock , ecx  ;;call the function with a pointer to the rock
	invoke PlaySound, offset PikaShock, 0, SND_FILENAME OR SND_ASYNC
	;;call reduce pikas life and check game
	;;dec Pikachu.Life
	shr Pikachu.Life, 1  ;; at 0 game over

;;;;;;;;;;;

CollisionWithBlast:
;;blow up
;;loop through the blast array
;;check if there is a collision at this new point

;;i ==> esi
xor esi, esi
jmp ForCollisionBlastEval

ForCollisionBlastBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone
	;;load the Rock 
	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov oneX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov oneY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov oneBitmap, ebx

	;;load the blast
	;;check if the blast is active

	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	jz IncrementBlastLOOP
	;;if active load it up
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastxpos
	mov twoX, ebx
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastypos
	mov twoY, ebx
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastptr ;;bitmaps
	mov twoBitmap, ebx

	invoke CheckIntersect, oneX, oneY, oneBitmap, twoX, twoY, twoBitmap
	cmp eax, 1 
	jne IncrementBlastLOOP ;;skip the explosion
	invoke PlaySound, offset ExplosionPath, 0, SND_FILENAME OR SND_ASYNC
	;;put the rock in explosion mode
	xor (fireblast PTR [FireArr + esi]).fireblaststates, 01h ;;deactivate the fireblast
	xor (rockobject PTR [RockArr + edi]).rockstates, 11b ;;set to exploding
	mov ecx, OFFSET RockArr
	add ecx, edi
	Invoke ExplodeRock , ecx  ;;call the function with a pointer to the rock
	;;call reduce pikas life and check game
	;;dec Pikachu.Life

IncrementBlastLOOP:
	add esi, TYPE FireArr
	
ForCollisionBlastEval:
 cmp esi, SIZEOF FireArr
 jl ForCollisionBlastBody


;;;;;;;;
CollisionWithRock:
;;bounce back 
;; loop through the array exclude edi
xor esi, esi
jmp ForCollisionRockEval

ForCollisionRockBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone
	;;load the Rock 
	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov oneX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov oneY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov oneBitmap, ebx

	;;load the blast
	;;check if the blast is active
	NotCurrent:
	cmp esi, edi
	je IncrementRockLOOP

	Active:
	test (rockobject PTR [RockArr + esi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementRockLOOP     ;;if not

	AlreadyExploding:
	test (rockobject PTR [RockArr + esi]).rockstates, 01h  ;; rock already exploding
	jz IncrementRockLOOP
	
	mov ebx, (rockobject PTR [RockArr + esi]).rockxpos
	mov twoX, ebx
	mov ebx, (rockobject PTR [RockArr + esi]).rockypos
	mov twoY, ebx
	mov ebx, (rockobject PTR [RockArr + esi]).rockbitmaps
	mov twoBitmap, ebx


	invoke CheckIntersect, oneX, oneY, oneBitmap, twoX, twoY, twoBitmap
	cmp eax, 1 
	jne IncrementRockLOOP ;;skip the explosion

	;;put the rock in explosion mode
	;;xor (fireblast PTR [FireArr + esi]).fireblaststates, 01h ;;deactivate the fireblast
	neg (rockobject PTR [RockArr + edi]).rockvelocity ;;set to exploding
	neg (rockobject PTR [RockArr + esi]).rockvelocity ;;mov the rocks in opposite directions
	;;call reduce pikas life and check game
	;;dec Pikachu.Life

IncrementRockLOOP:
	add esi, TYPE RockArr
	
ForCollisionRockEval:
 cmp esi, SIZEOF RockArr
 jl ForCollisionRockBody


;;no collisions at all
NormalOperation:
	invoke Clearprev, ptrPika, xprev, yprev
	invoke	BasicBlit, ptrPika , x , y 
	
IncrementLOOP2:
	add edi, TYPE RockArr
	
ForRockEval:
 cmp edi, SiZEOF RockArr
 jl ForRockbody

	
ExitRockFunc:
	
ret
UpdateRocks ENDP


UpdateBlasts Proc
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  
;;goes through the lists of blasts
;; checks if FKEY is pressed and activates one
;;updates the others depending on direction and speed
;;checks for collisions with any of the rocks
;;if so calls Explode rock with a pointer to the rock
;;deactivate the blast
;;part of update fireblast

cmp newgame.blastDelay , 0
je FirstBody      ;;if it is already zero then cool!!
dec newgame.blastDelay



FirstBody:
xor esi, esi
jmp ForBlastEval

ForBlastBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone
	
	;;load the blast
	;;check if the blast is active
	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	jz IncrementBlastLOOP

	;;if active load it up
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastxpos
	mov xprev, ebx
	add ebx, (fireblast PTR [FireArr + esi]).fireblastvelocity
	mov (fireblast PTR [FireArr + esi]).fireblastxpos, ebx 
	mov oneX, ebx

	mov ebx, (fireblast PTR [FireArr + esi]).fireblastypos
	mov yprev, ebx 
	mov oneY, ebx
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastptr ;;bitmaps
	mov oneBitmap, ebx


;;check collision with rock
CollisionWithRock:
;;disappear, set the rock to explosion
;;explode call explosion on the rock

;;i ==> edi
xor edi, edi
jmp ForCollisionEval

ForCollisionBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	;;;;check for an active rock
	test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementLOOP;;if not
	test (rockobject PTR [RockArr + edi]).rockstates, 01h  ;; rock already exploding
	jnz IncrementLOOP

	;;load the current blast
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastxpos
	mov oneX, edi
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastypos
	mov oneY, edi
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastptr
	mov oneBitmap, ebx

	;;load a rock
	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov twoX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov twoY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov twoBitmap, ebx

	invoke CheckIntersect, oneX, oneY, oneBitmap, twoX, twoY, twoBitmap
	cmp eax, 1 
	jne IncrementLOOP ;;skip the explosion

	;;put the rock in explosion mode
	xor (rockobject PTR [RockArr + edi]).rockstates, 11b ;;set to exploding
	;;deactivate the missile
	xor (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	;;xor (fireblast PTR [FireArr + esi]).
	mov ecx, OFFSET RockArr
	add ecx, edi
	Invoke ExplodeRock , ecx  ;;call the function with a pointer to the rock
	;;call reduce pikas life and check game
	;;dec Pikachu.Life
	;;shr Pikachu.Life, 1  ;; at 0 game over

IncrementLOOP:
	add edi, TYPE RockArr

ForCollisionEval:
 cmp edi, SiZEOF RockArr
 jl ForCollisionBody



OutOfBounds:
	;;deactivate the blast ready for next

	mov edi , (fireblast PTR [FireArr + esi]).fireblastxpos
	mov x, edi
	cmp (fireblast PTR [FireArr + esi]).fireblastxpos, 660
	jg ResetBlast
	cmp (fireblast PTR [FireArr + esi]).fireblastxpos, -20
	jg InBounds

ResetBlast:
	xor (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	

InBounds:
	;;invoke Clearprev, ptrV, xprev, y
	invoke Clearprev, oneBitmap, xprev, yprev
	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	jz IncrementBlastLOOP
	;;draw the blast
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastxpos
	mov x, ebx
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastypos
	mov y,ebx
	;;init pos of the fire
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastptr ;; load the bitmap of the fire
	mov ptrV, ebx
	invoke BasicBlit, ptrV, x, y

	;;call reduce pikas life and check game
	;;dec Pikachu.Life
IncrementBlastLOOP:
	add esi, TYPE FireArr
 ForBlastEval:
 cmp esi, SIZEOF FireArr
 jl ForBlastBody



FkeyFire:
	;;when this key is pressed pikachu fires fire balls in the direction he is facing
	;;fires then at rocks
	;;VK_F						 equ 46h
	mov ecx, 46h   ;; Fkey
	cmp ecx, KeyPress
	jne OutFunc ;;=>out

	;;loop through the blast array and activate the blast
    xor esi, esi
    jmp ForFireBlastEval

ForFireBlastBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;;load the blast
	;;check if the blast is active

	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h
	jz FoundInactive
	;;if inactive break

IncrementFireBlastLOOP:
	add esi, TYPE FireArr
	
ForFireBlastEval:
 cmp esi, SIZEOF FireArr
 jl ForFireBlastBody
 cmp esi, SIZEOF FireArr
 je OutFunc

 FoundInactive:
	;; init a and create fire in the direction pikachu is facing
	mov ebx, OFFSET Fireball3  ;;.lpBytes;; get the address of the bitmap
	;;get pika's direction
	test Pikachu.pikastates, 100b ;; check if it is facing right
	jnz FireLeft 

FireRight: 
	;;implementation plan => find an inactive fireball
	;;if yes get the pointer and modify that
	;;activate it
	;;if not do nothing, pikachu has fired max fireballs for now
	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h 
	jnz OutFunc;;==== out ;; the fire is already active
	cmp newgame.blastDelay, 0h
	jne OutFunc
	invoke PlaySound, offset BlastPath, 0, SND_FILENAME OR SND_ASYNC
	mov newgame.blastDelay, 5h
	xor (fireblast PTR [FireArr + esi]).fireblaststates, 01h ;;activate
	mov (fireblast PTR [FireArr + esi]).fireblastvelocity, 10 ;;intitialize the velocity of the ball
	mov edi, Pikachu.pikaxpos 
	add edi, 100;; offset from the center a little bit
	mov (fireblast PTR [FireArr + esi]).fireblastxpos, edi ;; init pos of the fire
	mov edi, Pikachu.pikaypos
	mov (fireblast PTR [FireArr + esi]).fireblastypos, edi
	mov (fireblast PTR [FireArr + esi]).fireblastptr, ebx ;; load the bitmap of the fire
	jmp DrawFireballs;;====>out

FireLeft:
	mov ebx, OFFSET fireball3left
	test (fireblast PTR [FireArr + esi]).fireblaststates, 01h 
	jnz OutFunc;;==== out ;; the fire is already active
	cmp newgame.blastDelay, 0h
	jne OutFunc
	mov newgame.blastDelay, 5h
	invoke PlaySound, offset BlastPath, 0, SND_FILENAME OR SND_ASYNC
	xor(fireblast PTR [FireArr + esi]).fireblaststates, 01h ;;activate
	mov (fireblast PTR [FireArr + esi]).fireblastvelocity, -10 ;;intitialize the velocity of the ball
	mov edi, Pikachu.pikaxpos 
	sub edi, 100 ;; offset from the center a little bit
	mov (fireblast PTR [FireArr + esi]).fireblastxpos, edi ;; init pos of the fire
	mov edi, Pikachu.pikaypos
	mov (fireblast PTR [FireArr + esi]).fireblastypos, edi
	mov (fireblast PTR [FireArr + esi]).fireblastptr, ebx ;; load the bitmap of the fire
	;;jmp OutFunc;;====>out


DrawFireballs:
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastxpos
	mov x, ebx
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastypos
	mov y,ebx
	;;init pos of the fire
	mov ebx, (fireblast PTR [FireArr + esi]).fireblastptr ;; load the bitmap of the fire
	mov ptrV, ebx
	invoke BasicBlit, ptrV, x, y


OutFunc:

ret
UpdateBlasts ENDP







UpdatePikachu Proc USES ecx edi ebx edx
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  
;;this updates the position of Pikachu
;;checks if there is collision with any of the rocks
;;if so reduce life
;;blow the rock maybe
;;check for collision with the ball
;;move the ball randomly with parabolic motion
mov maxjump, 300 ;;

SpaceKey:
	mov ecx, 20h   ;; upkey
	cmp ecx, KeyPress
	jne Upkey
	xor Pikachu.pikastates, 100b  ;; change the way it is facing
	
FacingLeft:
	test Pikachu.pikastates, 100b
	jz FacingRight
	mov  edi, OFFSET pika;;
	mov Pikachu.pikaptr, edi
	jmp Upkey

FacingRight:
	mov  edi, OFFSET pikaright;; 
	mov Pikachu.pikaptr, edi

Upkey:
	mov ecx, 26h   ;; upkey
	cmp ecx, KeyPress
	mov edi, Pikachu.pikaypos
	mov yprev, edi 
	jne LeftKey ;;
	
	;; pika states b1=> 0 stationery b1=> 1 jump  b2 => 0 up b2=> 1 => down  
	test Pikachu.pikastates, 01h  ;; b2b1 and 01 
	jnz LeftKey ;; if it is not zero;; means it is not stationery to begin with
	or Pikachu.pikastates, 3h ;; set b1 to jump, b2 to up
	;;check if stationery
	    ;; if yes set up the up bit 
	    ;;save the initial y position => constant in this case
	;;do nothing if not
	;;mov shifty, 2 ;;

;; when the left key is pressed move pikachu to the left by 4 units
;; if at the end of the frame make pikachu appear on the other side

LeftKey:
	mov ecx, 25h ;; leftkey
	mov ebx, Pikachu.pikaxpos
	mov xprev, ebx ;; keep the prev x

	cmp ecx, KeyPress
	jne RightKey

	add ebx, -15                      ;; shift to the left
	cmp ebx, 0
	jg ShiftedLeft
	mov ebx, 600               ;; move it to the right end if the shift goes past the boundary

ShiftedLeft:
	mov Pikachu.pikaxpos, ebx
	jmp Operations

;;when the right key is pressed move pikacchu to the right
;; when at the end move pikachu to the opposite end
RightKey:
	mov ecx, 27h ;; rightkey
	cmp ecx, KeyPress 
	mov ebx, Pikachu.pikaxpos
	mov xprev, ebx ;; keep the prev x

	jne Operations
	
	add ebx, 15                   ;; move pikachu 4 units to the right
	cmp ebx, 636
	jl ShiftedRight
	mov ebx, 3         ;; if at the end move it the opposite end

ShiftedRight:
	mov Pikachu.pikaxpos, ebx
	jmp Operations


Operations:

;; draw pikachu 
	mov ebx, Pikachu.pikaxpos
	mov x, ebx 
	mov ebx, Pikachu.pikaptr ;;
	mov ptrPika, ebx
	

	;;check the state
	test Pikachu.pikastates, 01h ;;check if jump
	jz Stationery
	test Pikachu.pikastates, 2h    ;; check if b2 is set is up
	jz CheckDown
	mov ebx, Pikachu.pikaypos
	;;mov yprev, ebx 
	add ebx, -5 ;; jump up
	cmp ebx, maxjump  
	jle MAXREACHED
	mov y, ebx
	mov Pikachu.pikaypos, ebx ;; update the position

	;;check for collisions with the rocks
	;;if so call explode rock, reduce pikas life

	jmp DrawPika


MAXREACHED:
	mov ebx, maxjump
	mov y, ebx  ;; set y to maxjump
	mov Pikachu.pikaypos, ebx ;; update the position
	xor Pikachu.pikastates, 2h ;; set the b2 => 0 and the down direction
	jmp DrawPika

CheckDown:
	mov ebx, Pikachu.pikaypos
	add ebx, 5 ;; jump down
	;;mov yprev, ebx
	cmp ebx, 385
	jge MAXDOWN
	mov y, ebx
	mov Pikachu.pikaypos, ebx

	

	jmp DrawPika

MAXDOWN:
	mov ebx, 385
	mov y, ebx ;;
	;;mov yprev, ebx
	mov Pikachu.pikaypos, ebx
	xor Pikachu.pikastates, 11b ;; make it stationery 
	jmp DrawPika 

Stationery:
		mov ebx, Pikachu.pikaptr ;;
		mov ptrPika, ebx
		mov ebx, Pikachu.pikaxpos
		mov x, ebx 
		mov ebx, Pikachu.pikaypos
		mov y, ebx


DrawPika:
	;;mov xprev, 100;;
	invoke Clearprev, ptrPika, xprev, yprev

CheckExplosion:
;;check if there is a collision at this new point

;;i ==> edi
xor edi, edi
jmp ForCollisionEval

ForCollisionBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	;;;;check for an active rock
	test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementLOOP;;if not
	test (rockobject PTR [RockArr + edi]).rockstates, 01h  ;; rock already exploding
	jnz IncrementLOOP

	mov ebx, Pikachu.pikaxpos
	mov oneX, ebx
	mov ebx, Pikachu.pikaypos
	mov oneY, ebx
	mov ebx, Pikachu.pikaptr
	mov oneBitmap, ebx

	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov twoX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov twoY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov twoBitmap, ebx

	invoke CheckIntersect, oneX, oneY, oneBitmap, twoX, twoY, twoBitmap
	cmp eax, 1 
	jne IncrementLOOP ;;skip the explosion
	;;put the rock in explosion mode
	xor (rockobject PTR [RockArr + edi]).rockstates, 11b ;;set to exploding
	mov ecx, OFFSET RockArr
	add ecx, edi

	Invoke ExplodeRock , ecx  ;;call the function with a pointer to the rock
	;;call reduce pikas life and check game
	;;dec Pikachu.Life
	shr Pikachu.Life, 1  ;; at 0 game over

IncrementLOOP:
	add edi, TYPE RockArr
	
ForCollisionEval:
 cmp edi, SiZEOF RockArr
 jl ForCollisionBody

 CollisionWithBall:

;;reduce pikas life
;;dont draw at the new position
invoke BasicBlit, ptrPika , x, y

ret
UpdatePikachu ENDP

GetNextPosBall Proc Uses ebx ecx edx  ;;gets a ptr to the ball
;;to be deleted 

;;to be deleted

LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, Vy:DWORD , Vx:DWORD, Cosa:DWORD, Sina:DWORD  
;;uses the equation of a parabola to get the next position of the ball
;; we will deal with this later?:))

;;find the value of Vx 
;;vx = V*cosTheta
mov edi, ballA.Theta    ;;get the angle
invoke FixedCos, edi   ;;get the sin of theta
mov Cosa, eax 
mov eax, ballA.BallV
imul Cosa
add ballA.ballxpos, edx 

;;chack if  the ball is going down
;;choose the appropriate equation for y 

test ballA.ballstate, 01b
jnz MovingUp

;;vy = V*sinTheta + gravity*timer
MovingDown:
mov edi, ballA.Theta    ;;get the angle
invoke FixedSin, edi   ;;get the sin of theta
mov Sina, eax 
mov eax, ballA.BallV
imul Sina
mov Vy, edx
;;add ballA.ballxPos, ebx 
mov eax, newgame.Gravity
imul ballA.Timer
add edx, Vy
add ballA.ballypos, edx

jmp FuncOut
;;vy = V*sinTheta - gravity*timer
MovingUp:
mov edi, ballA.Theta    ;;get the angle
invoke FixedSin, edi   ;;get the sin of theta
mov Sina, eax
mov eax, ballA.BallV
imul Sina
mov Vy, edx
;;add ballA.ballxPos, ebx 
mov eax, newgame.Gravity
imul ballA.Timer 
add edx, Vy
add ballA.ballypos, edx


;;xpos + vx  
;;ypos + vy
FuncOut:

ret
GetNextPosBall ENDP


UpdateBall Proc
	LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
	LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, Const:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  

	;;update the position of the ball according to its speed a
	;;check if it hits a rock
	;;check if it hits pikachu

	add ballA.Timer, 65536
	mov ebx, ballA.ballptr
	mov balladd, ebx ;; init a pointer to the ball

	mov ecx, ballA.ballangle
	mov ballAngle, ecx ;; assign the angle to a var

	mov edi, ballA.ballxpos ;;get the xcenter
	mov xprev, edi ;; assign the xcenter to x
	mov eax, ballA.ballypos
	mov yprev, eax ;; assign ycenter to y

	invoke GetNextPosBall
	;;call the function to determine the next position of ball
	;;puts the results in edi and eax
	;;init with the result from Getnextpos
	mov edi, ballA.ballxpos ;;get the xcenter
	mov x, edi ;; assign the xcenter to x
	mov eax, ballA.ballypos
	mov y, eax ;; assign ycenter to y

	;;check if is out of bounds
	
;;ballstate BYTE 0  ;;  b1 set => vertical, 0 ==> moving down ,,b2 =>set North, b3 set =>south b4 set => east, b5 unset => we
RightSide:
	cmp x, 630
	jle LeftSide
	;;use the ball timer 
	mov ballA.Timer, 0  ;;set the timer back to zero
	mov  Const, 205887 
	;;invoke nrandom, Const
	;;neg eax
	;;mov eax, -51471

	;;plan is to make V and accelaration random
	mov ballA.Theta, 205887;;  <======= movement
	mov ballA.BallV, 983040

	;;moving from the east and north and going down
	mov ballA.ballstate, 1010b 
	jmp FuncOut

LeftSide:
	cmp x, 10
	jge TopY
	;;use the ball timer 
	mov ballA.Timer, 0  ;;set the timer back to zero
	mov  Const, 205887 
	;;invoke nrandom, Const
	;;neg eax
	;;mov eax, -51471

	;;plan is to make V and accelaration random
	mov ballA.Theta, 0;;  =======> movement
	mov ballA.BallV, 983040
	;;ballstate BYTE 0  ;;  b1 set => vertical, 0 ==> moving down ,,b2 =>set North, b3 set =>south b4 set => east, b5 unset => we

	;;moving from the west and north and going down
	mov ballA.ballstate,  10010b 
	jmp FuncOut

TopY:
	cmp y, 10
	jge Bottom
	;;use the ball timer 
	mov ballA.Timer, 0  ;;set the timer back to zero
	mov  Const, 205887 
	invoke nrandom, Const
	;;neg eax
	;;mov eax, -51471

	;;plan is to make V and accelaration random
	mov ballA.Theta, -102943;;  down movement
	mov ballA.BallV, 0

	;;moving from the North and going down
	xor ballA.ballstate, 10b ;;going down
	jmp FuncOut

	;;check for collision with rocks
	;;bounces with respect to the type of collision experienced
	;;i ==> edi

Bottom:
cmp y, 460
jle StillWithinBounds
shr Pikachu.Life, 2     ;;lose two lives if you let the ball fall down
	
	;;put the ball at the top again 
	;;init ball position
	mov edx, OFFSET ballA ;; load the address of ballA
	mov (ballobject PTR [edx]).ballxpos , 300 ;; above pika
	mov (ballobject PTR [edx]).ballypos , 50  ;; above pika
	mov edi, OFFSET pball ;; load the address to the ball bitmap
	mov (ballobject PTR [edx]).ballptr, edi ;; load the address to the ballbitmap
	mov (ballobject PTR [edx]).ballangle, -200000000 ;; the ball is 0 rotated

    mov ballA.Timer, 0  ;;set the timer back to zero
	mov  Const, 205887 
	invoke nrandom, Const
	;;neg eax
	;;mov eax, -51471

	;;plan is to make V and accelaration random
	mov ballA.Theta, -102943;;  down movement
	mov ballA.BallV, 0

	;;moving from the North and going down
	xor ballA.ballstate, 10b ;;going down
	jmp FuncOut

StillWithinBounds:

xor edi, edi
jmp ForCollisionEval

ForCollisionBody:
	;;get pointer to the beginning
	;;mov edx, OFFSET RockArr
	;;add the type * index to get pointer to the right position
	;;edx contains a pointer to a struct in the arr

	;; b1=> 0 compact 
						;;b1 => 1 exploding ==> iterate through explosion bitmaps
						;;b2 => 1 => xplosion 1
						;;b3 => 1 => xplosion 2
						;;b4 => 1 => explosion 3
						;;b5 => 1 => explosion 4
						;;b6 => 1 => the rock is gone

	;;;;check for an active rock
	test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
	jz IncrementLOOP;;if not
	test (rockobject PTR [RockArr + edi]).rockstates, 01h  ;; rock already exploding
	jnz IncrementLOOP

	mov ebx, ballA.ballxpos
	mov twoX, ebx
	mov ebx, ballA.ballypos
	mov twoY, ebx
	mov ebx, ballA.ballptr
	mov twoBitmap, ebx

	mov ebx, (rockobject PTR [RockArr + edi]).rockxpos
	mov oneX, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockypos
	mov oneY, ebx
	mov ebx, (rockobject PTR [RockArr + edi]).rockbitmaps
	mov oneBitmap, ebx

	
	invoke CheckIntersect,  oneX, oneY, oneBitmap ,twoX ,twoY, twoBitmap
	cmp eax, 0
	je IncrementLOOP
	;;ballstate BYTE 0  ;;  b1 set => vertical, 0 ==> moving down ,,b2 =>set North, b3 set =>south b4 set => east, b5 unset => we
	
	;;check the nature of the explosion

PureNorthRock:
;;use the ball timer 
mov ballA.Timer, 0  ;;set the timer back to zero
mov  Const, 205887 
invoke nrandom, Const
neg eax
;;mov eax, -51471
mov ballA.Theta, eax ;;-102943 ;;move up
mov  Const, 983040 
invoke nrandom, Const
neg eax
mov ballA.BallV, 983040 ;;eax
xor ballA.ballstate, 01b ;;mov upinvoke Clearprev, balladd  , xprev, yprev
jmp FuncOut

NorthEasRock:


;;jmp IncrementLOOP
NorthWestRock:

;;jmp IncrementLOOP
PureSouthRock:


SouthEastRock:


;;jmp IncrementLOOP
SouthWestRock:




IncrementLOOP:
	add edi, TYPE RockArr
	
ForCollisionEval:
 cmp edi, SiZEOF RockArr
 jl ForCollisionBody


PikachuCollision:
    ;;check for collision with Pikachu
    mov ebx, Pikachu.pikaxpos
	mov twoX, ebx
	mov ebx, Pikachu.pikaypos
	mov twoY, ebx
	mov ebx, Pikachu.pikaptr
	mov twoBitmap, ebx

	mov ebx, ballA.ballxpos
	mov oneX, ebx
	mov ebx, ballA.ballypos
	mov oneY, ebx
	mov ebx, ballA.ballptr
	mov oneBitmap, ebx

	invoke CheckIntersect,  oneX, oneY, oneBitmap ,twoX ,twoY, twoBitmap
	cmp eax, 0
	je FuncOut

	
PureNorthPika:
;;use the ball timer 
mov ballA.Timer, 0  ;;set the timer back to zero
mov  Const, 102943 
invoke nrandom, Const
neg eax
sub eax, 68629
;;mov eax, -51471
;;find a random angle in the range -pi to 0
mov ballA.Theta, eax 	 ;;move up
mov ballA.BallV, 1966080
xor ballA.ballstate, 01b ;;mov upinvoke Clearprev, balladd  , xprev, yprev
jmp FuncOut

NorthEastPika:

;;jmp IncrementLOOP
NorthWestPika:


	;;check for collision with pika
	
	;;left => bounces back=> horizontaly
	;;right => bounces back => horizontly
	;;up => bounces back

	
FuncOut:
	invoke Clearprev, balladd  , xprev, yprev
	invoke RotateBlit, balladd, x, y, ballAngle   ;; lpBmp:PTR EECS205BITMAP, xcenter:DWORD, ycenter:DWORD, angle:FXPT

	add ecx, 32768 ;; increment the angle
	mov ballA.ballangle, ecx ;; update the state 


ret
UpdateBall ENDP


CreateNewRocks PROC USES edi ebx edx  
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , Const:DWORD, xprev:DWORD, yprev:DWORD      
;;this function uses a timer to create rocks 
;;shoots the rocks at pikachu
;;randomly create 
	;;invoke PlaySound, offset newgameDrums, 0, SND_FILENAME OR SND_ASYNC
	dec newgame.CreationTimer
	cmp newgame.CreationTimer, 0
	jg FuncOut

	;;only create a rock when the timer runs out
	xor edi, edi
	jmp ForCollisionEval

	ForCollisionBody:
		;;get pointer to the beginning
		;;mov edx, OFFSET RockArr
		;;add the type * index to get pointer to the right position
		;;edx contains a pointer to a struct in the arr

		;; b1=> 0 compact 
							;;b1 => 1 exploding ==> iterate through explosion bitmaps
							;;b2 => 1 => xplosion 1
							;;b3 => 1 => xplosion 2
							;;b4 => 1 => explosion 3
							;;b5 => 1 => explosion 4
							;;b6 => 1 => the rock is gone

		;;;;check for an active rock
		test (rockobject PTR [RockArr + edi]).rockstates, 1000000b ;;check if the particular rock is on the screen
		jnz IncrementLOOP;;if not
		test (rockobject PTR [RockArr + edi]).rockstates, 0h  ;; rock already exploding
		jnz IncrementLOOP

		mov Const, 2 ;; randomly choose 1 and 0
        invoke nrandom, Const
		cmp eax, 0
		jz FromtheRight

FromtheLeft:
		mov (rockobject PTR [RockArr + edi]).rockxpos, 10
		mov ebx, Pikachu.pikaypos
		add ebx, 20

		mov (rockobject PTR [RockArr + edi]).rockypos, ebx
		mov (rockobject PTR [RockArr + edi]).rockvelocity, 5
		mov (rockobject PTR [RockArr + edi]).rockstates, 1000000b
		;;init a new timer 

		mov Const, 50
        invoke nrandom, Const
		add eax, 10
		mov newgame.CreationTimer, eax   ;; the timer for the following rock
		jmp FuncOut

FromtheRight:
		mov (rockobject PTR [RockArr + edi]).rockxpos, 630
		mov ebx, Pikachu.pikaypos
		add ebx, 20

		mov (rockobject PTR [RockArr + edi]).rockypos, ebx
		mov (rockobject PTR [RockArr + edi]).rockvelocity, -5
		mov (rockobject PTR [RockArr + edi]).rockstates, 1000000b
		mov Const, 50
		invoke nrandom, Const
		add eax, 10
		mov newgame.CreationTimer, eax   ;; the timer for the following rock
		jmp FuncOut

IncrementLOOP:
	add edi, TYPE RockArr
	
ForCollisionEval:
 cmp edi, SiZEOF RockArr
 jl ForCollisionBody


FuncOut:

ret 
CreateNewRocks ENDP

UpdateScoreAndLife Proc 
LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, Pikalife:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD  
;;this function displays a nummer of hearts depending on how many times pika has been hit
;;if zero lives it dispays game over in the middle of the screen and pauses the game
;;whenever you get hit the number of hearts decreases

cmp newgame.gametime, 0 
jg FiveLives
mov newgame.gametime, 10
mov eax, newgame.score
push eax
push offset fmtStr
push offset outStr
call wsprintf
add esp, 12
invoke DrawStr, offset outStr, 500, 20, 255
inc newgame.score

FiveLives:
cmp Pikachu.Life, 11111b
jne FourLives
;;===> draw the 5 lives
mov Pikalife, offset Fivelives
mov x, 65
mov y, 20
invoke BasicBlit, Pikalife, x, y

jmp FuncOut

FourLives:
cmp Pikachu.Life, 1111b 
jne ThreeLives
;;==draw 4 lives
mov Pikalife, offset Fivelives
mov x, 65
mov y, 20
invoke Clearprev, Pikalife , x, y
mov Pikalife, offset Fourlives
invoke BasicBlit, Pikalife, x, y

jmp FuncOut

ThreeLives:
cmp Pikachu.Life, 111b
jne TwoLives
;;==draw 3lives
mov Pikalife, offset Fourlives
mov x, 65
mov y, 20
invoke Clearprev, Pikalife  , x, y
mov Pikalife, offset Threelives
invoke BasicBlit, Pikalife, x, y

jmp FuncOut

TwoLives:
cmp Pikachu.Life, 11b
jne OneLives
;;==draw 2 lives
mov Pikalife, offset Threelives
mov x, 65
mov y, 20
invoke Clearprev, Pikalife  , x, y
mov Pikalife, offset Twolives
invoke BasicBlit, Pikalife, x, y
jmp FuncOut

OneLives:
cmp Pikachu.Life, 1b 
jne ZeroLives
;;===draw 1 lives
mov Pikalife, offset Twolives
mov x, 65
mov y, 20
invoke Clearprev, Pikalife  , x, y
mov Pikalife, offset Onelives
invoke BasicBlit, Pikalife, x, y
jmp FuncOut

ZeroLives:
;; draw 0 lives
;; pause the game
mov Pikalife, offset Onelives
mov x, 65
mov y, 20
invoke Clearprev, Pikalife  , x, y
mov Pikalife, offset Zerolives
invoke BasicBlit, Pikalife, x, y


mov Pikalife, offset GameOver
mov x, 320
mov y, 200
invoke BasicBlit, Pikalife, x, y
xor newgame.playpause, 01h
;; write game over in the middle of screen


FuncOut:

ret 
UpdateScoreAndLife ENDP




GamePlay PROC USES ecx ebx esi eax
	
	LOCAL ballAngle:DWORD, ptrPika:PTR EECS205BITMAP, balladd:PTR EECS205BITMAP, x:DWORD, y:DWORD, maxjump:DWORD, xprevball:DWORD, yprevball:DWORD, ptrV:DWORD, oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP  
	LOCAL twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP, shifty:DWORD , shift:DWORD, xprev:DWORD, yprev:DWORD                                          
	

	;;call the beuatiful functions
	;; if the player presses P, pause the game
	;; if they press P again, play

 ;;this is a timer for the game

 ;;invoke DrawStr, offset fmtStr, 500, 20, 255

EnterKey:
;;VK_RETURN                            equ 0Dh
	mov ecx, 0Dh   ;; enterkey
	cmp ecx, KeyPress
	jne Play

PauseKey:
    xor newgame.playpause, 01h

Play:
	test newgame.playpause, 01h
	jnz PauseGame
	;;invoke PlaySound, offset PikaShock, 0, SND_FILENAME OR SND_ASYNC 
	dec newgame.gametime
	Invoke UpdatePikachu
	invoke UpdateBlasts
	invoke CreateNewRocks
	invoke UpdateRocks
	invoke UpdateBall
	invoke UpdateScoreAndLife
	
	 
PauseGame:           ;; skip to the end if in pause state

	ret         ;; Do not delete this line!!!
GamePlay ENDP

END
