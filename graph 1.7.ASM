format PE GUI 4.0
entry start
include 'R:\FASM\INCLUDE\win32a.inc'
include 'R:\FASM\INCLUDE\MACRO\if.inc'
ID_DIALOG_MAIN = 1
ID_BUTTON = 2
ID_BUTTONGB1 = 3
ID_BUTTONR1 = 4
ID_BUTTONR2 = 5
ID_BUTTONGB2 = 6
ID_EDIT1 = 7
ID_EDIT2 = 8
ID_STATIC1 = 9
ID_STATIC2 = 10
ID_BUTTONGB3 = 11
ID_STATIC3 = 12
ID_STATIC4 = 13
ID_EDIT3 = 14
ID_EDIT4 = 15
ID_STATIC5 = 16
ID_BITMAP = 17
section '.code' code readable executable
start:

 mov eax, [interval]
 mul [intervalsCount]
 mov ebx, 8
 mul ebx
 cinvoke malloc, eax
 mov [polyLinesPointsPointer], eax
 invoke GetModuleHandle, 0
 mov [_hModule], eax
 invoke DialogBoxParam, eax, ID_DIALOG_MAIN, HWND_DESKTOP, DialogProcMain, 0
 cinvoke free, [polyLinesPointsPointer]
 invoke ExitProcess, 0
;----------------------------------------------
proc DialogProcMain uses ebx ecx edx esi, hwnddlg, msg, wParam, lParam
cmp [msg], WM_CLOSE
 je FreeDialog
 ;-------------
 cmp [msg], WM_INITDIALOG
 je InitdialogForm
 ;-------------
 cmp [msg], WM_PAINT
 je PaintForm
 ;-------------
 cmp [msg], WM_LBUTTONDOWN
 je LeftClick
 ;-------------
 cmp [msg], WM_COMMAND
 jne ExitProc
 ;-------------
 mov eax, BN_CLICKED
 shl eax, 16
 add eax, ID_BUTTON
 cmp [wParam], eax
 je ButtonClick
 jmp ExitProc
 ;-------------

LeftClick:
    .if byte [startFlag1] <> 0
        xor ecx, ecx
        xor ebx, ebx
        mov bx, word [lParam]
        mov cx, word [lParam+2]
        .if (bx >= 100) & (bx <= 601)
             push 0
             push 0
             sub ebx, 100
             mov dword [buffer64], ebx
             finit
             fild dword [buffer64]
             fmul [xSmallIntervalPrice]
             fldz
             fld dword [endXPos]
             fcomi st1
             fld st2
             jae positive1
             push -1.0
             fmul dword [esp]
             add esp, 4
             positive1:
             fiadd dword [startXPos]
             fst qword [esp]
             fst dword [buffer64+8]
             mov eax, buffer64
             add eax, 12
             cinvoke sprintf, eax, floatf
             mov eax, buffer64
             add eax, 12
             invoke SetDlgItemTextA, [hwnddlg], ID_EDIT4 , eax
             stdcall getEquationValueFloat, dword [buffer64+8]
             mov dword [buffer64+4], eax
             finit
             fld dword [buffer64+4]
             fst qword [esp]
             cinvoke sprintf, buffer64, floatf
             invoke SetDlgItemTextA, [hwnddlg], ID_EDIT3 , buffer64
             add esp, 8
        .else
             invoke SetDlgItemTextA, [hwnddlg],ID_EDIT3 ,messageNotInRange
             invoke SetDlgItemTextA, [hwnddlg], ID_EDIT4 ,messageNotInRange
        .endif
    .endif
jmp ExitProc
;*****************************************
ButtonClick:
     invoke GetDlgItemTextA, [hwnddlg], ID_EDIT1, buffer64, 15
     mov ebx, eax
     invoke GetDlgItemTextA, [hwnddlg], ID_EDIT2, buffer64, 15
     mov ecx, eax
     push ecx
     invoke IsDlgButtonChecked, [hwnddlg], ID_BUTTONR1
     mov edx, eax
     push edx
     invoke IsDlgButtonChecked, [hwnddlg], ID_BUTTONR2
     pop edx
     pop ecx
     .if (ecx <> 0) & (ebx <> 0) & ((edx = BST_CHECKED) | (eax = BST_CHECKED))
         invoke InvalidateRect, [hwnddlg], NULL, TRUE
         mov al, 1
         mov [startFlag1], al
         jmp ExitProc
     .endif
     invoke MessageBox, [hwnddlg], messageSetInterval, messageBox1, MB_OK
 jmp ExitProc
InitdialogForm:
 invoke LoadImage, [_hModule], ID_BITMAP, IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR+LR_DEFAULTSIZE
 invoke SendDlgItemMessage, [hwnddlg], ID_STATIC5, STM_SETIMAGE, IMAGE_BITMAP, eax

 invoke CreateFont, -9, 7, 0, 0, 0, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH + FF_SWISS, fnt_nm
 mov [fontH], eax
 invoke CreateFont, -9, 7, 2700, 0, 400, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH + FF_SWISS, fnt_nm
 mov [fontV], eax
 invoke CreatePen, PS_SOLID, 1, 0ffh
 mov [pen], eax
 jmp ExitProc
PaintForm:

 invoke BeginPaint, [hwnddlg], ps  ;Маркер начала рисования
 mov [hdc], eax
 invoke SetBkMode, [hdc], TRANSPARENT ;Установка фона текста
 invoke GetDlgItemInt, [hwnddlg], ID_EDIT1, NULL, TRUE
 mov dword [startXPos], eax
 invoke GetDlgItemInt, [hwnddlg], ID_EDIT2, NULL, TRUE
 mov dword [endXPos], eax
 invoke IsDlgButtonChecked, [hwnddlg], ID_BUTTONR1
     .if eax = BST_CHECKED
         stdcall drawCoordinateAxes, [hdc] ;Рисование координатных осей и их оформление
         stdcall drawPoints, [hdc]
     .endif
     invoke IsDlgButtonChecked, [hwnddlg], ID_BUTTONR2
     .if eax = BST_CHECKED
         stdcall drawCoordinateAxes, [hdc]
         stdcall drawLinesPoly, [hdc]
     .endif
 invoke EndPaint, [hwnddlg], ps  ;Маркер окончания рисования
 invoke ReleaseDC, [hwnddlg], [hdc]

 jmp ExitProc
ExitProc:
 xor eax, eax
 ret

FreeDialog:
 invoke EndDialog, [hwnddlg], 0
endp
;***********************************************
proc drawLinesPoly uses ebx ecx edx esi, hdc
   invoke SelectObject, [hdc], [pen]

   finit
   fild [startXPos]
   fst dword [buffer64+60]
   mov ebx, [centerXPos]
   mov [polyLinesPointsLength], 0

   mov eax, dword [intervalsCount]
   xor edx, edx
   mul dword [interval]
   mov dword [buffer64+52], eax
   xor ecx, ecx
   xor edx, edx
   .while ecx < dword [buffer64+52]
        push ecx
        finit
        stdcall getEquationValueFloat, dword [buffer64+60]

        finit
        mov dword [buffer64+28], eax
        fld dword [buffer64+28]
        ftst
        fnstsw ax
        sahf
        jb drawLinesPoly_yLessThanZero

        fild dword [endYPos]     ;eax > 0
        ftst
        fnstsw ax
        sahf
        jb drawLinesPoly_skip2  ;endYPos > 0
        jmp drawLinesPoly_printPoint

        drawLinesPoly_yLessThanZero:  ;eax < 0
        fild dword [endYPos]
        ftst
        fnstsw ax
        sahf
        jae drawLinesPoly_skip2
        drawLinesPoly_printPoint:
            finit
            mov eax, dword [buffer64+28]
            push eax
            fld dword [esp]
            fabs
            fst dword [esp]
            pop eax

            stdcall getYPos, eax
            push ecx
            mov ecx, [polyLinesPointsPointer]
            mov esi, edx
            push edx
            dec esi
            mov edx, dword [ecx + 4*esi] ;y
            dec esi ;x
            .if (dword [ecx + 4*esi] <> ebx) & (edx <> eax)
                pop edx
                mov dword [ecx + 4*edx], ebx
                inc edx
                mov dword [ecx + 4*edx], eax
                inc edx
                inc [polyLinesPointsLength]
                push edx
            .endif
            pop edx
            pop ecx
        drawLinesPoly_skip2:
        finit
        fld dword [buffer64+60]
        .if signed dword [endXPos] > 0
            fadd dword [xSmallIntervalPrice]
        .elseif signed dword [endXPos] < 0
            fsub dword [xSmallIntervalPrice]
        .endif
        fst dword [buffer64+60]
        inc ebx
        pop ecx
        inc ecx
   .endw
   invoke Polyline, [hdc], [polyLinesPointsPointer], [polyLinesPointsLength]
ret
endp
;***********************************************
proc drawPoints uses ebx ecx edx esi, hdc
    invoke SelectObject, [hdc], [pen]
    finit
    fild [startXPos]
    fst dword [buffer64+60]
    mov ebx, [centerXPos]
    xor ecx, ecx
    mov eax, dword [intervalsCount]
    xor edx, edx
    mul [interval]
    mov dword [buffer64+52], eax
    xor ecx, ecx
    .while ecx < dword [buffer64+52]
        push ecx
        xor esi, esi
        xor esi, esi
        xor esi, esi
        fld dword [buffer64+60]
        fnop
        finit
        stdcall getEquationValueFloat, dword [buffer64+60]

        finit
        mov dword [buffer64+28], eax
        fld dword [buffer64+28]
        ftst
        fnstsw ax
        sahf
        jb drawPoints_yLessThanZero

        fild dword [endYPos]     ;eax > 0
        ftst
        fnstsw ax
        sahf
        jb drawPoints_skip2  ;endYPos > 0
        jmp drawPoints_printPoint

        drawPoints_yLessThanZero:  ;eax < 0
        fild dword [endYPos]
        ftst
        fnstsw ax
        sahf
        jae drawPoints_skip2

        drawPoints_printPoint:
            mov eax, dword [buffer64+28]
            push eax
            fld dword [esp]
            fabs
            fst dword [esp]
            pop eax

            stdcall getYPos, eax
            .if (eax >= 175) & (eax <= 675) & (ebx >= 100) & (ebx <= 600)
                push eax
                invoke MoveToEx, [hdc], ebx, eax, NULL
                pop eax
                inc eax
                push eax
                invoke LineTo, [hdc], ebx, eax
                pop eax
                dec eax
                push eax
                invoke LineTo, [hdc], ebx, eax
                pop eax
                inc eax
                push eax
                invoke LineTo, [hdc], ebx, eax
                pop eax
                dec eax
                push eax
                invoke LineTo, [hdc], ebx, eax
                pop eax
            .endif
        drawPoints_skip2:
        finit
        fld dword [buffer64+60]
        .if signed dword [endXPos] > 0
            fadd dword [xSmallIntervalPrice]
        .elseif signed dword [endXPos] < 0
            fsub dword [xSmallIntervalPrice]
        .endif
        fst dword [buffer64+60]
        inc ebx
        pop ecx
        inc ecx
    .endw
ret
endp
;***********************************************
proc getYPos uses ebx ecx edx esi, yValue
    finit
    fild dword [startXPos]
    fabs
    fst dword [buffer64+56]

    mov eax, [centerYPos]
    xor ecx, ecx
    getYPosHighAccuracy_lp_1:

        cmp ecx, 501
        jge getYPosHighAccuracy_lp_1_end

        finit
        fld dword [yValue]
        fld dword [buffer64+56]
        fcomi st1
        jae getYPosHighAccuracy_lp_1_end

        dec eax
        fld dword [buffer64+56]
        fadd dword [ySmallIntervalPrice]
        fst dword [buffer64+56]
        inc ecx
     jmp getYPosHighAccuracy_lp_1
    getYPosHighAccuracy_lp_1_end:

ret
endp
;***********************************************
proc drawCoordinateAxes uses ebx ecx edx esi, hdc
    xor eax, eax
    mov dword [polyLinesPointsLength], eax


    invoke MoveToEx, [hdc], [centerXPos], [centerYPos], NULL
    mov eax, [centerXPos]
    add eax, 520
    mov ebx, [centerYPos]
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    sub eax, 10
    sub ebx, 5
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    add ebx, 11
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    mov eax, [centerXPos]
    add eax, 520
    mov ebx, [centerYPos]
    invoke LineTo, [hdc], eax, ebx;Конец отрисовки OX

    invoke MoveToEx, [hdc], [centerXPos], [centerYPos], NULL
    mov eax, [centerXPos]
    mov ebx, [centerYPos]
    sub ebx, 520
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    sub eax, 5
    add ebx, 10
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    add eax, 11
    push eax
    invoke LineTo, [hdc], eax, ebx
    pop eax
    mov eax, [centerXPos]
    mov ebx, [centerYPos]
    sub ebx, 520
    invoke LineTo, [hdc], eax, ebx ;Конец отрисовки OY

    invoke SelectObject, [hdc], [fontV]
    mov esi, [centerXPos]
    add esi, [interval]
    xor edx, edx
    finit
    fild dword [endXPos]
    fabs
    fild dword [startXPos]
    fabs
    fxch st1
    fsub st0, st1
    fild dword [intervalsCount]
    fxch st1
    fdiv st0, st1
    fst dword [xBigIntervalPrice]
    fld dword [xBigIntervalPrice]
    fist dword [buffer64]
    mov ebx, dword [buffer64]
    .if signed [endXPos] < 0
        neg ebx
    .endif
    mov eax, [startXPos]
    add eax, ebx
    .while edx < [intervalsCount]
        push edx
        push eax
            .if (edx = 0) | (edx = 9) | (edx = 19) | (edx = 29) | (edx = 39) | (edx = 49)
                cinvoke sprintf, buffer64, intf, eax
                mov ecx, [centerYPos]
                add ecx, 20
                add esi, 6
                invoke TextOut, [hdc], esi, ecx, buffer64, eax
                sub esi, 6
            .endif
            invoke MoveToEx, [hdc], esi, [centerYPos], NULL
            mov ecx, [centerYPos]
            mov edx, dword [esp+4]
            .if (edx = 0) | (edx = 9) | (edx = 19) | (edx = 29) | (edx = 39) | (edx = 49)
                sub ecx, 6
                invoke LineTo, [hdc], esi, ecx
                   mov ecx, [centerYPos]
                add ecx, 7
                invoke LineTo, [hdc], esi, ecx
            .else
                sub ecx, 3
                invoke LineTo, [hdc], esi, ecx
                mov ecx, [centerYPos]
                add ecx, 4
                invoke LineTo, [hdc], esi, ecx
            .endif
        pop eax
        add eax, ebx
        add esi, [interval]
        pop edx
        inc edx
    .endw
    invoke SelectObject, [hdc], [fontH]
    finit


    fnop
    fild dword [endXPos]
    fst dword [buffer64+28]
    stdcall getEquationValueFloat, dword [buffer64+28]
    mov dword [buffer64+28], eax
    fld dword [buffer64+28]
    fist dword [endYPos]
    mov eax, dword [endYPos]
    push eax


    fild dword [esp]
    fabs
    fild dword [startXPos]
    fabs
    fxch st1
    fsub st0, st1
    fidiv dword [intervalsCount]
    fst dword [yBigIntervalPrice]
    fld dword [yBigIntervalPrice]
    fist dword [esp]
    pop ebx
    .if signed [endYPos] < 0
        neg ebx
    .endif
    mov eax, [startXPos]
    add eax, ebx
    mov esi, [centerYPos]
    sub esi, [interval]
    xor edx, edx
    .while edx < [intervalsCount]
        push edx
        push eax
            .if (edx = 0) | (edx = 9) | (edx = 19) | (edx = 29) | (edx = 39) | (edx = 49)
                ;mov dword [buffer64+60], eax
                cinvoke sprintf, buffer64, intf, eax
                mov ecx, [centerXPos]
                sub ecx, 50
                sub esi, 5
                invoke TextOut, [hdc], ecx, esi, buffer64, eax
                add esi, 5
            .endif
            mov edx, dword [esp+4]
            .if (edx = 0) | (edx = 9) | (edx = 19) | (edx = 29) | (edx = 39) | (edx = 49)
                invoke MoveToEx, [hdc], [centerXPos], esi, NULL
                mov ecx, [centerXPos]
                sub ecx, 6
                invoke LineTo, [hdc], ecx, esi
                mov ecx, [centerXPos]
                add ecx, 7
                invoke LineTo, [hdc], ecx, esi
            .else
                invoke MoveToEx, [hdc], [centerXPos], esi, NULL
                mov ecx, [centerXPos]
                sub ecx, 3
                invoke LineTo, [hdc], ecx, esi
                mov ecx, [centerXPos]
                add ecx, 4
                invoke LineTo, [hdc], ecx, esi
            .endif
        sub esi, [interval]
        pop eax
        add eax, ebx
        pop edx
        inc edx
    .endw
    push ebx
    .if signed eax >= 0
        mov dword [buffer64+60], ebx
        fild dword [buffer64+60]
        fabs
        mov dword [buffer64+60], eax
        fild dword [buffer64+60]
        fabs
        fsub st0, st1
        fist dword [endYPos]
    .else
        mov dword [buffer64+60], ebx
        fild dword [buffer64+60]
        fabs
        mov dword [buffer64+60], eax
        fild dword [buffer64+60]
        fabs
        fsub st0, st1
        fist dword [endYPos]
        neg dword [endYPos]
    .endif
    pop ebx
    mov eax, [startXPos]
    cinvoke sprintf, buffer64, intf, eax
    mov ecx, [centerXPos]
    mov esi, [centerYPos]
    sub ecx, 40
    add esi, 20
    invoke TextOut, [hdc], ecx, esi, buffer64, eax


    finit
    fild dword [endXPos]
    fabs
    fild dword [startXPos]
    fabs
    fxch
    fsub st0, st1
    push [intervalsCount]
    fidiv dword [esp]
    fst dword [xBigIntervalPrice]
    fild dword [endYPos]
    fabs
    push [intervalsCount]
    fidiv dword [esp]
    fst dword [yBigIntervalPrice]
    add esp, 8

    finit
    fld dword [xBigIntervalPrice]
    push 10.0
    fdiv dword [esp]
    fst dword [xSmallIntervalPrice]

    fld dword [yBigIntervalPrice]
    push 10.0
    fdiv dword [esp]
    fst dword [ySmallIntervalPrice]
    add esp, 8
ret
endp
;***********************************************
proc getEquationValueFloat uses ebx ecx edx esi, xValue
     finit
     fld dword [xValue]
     fmul [xValue]
     fmul [xValue]
     push 15.0
     fmul dword [esp]
     add esp, 4
     fst dword [buffer64];15X^3
     ;finit
     fld dword [xValue]
     fmul [xValue]
     push 12.0
     fmul dword [esp]
     add esp, 4
     fst dword [buffer64+4]
     ;finit
     fld dword [xValue]
     push 17.0
     fmul dword [esp]
     add esp, 4
     push 34.0
     fadd dword [esp]
     fadd dword [buffer64+4]
     fadd dword [buffer64]
     fst dword [buffer64]
     fld dword [xValue]
     fmul dword [xValue]
     push 23.0
     fsub dword [esp]
     fld dword [buffer64]
     ;fxch st1
     fdiv st0, st1
     add esp, 4
     fst dword [esp]
     pop eax
     finit
ret
endp
;***********************************************
proc getEquationValue uses ebx ecx edx esi, xValue
     finit
     fild dword [xValue]
     fimul [xValue]
     fimul [xValue]
     push 15.0
     fmul dword [esp]
     add esp, 4
     fst dword [buffer64];15X^3
     ;finit
     fild dword [xValue]
     fimul [xValue]
     push 12.0
     fmul dword [esp]
     add esp, 4
     fst dword [buffer64+4]
     ;finit
     fild dword [xValue]
     push 17.0
     fmul dword [esp]
     add esp, 4
     push 34.0
     fadd dword [esp]
     fadd dword [buffer64+4]
     fadd dword [buffer64]
     fst dword [buffer64]
     fild dword [xValue]
     fimul dword [xValue]
     push 23.0
     fsub dword [esp]
     fld dword [buffer64]
     ;fxch st1
     fdiv st0, st1
     add esp, 4
     fist dword [esp]
     pop eax
ret
endp
;***********************************************
proc getEquationValueFloatX uses ebx ecx edx esi, xValue     ;X^2
    push 0
    finit
    fld dword [xValue]
    fmul dword [xValue]
    fst dword [esp]
    pop eax
ret
endp
;***********************************************
proc getEquationValueX uses ebx ecx edx esi, xValue     ;X^2
    push 0
    finit
    fild dword [xValue]
    fimul dword [xValue]
    fist dword [esp]
    pop eax
ret
endp
;***********************************************


section '.data' data readable writeable
intf db '%d', 0
floatf db '%lf', 0
fnt_nm db "Courier New", 0

messageSetInterval db 'Interval or graph type is empty. Please enter it first.', 0
messageBox1 db 'ERROR', 0
messageNotInRange db 'NOT_IN_RANGE', 0

startLineFlag1 db 0
startFlag1 db 0

fontH dd ?  ;Горизонтальный, вертикальный шрифты
fontV dd ?

ps PAINTSTRUCT  ;Структуры, переменные win32
_hModule dd ?
hdc dd ?
pen dd ?
rect RECT

centerXPos dd 100 ;Координаты начала OX, OY
centerYPos dd 675

startXPos dd 0 ;Интервал оси OX
endXPos dd 0
endYPos dd ?
interval dd 10 ;Расстояние в лог. единицах между интервалами на оси.
intervalsCount dd 50 ;Кол-во интервалов на каждой оси

xSmallIntervalPrice dd ? ;Значение соотв. изменению значения X при увеличении X на 1/10 интервала.
ySmallIntervalPrice dd ?

xBigIntervalPrice dd ? ;Значение соотв. изменению значения X при увеличении X на 1 интервал.
yBigIntervalPrice dd ?

buffer64 rb 64

polyLinesPointsPointer dd 4096
polyLinesPointsLength dd 0
;***********************************************
section '.idata' data readable writeable
_Translated: db TRUE
;***********************************************
section '.rsrc' data resource readable
directory RT_DIALOG, mainDialog,\
          RT_BITMAP, bitmaps
resource mainDialog,\
 ID_DIALOG_MAIN, LANG_NEUTRAL, MainWindow
resource bitmaps,\
 ID_BITMAP,LANG_NEUTRAL, main_bitmap

 dialog MainWindow, 'FUNCTION GRAPH SEMILETOV I.D.', 0, 0, 500, 500, WS_VISIBLE+WS_SYSMENU+DS_CENTER+WS_MINIMIZEBOX+WS_MINIMIZE
 dialogitem 'BUTTON', 'PRINT', ID_BUTTON, 239, 40, 39, 14, WS_VISIBLE
 dialogitem 'BUTTON', 'MODE', ID_BUTTONGB1, 380, 5, 100, 50, WS_VISIBLE+BS_GROUPBOX
 dialogitem 'BUTTON', 'POINTS', ID_BUTTONR1, 385, 14, 80, 15, WS_VISIBLE+BS_AUTORADIOBUTTON
 dialogitem 'BUTTON', 'LINES', ID_BUTTONR2, 385, 32, 80, 15, WS_VISIBLE+BS_AUTORADIOBUTTON

 dialogitem 'BUTTON', 'INTERVAL', ID_BUTTONGB2, 280, 5, 100, 50, WS_VISIBLE+BS_GROUPBOX
 dialogitem 'STATIC', 'XSTART:', ID_STATIC1, 285, 18, 30, 15, WS_VISIBLE+SS_LEFT
 dialogitem 'STATIC', 'XEND:', ID_STATIC2, 285, 35, 30, 15, WS_VISIBLE+SS_LEFT
 dialogitem 'EDIT', '', ID_EDIT1, 320, 18, 45, 8, WS_VISIBLE
 dialogitem 'EDIT', '', ID_EDIT2, 320, 35, 45, 8, WS_VISIBLE
 dialogitem 'BUTTON', 'COORDINATES', ID_BUTTONGB3, 1, 5, 65, 50, WS_VISIBLE+BS_GROUPBOX
 dialogitem 'EDIT', '', ID_EDIT3, 13, 18, 45, 8, WS_VISIBLE
 dialogitem 'EDIT', '', ID_EDIT4, 13, 35, 45, 8, WS_VISIBLE
 dialogitem 'STATIC', 'Y:', ID_STATIC3, 5, 18, 6, 15, WS_VISIBLE+SS_LEFT
 dialogitem 'STATIC', 'X:', ID_STATIC4, 5, 35, 6, 15, WS_VISIBLE+SS_LEFT
 dialogitem 'STATIC', '', ID_STATIC5, 100, 10, 0, 50, WS_VISIBLE+SS_BITMAP
enddialog

bitmap main_bitmap, 'equation.bmp'
section '.idata' import data readable writeable
  library kernel32, 'KERNEL32.DLL', \
          user32, 'USER32.DLL', \
          gdi32, 'GDI32.DLL', \
          msvcrt, 'MSVCRT'
  import msvcrt,\
          atoi, 'atoi',\
          sprintf, 'sprintf',\
          malloc, 'malloc',\
          free, 'free'
  include 'R:\FASM\INCLUDE\API\Kernel32.inc'
  include 'R:\FASM\INCLUDE\API\User32.inc'
  include 'R:\FASM\INCLUDE\API\Gdi32.inc'
