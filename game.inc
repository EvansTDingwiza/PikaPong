; #########################################################################
;
;   game.inc - Includes for CompEng205 Assignment 4/5
;
;
; #########################################################################

;; Library Definitions
MouseInfo STRUCT
 horiz DWORD ?
 vert  DWORD ?
 buttons DWORD ?
MouseInfo ENDS

MK_CONTROL  = 0008h  ;; The CTRL key is down.
MK_LBUTTON  = 0001h  ;; The left mouse button is down.
MK_MBUTTON  = 0010h  ;; The middle mouse button is down.
MK_RBUTTON  = 0002h  ;; The right mouse button is down.
MK_SHIFT    = 0004h  ;; The SHIFT key is down.
MK_XBUTTON1 = 0020h  ;; The first X button is down.
MK_XBUTTON2 = 0040h  ;; The second X button is down.

;; Library Functions
BlackStarField	PROTO
DrawStr PROTO myStr:PTR BYTE, x:DWORD, y:DWORD, color:DWORD

;; Library Data
EXTERNDEF StarBitmap:EECS205BITMAP
;;other bitmaps
EXTERNDEF GameOver:EECS205BITMAP
EXTERNDEF Fivelives:EECS205BITMAP
EXTERNDEF Fourlives:EECS205BITMAP
EXTERNDEF Threelives:EECS205BITMAP
EXTERNDEF Twolives:EECS205BITMAP
EXTERNDEF Onelives:EECS205BITMAP
EXTERNDEF Zerolives:EECS205BITMAP
EXTERNDEF ScreenBack:EECS205BITMAP
EXTERNDEF fireball3left:EECS205BITMAP
EXTERNDEF Explosion4:EECS205BITMAP
EXTERNDEF Explosion3:EECS205BITMAP
EXTERNDEF Explosion2:EECS205BITMAP
EXTERNDEF Explosion1:EECS205BITMAP
EXTERNDEF Fireball4:EECS205BITMAP
EXTERNDEF Fireball3:EECS205BITMAP
EXTERNDEF rock:EECS205BITMAP
EXTERNDEF pball:EECS205BITMAP
EXTERNDEF pikaright:EECS205BITMAP
EXTERNDEF pika:EECS205BITMAP
;;otherbitmaps


EXTERNDEF MouseStatus:MouseInfo
EXTERNDEF KeyUp:DWORD
EXTERNDEF KeyDown:DWORD
EXTERNDEF KeyPress:DWORD

;; User Defined Functions
GameInit PROTO
GamePlay PROTO
CheckIntersect PROTO oneX:DWORD, oneY:DWORD, oneBitmap:PTR EECS205BITMAP, twoX:DWORD, twoY:DWORD, twoBitmap:PTR EECS205BITMAP 




