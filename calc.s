%define stuckSize 5                                         ; the size of the stuck                    
section	.rodata					                             
	format_string: db "%s",0		                        ; format difinitions
	format_string_debugMode: db "%s%s",10,0
	format_int: db "%X",10,0		     
    format_string_print_last: db "%s",10,0		     
section .data
    bufferWrite: db "calc: ",0                              ; the buffer we use to write to the user
    ; messages to the user
    MSG_errorOperandStackOverflow: db "Error: Operand Stack Overflow" ,10, 0
    MSG_errorInsufficientNumberOfArgumentsOnStack: db "Error: Insufficient Number of Arguments on Stack",10, 0        
    MSG_errorY: db "wrong Y value",10,0
    MSG_errorSquareRootNotSupported: db "The operation SquareRoot is not supported", 10, 0
    debugEnterNumMGS: db "debug mode : User enters number : ",0
    debugPushedNumMGS: db "debug mode : Result pushed to stuck : ",0
section .bss				       	    
    amountOfOperations: resb 4                              ; the total amount of operations
    myStuck:resb 4*stuckSize                                ; holds the total size of the stuck (4*stuckSize)
    bufferRead: resb 82                                     ; the buffer we use to read from the user(80+2('00','/n'))
    bufferReadLength equ $ - bufferRead                     ; the length of the input that was read fromt he user
    bufferReadTemp: resb 82 
    bufferReadTempN: resb 4                                 ; a temp buffer for 'n' action
    inputLength: resb 4                                     ; the input length
    isDebugMode: resb 1                                     ; a flag that point if it is a debug mode (if 1 = debug mode)
    data:resb 1                                             ; a temp var for savein a data size of 1 byte
    carry: resb 1                                           ; a temp var that saves the carry in some actions
    counter:resb 1                                          ; countes the number of 1's
    temp1: resb 4                                           ; temp var
    temp2: resb 4                                           ; temp var
    temp3: resb 4                                           ; temp var
    temp4: resb 4                                           ; temp var
    temp5: resb 4                                           ; temp var
    powFlag: resb 1                                         ; a flag for debug mode for the pows
section .text
    align 16
	global main					    
    extern printf
    extern calloc
    extern fgets
    extern stdin
    extern fflush
    extern stderr
    extern fprintf
    extern free
    extern stdout
main:					
    push ebp                                                ; start of function                                                    
    mov ebp, esp
    pushad	
    xor esi,esi
    xor ebx,ebx 
    xor eax,eax
    mov esi, dword[ebp+12]                                  ; get first argv string into esi 
    mov ebx, dword[esi+4]                                   ; get the pointer to the first argv
    cmp ebx,0                                               ; if there is no argv
    je _callMyCalc                                          ; starts 'myCalc()'
    mov eax, dword [ebx]                                    ; if there is a argv - so eax points to the first place
    cmp ax,"-d"                                             ; debug mode is "-d"
    je _getArgv
    jmp _callMyCalc                                         ; starts 'myCalc()'
    _getArgv:
        mov [isDebugMode], byte 1                           ; set the flag of debug mode to 1  
    _callMyCalc:
    call myCalc                                             ; calls 'myCalc()'
    
    _printAmountOfOperations:
    mov eax, dword [amountOfOperations]                     ; after returning from 'myCalc()' - prints the amountOfOperations
    push eax
    push format_int
    push dword [stdout]
    call fprintf
    push dword 0
    call fflush
    add esp, 16
    _exitFromMain:                                          ; exit the program       
    mov eax, 1	             		                        ; end of function
    mov ebx, 0           		
    int 0x80
      
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~myCalc~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
      
; A function that rulls the calculator operations      
myCalc:
    push ebp                                                ; start of function
    mov ebp, esp
    pushad
    _pointToStuck:                                          ; make esi,edi pointers to myStuck
        mov esi, myStuck                                    ; esi points to the first cell of the myStuck
        mov edi, myStuck                                    ; edi points to the current cell of the myStuck
        mov [amountOfOperations], dword 0
    _printMenuCalc:                                         ; the part of the menu in the calculator
        mov [bufferRead], dword 0                           ; initialize the varibles
        mov [inputLength], dword 0
        mov [temp1],dword 0
        mov [temp2],dword 0
        mov [temp3],dword 0
        mov [temp4],dword 0
        mov [temp5],dword 0
        mov [carry],dword 0
        mov [data], byte 0
        mov [powFlag], byte 0
        mov [counter], byte 0
        mov [bufferReadTemp], dword 0
        mov [bufferReadTempN], dword 0
        push bufferWrite                                    ; prints : "calc: "
        push format_string
        call printf
        push dword 0
        call fflush
        add esp,12  
        push dword [stdin]                                  ; getting input from the user
        push bufferReadLength
        push bufferRead
        call fgets
        add esp,12                      
        
        mov ecx,dword bufferRead                            ; eax points to the start of bufferRead
       _removeTheEnter:                                     ; removes the enter from every input                
        cmp byte [ecx], 0x0A                                ; if the loop is over ('\n'=0x0A)
        je change
        inc ecx
        jmp _removeTheEnter
        change: mov [ecx],byte 0                            ; instead of '/n' we put byte 0
  
    _checkInput:                                            ; check the input and moves to the suitable function
        cmp [bufferRead], byte 'q'
            je _goToQuitFunc
        cmp [bufferRead], byte '+'
            je _goToUnsignedAdditionFunc
        cmp [bufferRead], byte 'p'
            je _goToPopAndPrintFunc
        cmp [bufferRead], byte 'd'
            je _goToDuplicate
        cmp [bufferRead], byte '^'
            je _goToCheckRanges
        cmp [bufferRead], byte 'v'
            je _goToCheckRanges
        cmp [bufferRead], byte 'n'
            je _goToNumberOf1Bits
	cmp [bufferRead], dword 'sr'
            je _goToSquareRoot
        jmp _goToRegularInput
        
        _goToQuitFunc:                                      
            jmp _Quit
        _goToUnsignedAdditionFunc:
            add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
            call _UnsignedAddition
            jmp _printMenuCalc
        _goToPopAndPrintFunc:
            add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
            call _PopAndPrint
            jmp _printMenuCalc
        _goToDuplicate:
            add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
            call _Duplicate
            jmp _printMenuCalc
        _goToCheckRanges:
            add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
            call _checkRanges
            jmp _printMenuCalc
        _goToNumberOf1Bits:
            add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
            call _NumberOf1Bits
            jmp _printMenuCalc
	_goToSquareRoot:
	    add [amountOfOperations], byte 1                 ; add 1 to the amount of operations
	    call _SquareRoot
            jmp _printMenuCalc
        _goToRegularInput:
            call _RegularInput
            jmp _printMenuCalc
            
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~UnsignedAddition~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that take care of the addition action in the calculator.
; 1 list is popped and the addition is performed on the second list(the one who enterded earlier).
; If the secon list is shorter then the first, so we change the pointer of the last cells from the first to the second 
_UnsignedAddition:
    push ebp                                                ; start of function
    mov ebp, esp
    pushad
    _checkIfUnsignedAdditionFunction:
        mov [carry], byte 0                                 ; initialize the carry
        xor ebx,ebx
        xor edx,edx
        lea ebx, [edi]
        lea edx, [esi]
        cmp ebx, edx                                        ; check if the current cell is the first cell-->nothing in stuck 
        je _errorInsufficientNumberOfArgumentsOnStack
        xor ebx,ebx
        xor edx,edx
        lea ebx, [edi-4]
        lea edx, [esi]
        cmp ebx, edx                                        ; check if the current cell is the second cell-->not enogth args
        je _errorInsufficientNumberOfArgumentsOnStack
        xor ebx,ebx
        xor edx,edx
        xor ecx,ecx
        xor eax,eax
        lea eax, [edi-4]                                    ; points to the last cell
        lea edx, [edi-8]                                    ; points to the cell before the last cell
        mov ebx, [eax]                  ; in ebx there is the adderess of the first link, so eax will point to the first link
        mov ecx, [edx]                  ; in edx there is the adderess of the second link, so eax will point to the first link
        mov [temp2],ebx                                     ; save ebx in temp2    
        mov [temp3],ecx                                     ; save ecx in temp3
        _compareListsLengths:   
            cmp ecx, 0                                      ; if we reach the end of ecx then we check the curr point in ebx
            je _checkEbx
            lea eax, [ecx+1]
            mov ecx, [eax]                                  ; moves to the next cell
            lea edx, [ebx+1]
            mov ebx, [edx]                                  ; moves to the next cell
            cmp ebx, 0                                      ; if ebx small then ecx
            je _beforeAdditionLoop
            jmp _compareListsLengths
            _beforeAdditionLoop:                            ; recover ebx and ecx values
                mov ecx, [temp3]                            
                mov ebx, [temp2]
                jmp _additionLoop
            jmp _compareListsLengths
            _checkEbx:                                      ; checks the curr link in ebx    
                cmp ebx,0                                   ; ebx is longer then ecx
                jne _addEbxToEcx
                _addEbxToEcx:
                    mov ecx, eax                            ; return to the current cell (eax = eac (previos)+1)
                    lea eax, [ebx]
                    mov [ecx],dword eax
                    sub edx, byte 1                         ; moves edx to the last cell that ebx pointed
                    mov ebx,edx
                    mov [ebx+1], dword 0                    ; makes ebx point to nothing
                mov ecx, [temp3]                            ; recover ebx and ecx values
                mov ebx, [temp2]
            _additionLoop:                                  ; the addition calculation
                mov [temp2],ebx
                mov [temp3],ecx 
                cmp ecx, 0
                je _endAddition
                xor edx,edx
                xor eax,eax
                lea edx, [ebx]
                lea eax, [ecx]
                cmp edx,eax                                 ; means that |ecx| was small then |ebx| and now they are pointing                  
                                                            ; to the same place
            je _differentAdditionEcxAndCarry                ; when ebx and ecx not in the same length
            cmp ebx,0
            je _differentAdditionEcxAndCarry
            xor edx,edx
            xor eax,eax
            mov dl,[ecx]                                    ; moves to dl the data that in ecx    
            mov al,[ebx]                                    ; moves to al the data that in ebx
            add dl,al                                       ; dl = al + dl 
            add dl,[carry]                                  ; dl = dl + carry
            mov [carry], dword 0                            ; initialize the carry for the next iteration
            jmp _comparePart
            _differentAdditionEcxAndCarry:                  ; ebx and ecx not in the same length
                xor edx,edx         
                xor eax,eax
                mov dl,[ecx]                                    
                add dl,[carry]                              ; calculates only dl = dl +carry       
                mov [carry], dword 0                        ; initialize the carry for the next iteration
            _comparePart:
                cmp edx, 16                                 ; if the addition got 16 etc then we have a carry to save
                jge _saveCarry
                mov [ecx], dl
                lea eax, [ecx+1]
                mov ecx, [eax]                              ; the next cell
                cmp ebx,0
                jne _incEbx
                jmp _additionLoop
            _incEbx:                                        ; increment ebx and loop to continue the addition
                lea eax, [ebx+1]
                mov ebx, [eax]                              ; the next cell
                jmp _additionLoop
            _saveCarry:                                     ; saves the carry for the next iteration
                xor ebx,ebx
                mov bl, byte 16                             ; moves 16 to bl
                mov eax, dword edx                          ; moves to al the number
                mov edx, dword 0
                div ebx                                     ; the int part goes to eax, the reminder to edx
                mov [temp1], byte 0                         ; take care to the int part
                mov [temp1], edx                            ; temp1 hold the reminder
                mov edx, dword 0
                mov dl, [temp1]
                mov [ecx], dl
                mov [temp1], byte 0                         ; take care to the reminder
                mov [temp1], eax
                mov eax, dword 0
                mov al, [temp1]                             ; al hold the reminder
                mov [carry], dword 0
                mov [carry], al                             ; saves the reminder to the carry varible
                mov eax, [ecx+1]                            ; check if this is the last link
                cmp eax, dword 0
                je _checkCarry
                jmp _updateNextCells
                _checkCarry:                                
                    cmp [carry], dword 0
                    jne _addLink
                _addLink:                                   ; if there is a need to add a new link that contains the carry
                    push 1
                    push 5                                  ; calloc's parameter: number of bytes to allocate
                    call calloc
                    add esp,8
                    mov ecx,[temp3]
                    mov [ecx+1],dword eax 
                    mov ecx, dword eax                      ; the next cell
                    mov edx, dword 0
                    mov dl, [carry]
                    mov [ecx],dl
                    mov eax, [ecx+1]                        ; to reach to final in _additionLoop
                    mov ecx, eax                            ; the next cell
                    mov ebx, [temp2]
                    cmp ebx,0
                    jne _updateEbx
                    jmp _resetCarry
                    _updateEbx:                             ; inc ebx to the next cell
                        mov eax, [ebx+1]
                        mov ebx, eax                        ; the next cell
                    _resetCarry:                            ; initialize the carry again
                        mov [carry], dword 0
                        jmp _additionLoop
                _updateNextCells:                           ; increment 1 link in each list 
                    mov ecx, [temp3]
                    mov eax, [ecx+1]
                    mov ecx, eax                            ; the next cell
                    mov ebx, [temp2]
                    cmp ebx,0
                    jne _updateEBX
                    jmp _updateNewCells
                _updateEBX:                                  
                    mov eax, [ebx+1]
                _updateNewCells:
                    mov ebx, eax                            ; the next cell
                    jmp _additionLoop
        _endAddition:                                       ; end function
            call _Pop
            _checkIfPowMode:
            cmp [powFlag], byte 1                           ; if it is not a pow mode, then print the debug mode if exists
            jne _checkIfDebugMode
            jmp _exitFromAddition                           ; if it is a pow-check enything and quit
            _checkIfDebugMode:
            cmp [isDebugMode], byte 1
            je _printEnteredNumberAddition
            jmp _exitFromAddition
            _printEnteredNumberAddition:                    ; prints : "debug mode : User enters a number"                                        
                jmp _Print
                _finishPrintingAdd:
                push ecx
                push debugPushedNumMGS        
                push format_string_debugMode
                push dword [stderr]
                call fprintf
                push dword 0
                call fflush
                add esp,20
            _exitFromAddition:
            mov esp, ebp
            pop ebp
            ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PopAndPrint~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that prints the last link and pop it from the stuck.                
_PopAndPrint:
    push ebp                                                ; start of function
    mov ebp, esp
    pushad
    _printLastLink:
        xor ebx,ebx
        xor edx,edx
        lea ebx, [edi]
        lea edx, [esi]
        cmp ebx, edx                                        ; check if the current cell is the first cell-->nothing in stuck 
        je _errorInsufficientNumberOfArgumentsOnStack
        xor ebx,ebx
        xor eax,eax
        lea edx, [edi-4]                                    ; in ebx there is the adderess of the first link, so eax will
        mov eax, [edx]                                      ; point to the first link
        _pushToAssemblyStuck:
            xor edx,edx
            mov dl, [eax]
            push edx                                        ; so that ebx will point on the first mini-cell of the last cell
            lea edx, [eax+1]                                ; the,address that needs to free
            mov eax, [edx]                                  ; in ebx there is the adderess of the first link, so eax will 
            cmp eax, 0                                      ; point to the first link
            jne _pushToAssemblyStuck
        _popFromAssemblyStuck:
            lea edx, [edi-4]     
            mov eax, [edx]                                  ; eax will point to the first link
            xor edx,edx
            mov ecx,dword bufferReadTemp
            mov ebx, ecx                                    ; ebx and ecx points to the same place
        _loopPrint:                                         ; a loop that prints the link
            pop edx
            cmp edx, 10                                     ; if it is bigger then 10 so its a letter, else it's a number
            jge _add55ToChar
            jmp _add48ToChar
            _add48ToChar: add dl,48                         ; converts numbers between 0-9
                    jmp _continuePrint
            _add55ToChar: add dl,55                         ; converts letters between A-F
            _continuePrint: 
            mov [ebx], dword edx		                    ; saves the char to register ebx	
            inc ebx                                         ; ebx point to the next cell
            lea edx, [eax+1]     
            mov eax, [edx]                                  ; eax will point to the next link
            cmp eax, 0
            jne _loopPrint
            mov [ebx], byte 0x00			                ; adding null terminator
            cmp [isDebugMode], byte 1                       ; if it is a debug mode
        _callPrint:                                         ; prints the list
        push ecx                                            
        push format_string_print_last
        call printf
        push dword 0
        call fflush
        add esp,12
        call _Pop                                           ; call pop function
        mov esp, ebp                                        ; end function
        pop ebp
        ret
                
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~checkRanges~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that take care of the common actions between the 2 types of pows  
    _checkRanges:
        push ebp                                            ; start of the function
        mov ebp, esp
        pushad
        _checkTheStuck:
        xor ebx,ebx
        xor edx,edx
        lea ebx, [edi]
        lea edx, [esi]
        cmp ebx, edx                                        ; check if the current cell is the first cell-->nothing in stuck 
        je _errorInsufficientNumberOfArgumentsOnStack
        xor ebx,ebx
        xor edx,edx
        lea ebx, [edi-4]
        lea edx, [esi]
        cmp ebx, edx                                        ; check if the current cell is the second cell-->not enogth args 
        je _errorInsufficientNumberOfArgumentsOnStack
        xor ebx,ebx
        xor edx,edx
        xor ecx,ecx
        xor eax,eax
        lea eax, [edi-4]
        lea edx, [edi-8]
        mov ebx, [eax]                ; in ebx there is the adderess of the first link, so ebx will point to the first link=>x
        mov ecx, [edx]                ; in ecx there is the adderess of the second link,so ecx will point to the first link=>y
        _checkY:                                            ; check if y>200 (= y>C8)
            xor eax,eax
            _inc2Ecx:                                       ; reach to the link 2 in the list (if exists)                             
                xor edx,edx
                mov dl, [ecx]
                push edx
                lea edx, [ecx+1]
                mov ecx,[edx]
                add byte al,1
                cmp al,2
                je _checkNextCell
                jmp _ifEnd
                _checkNextCell:                             ; if there are more then 2 links --> error, y>C8
                cmp [edx],dword 0
                jne _throwError
                _ifEnd:
                cmp ecx,0
                jne _inc2Ecx
            _popAndCheck:
                pop edx
                cmp edx, 0x0C                               ; if the second cell is greater then C
                jg _throwError
                cmp edx, 0x0C                               ; if the second cell is equal to C
                je _checkPreviosCells
                jmp _convertPowToNumber
                _throwError:                                ; throw error about the size of y
                    push MSG_errorY
                    push format_string
                    call printf
                    push dword 0
                    call fflush
                    add esp,12
                    mov esp, ebp                            ; returns to _printMenuCalc, end fumction
                    pop ebp
                    ret
                _checkPreviosCells:                      ; if the second cell is C, then check that the previos cell is not
                    cmp eax,2                               ; greater then 8
                    je _popEdx                              
                    _popEdx:
                    pop edx
                    cmp edx,8
                    jg _throwError
        _convertPowToNumber:                                 ; convert y list to a number
            xor eax,eax
            xor edx,edx
            lea edx, [edi-8]
            mov ecx, [edx]           ; in edx there is the adderess of the second link, so eax will point to the first link=>y
        convertYToNUmber:
            xor edx, edx				                    ; clearing edx
            mov dl, [ecx]				                    ; adding the data to dl
            xor ebx, ebx				                    
            add ebx, edx 				                    ; adding the data to curr link
            xor eax, eax				
            lea eax, [ecx+1]			
            mov ecx, [eax]				
            cmp ecx, 0				                        ; if Y has 2 letters
            je _changePointersBetween2lists			
            xor edx, edx				
            mov dl, [ecx]				                    ; adding the data to dl
            xor eax, eax				
            mov eax, 0x10		                            ; 10 in hexa = 16 in dec
        multiplyWithTen:                                    ; if y has 2 letters              
            cmp eax, 0				
            je _changePointersBetween2lists			
            add ebx, edx 	 			                     
            dec eax					                        ; decrease the number of loops that need to be done
            jmp multiplyWithTen	
            mov [temp4],ebx
        _changePointersBetween2lists:                       ; so x will stay in stuck and y will be poped
        mov [temp4],ebx
        lea eax, [edi-4]
        lea edx, [edi-8]
        mov ebx, [eax]             ; in ebx there is the adderess of the first link, so eax will point to the first link=>x
        mov eax, [edx]            ; in edx there is the adderess of the second link, so eax will point to the first link=>y
        mov [temp2],eax
        mov [edi-8],ebx
        mov eax,[temp2]
        mov [edi-4],eax
        call _Pop                                           ; call pop function
        _currentOption:
            xor eax,eax
            mov eax,[temp4]
            mov [temp5],eax
            mov ecx,[temp5]
            cmp [bufferRead], byte '^'
                je _IfPositivePow
            cmp [bufferRead], byte 'v'
                je _IfNegativePow
        _endFunc:                                           ; end function
        _checkIfDebug:
            cmp [isDebugMode], byte 1
            je _printNumberPow
            jmp _exitFromPow
        _printNumberPow:                           ; prints : "debug mode : User enters a number"
            jmp _Print
            _finishPrintingPow:
            push ecx
            push debugPushedNumMGS        
            push format_string_debugMode
            push dword [stderr]
            call fprintf
            push dword 0
            call fflush
            add esp,20
        _exitFromPow:
        mov esp, ebp
        pop ebp
        ret
       
; we calculate this by doing y times duplicate and add on x.        
    _IfPositivePow:                                         ; if it is the action of the posisive pow
        mov [powFlag], byte 1
        cmp [temp5], dword 0			                            ; ecx hold y value in number
        je _endFunc	
        call _Duplicate			                            ; call _Duplicate
        call _UnsignedAddition			                    ; call _UnsignedAddition
        sub [temp5], dword 1			
        jmp _IfPositivePow			
        
; we calculate this by divide x in 2 y times.
    _IfNegativePow:  
        mov [powFlag], byte 1
        lea eax, [edi-4]
        mov ebx, [eax]      ; in ebx there is the adderess of the first link, so eax will point to the first link=>x
                            ; in ecx we have the value of y
        mov [temp2],ecx
        cmp ecx,0
        je _endFunc
        xor eax,eax
        _calaulateLengthOfCurrList:                         ; checks the length of x
            add eax,1
            mov [inputLength],eax
            lea edx, [ebx+1]
            mov ebx,[edx] 
            cmp ebx,0
            je _divideXwith2InCellInPlaceLength
            jmp _calaulateLengthOfCurrList
        _divideXwith2InCellInPlaceLength:                   ; goes on the list to n'th place and divide it by 2
            lea eax, [edi-4]
            mov ebx, [eax]
            mov eax,[inputLength]
            _division:                                      ; the division clculation
                cmp eax, 1
                je _divideCurrCell
                sub eax,1
                lea edx, [ebx+1]
                mov ebx,[edx]
                jmp _division
            _divideCurrCell:                                ; divides the curr cell by 2
                mov eax, dword 0
                mov al,[ebx]
                cmp [carry],byte 0
                jne _checkIfAddCarry
                jmp _divWith2
                _checkIfAddCarry:                           ; if the division ended with carry it saves it
                cmp [inputLength],dword 0                   ; if it is not the last cell then save the carry
                jne _addCarry
                mov [carry],byte 0
                jmp _divWith2
                _addCarry:                      ; adds the carry to the previos cell
                mov ecx, dword 0x10
                _addCarryLoop:
                    add al,[carry]
                    sub ecx,1
                    cmp ecx, dword 0
                    jne _addCarryLoop
                _divWith2:                      ; the div action
                xor edx,edx
                xor ecx,ecx
                mov cl,2
                div ecx
                mov [carry], edx                             ; the reminder
                xor ecx, ecx 
                mov ecx,[ebx+1]
                mov [ebx],eax
                mov [ebx+1],ecx
                _finishDiv:
                sub [inputLength],dword 1                    
                cmp [inputLength],dword 0
                jne _divideXwith2InCellInPlaceLength
                _finishOneSessionOfDivision:    ; moves to the next iteration
                mov ecx,[temp2]
                sub ecx,1
                mov [temp2],ecx
                mov [carry], byte 0
                cmp ecx,0
                jne _IfNegativePow
            _removeCellsWithZiro:       ; if after division there were left ziros - remove it
                lea eax, [edi-4]
                mov ebx, [eax]
                _jmpToTheEnd:
                    cmp [ebx+1],dword 0
                    jne _takeCellAfter
                    jmp _endFunc
                    _takeCellAfter:
                        lea eax, [ebx+1]
                        mov ecx, [eax]
                    cmp [ecx], byte 0 
                    je _removeLastZiroIfExists
                    mov ebx,ecx 
                    jmp _jmpToTheEnd
                _removeLastZiroIfExists:
                    cmp [ecx+1], dword 0
                    jne _updateAndJmpToTheEnd
                    jmp _tryFree
                    _updateAndJmpToTheEnd:
                        mov ebx,ecx 
                        jmp _jmpToTheEnd
                    _tryFree:           ; if a cell needs to be deleted- free the memory
                    cmp [ecx],dword 0
                    jne _endFunc
                    push ecx
                    call free
                    add esp, 4
                    mov [ebx+1],dword 0
                    jmp _removeCellsWithZiro                        
                    
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Print~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      

; prints the last link
_Print:
    xor ecx,ecx 
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi]
    cmp ebx, edx                                        ; check if the current cell is the first cell-->nothing in stuck 
    je _errorInsufficientNumberOfArgumentsOnStack
    xor ebx,ebx
    xor eax,eax
    lea edx, [edi-4]                                    ; in ebx there is the adderess of the first link, so eax will
    mov eax, [edx]                                      ; point to the first link
    _pushToAssStuck:
        xor edx,edx
        mov dl, [eax]
        push edx                                        ; so that ebx will point on the first mini-cell of the last cell
        lea edx, [eax+1]                                ; the,address that needs to free
        mov eax, [edx]                                  ; in ebx there is the adderess of the first link, so eax will 
        cmp eax, 0                                      ; point to the first link
        jne _pushToAssStuck
    _popFromAssStuck:
        lea edx, [edi-4]     
        mov eax, [edx]                                  ; eax will point to the first link
        xor edx,edx
        mov ecx,dword bufferReadTemp
        mov ebx, ecx                                    ; ebx and ecx points to the same place
    _loopPrintAction:                                         ; a loop that prints the link
        pop edx
        cmp edx, 10                                     ; if it is bigger then 10 so its a letter, else it's a number
        jge _add55ToCharToPrint
        jmp _add48ToCharToPrint
        _add48ToCharToPrint: add dl,48                         ; converts numbers between 0-9
                jmp continuePrint
        _add55ToCharToPrint: add dl,55                         ; converts letters between A-F
        continuePrint: 
        mov [ebx], dword edx		                    ; saves the char to register ebx	
        inc ebx                                         ; ebx point to the next cell
        lea edx, [eax+1]     
        mov eax, [edx]                                  ; eax will point to the next link
        cmp eax, 0
        jne _loopPrintAction
        mov [ebx], byte 0x00			                ; adding null terminator
        cmp [isDebugMode], byte 1                       ; if it is a debug mode
        je _backFromPrint
        _backFromPrint:
        cmp [bufferRead], byte 'v'                  ; we are here for another functions
        je _finishPrintingPow
        cmp [bufferRead], byte '^'
        je _finishPrintingPow
        cmp [bufferRead], byte '+'
        je _finishPrintingAdd
        cmp [bufferRead], byte 'd'
        je _finishPrintingDup
                    
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Duplicate~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that duplicate the last link that in the stuck.
_Duplicate:
    push ebp                                                    ; start of function
    mov ebp, esp
    pushad
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi]
    cmp ebx, edx                                             ; check if the current cell is the first cell,nothing in stuck 
    je _errorInsufficientNumberOfArgumentsOnStack
    _checkSpaceStuck:
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi+4*stuckSize]
    cmp ebx, edx                                                ; check if the current cell is on the last cell 
    je _errorOperandStackOverflow
    xor ebx,ebx
    lea ecx, [edi-4]     
    mov ebx, [ecx]                                              ; in ebx we have the link that we want to duplicate
    xor ecx,ecx
    _createNewLink:                                             ; create new list
        xor eax, eax				
        push 1				
        push 5					
        call calloc				
        add esp, 8			
        mov ecx, eax				
        mov [edi], dword ecx                                    ; update the new pointer of the list in the stuck
        add edi,4                                               ; increment edi pointer
    _duplicateLists:                                            ; does the duplication
        xor eax,eax
        mov eax,[ebx+1]
        cmp eax,0
        je _dupLastLink
        xor eax,eax
        mov al,[ebx]
        mov [ecx],al
        mov [temp1],ecx
        _newLink:                                               ; creates new link 
            xor eax, eax				
            push 1				
            push 5					
            call calloc				
            add esp, 8
            mov ecx, [temp1]
            mov [ecx+1],dword eax                               ; make this link a part of the previos link
            mov ecx,eax                                         ; move to the new link
            lea eax, [ebx+1]                                    ; increment the link that we are duplicating
            mov ebx, [eax]
            jmp _duplicateLists
    _dupLastLink:                                             ; duplicate last link in different way, so the pointer to the 
        mov al,[ebx]                                            ; bext cell will be 0
        mov [ecx],al                                    
        mov [ecx+1], dword 0

    _endDuplicate:                                              ; end function
        _checkIfPowModeDup:
            cmp [powFlag], byte 1                            ; if it is not a pow mode, then print the debug mode if exists
            jne _checkIfDebugModeDup
            jmp _exitFromDuplicate                              ; if it is a pow-check enything and quit
        _checkIfDebugModeDup:
            cmp [isDebugMode], byte 1
            je _printEnteredNumberDuplicate
            jmp _exitFromDuplicate
        _printEnteredNumberDuplicate:                           ; prints : "debug mode : User enters a number"                                        
            jmp _Print
            _finishPrintingDup:
            push ecx
            push debugPushedNumMGS     
            push format_string_debugMode
            push dword [stderr]
            call fprintf
            push dword 0
            call fflush
            add esp,20
        _exitFromDuplicate:
        mov esp, ebp
        pop ebp
        ret
                
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~NumberOf1Bits~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that counts the number of 1's in the binary form of the last link that in stuck   
_NumberOf1Bits:
    push ebp                                                    ; start of function
    mov ebp, esp
    pushad
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi]
    cmp ebx, edx                                                ; check if the current cell is the first cell,nothing in stuck 
    je _errorInsufficientNumberOfArgumentsOnStack
    xor ebx,ebx
    lea ebx, [edi-4]     
    mov ecx, [ebx]                                              ; the stuck we want to count it's number of 1's 
    xor eax,eax
    _countingTheNumberOf1s:
        xor edx,edx
        mov dl,[ecx]                                            ; the data of the current link
    _addToCounter:
        cmp edx, 0                                              ; 0 = 000
            je _add0
        cmp edx, 1                                              ; 1 = 001   
            je _add1
        cmp edx, 2                                              ; 2 = 010 
            je _add1
        cmp edx, 3                                              ; 3 = 011
            je _add2  
        cmp edx, 4                                              ; 4 = 100
            je _add1    
        cmp edx, 5                                              ; 5 = 101
            je _add2
        cmp edx, 6                                              ; 6 = 110
            je _add2
        cmp edx, 7                                              ; 7 = 111
            je _add3
        cmp edx, 8                                              ; 8 = 1000
            je _add1
        cmp edx, 9                                              ; 9 = 1001
            je _add2
        cmp edx, 0x0A                                           ; A = 1010        
            je _add2
        cmp edx, 0x0B                                           ; B = 1011    
            je _add3                                        
        cmp edx, 0x0C                                           ; C = 1100
            je _add2
        cmp edx, 0x0D                                           ; D = 1101
            je _add3
        cmp edx, 0x0E                                           ; E = 1110
            je _add3
        cmp edx, 0x0F                                           ; F = 1111
            je _add4
        _add0:
            add eax, 0
            jmp _checkIfEnd
        _add1:
            add eax, 1
            jmp _checkIfEnd
        _add2:
            add eax, 2
            jmp _checkIfEnd
        _add3:
            add eax, 3
            jmp _checkIfEnd
        _add4:
            add eax, 4
            jmp _checkIfEnd
    _checkIfEnd:                                                ; moves all of the links in the list
        lea ebx, [ecx+1]     
        mov ecx, [ebx]         
        cmp ecx,0
        jne _countingTheNumberOf1s
        cmp eax,0
        jne _splitAndConvert
        mov dl,0
        add [temp1], byte 1
        jmp add48ToCurrChar
        _splitAndConvert:                                       ; convert the number to string to push it to stuck 
            mov ebx,16
            mov edx,dword 0
        _convertToString:   
            div ebx
            push edx                                            ; push the reminder to stuck 
            mov edx,dword 0
            add byte [temp1],1                                  ; holds the length of the number
            cmp eax,0
            je _popChar
            jmp _convertToString
        _popChar:
            mov ecx,dword bufferReadTempN                       ; ecx and bufferReadTempN points to the same place
            mov ebx,ecx
        _popLoop:
            pop edx                                             ; pop the number from stuck
            cmp edx, 10
            jge _add55ToCurrChar
            jmp _add48ToCurrChar
        add48ToCurrChar:
            add dl,48
            mov ecx,dword bufferReadTempN                       ; ecx and bufferReadTempN points to the same place
            mov ebx,ecx
            jmp _conPrint
        _add48ToCurrChar: add dl,48                             ; converts numbers between 0-9
            jmp _conPrint
        _add55ToCurrChar: add dl,55                             ; converts letters between A-F
        _conPrint: 
            mov [ebx], dword edx		     
            inc ebx
            sub byte [temp1],1                                  ; legth--              
            cmp [temp1],dword 0
            jne _popLoop
            mov [ebx], byte 0x00			                    ; adding null terminator
            call _Pop                                           ; call pop function to remov the last link
            call _PushToStuck                                   ; call push to push the new link
            mov esp, ebp                                        ; end function
            pop ebp
            ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~RegularInput~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
       
; A function that take care for a regular number - input, that needs to be pushed to stuck
_RegularInput:
    push ebp                                                    ; start of function
    mov ebp, esp
    pushad
    _printThatNumberEntersFromUser:                             ; check if debug mode is on
    cmp [isDebugMode], byte 1
    je _printEnteredNumber
    jmp _callPush
    _printEnteredNumber:                                        ; prints : "debug mode : User enters a number"                                        
        push bufferRead
        push debugEnterNumMGS        
        push format_string_debugMode
        push dword [stderr]
        call fprintf
        push dword 0
        call fflush
        add esp,20
    _callPush:                                                  ; tries to push the new number to stuck
    call _PushToStuck
    mov esp, ebp                                                ; end function
    pop ebp
    ret
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~PushToStuck~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
       
; A function that take care for pushing a number to stuck
_PushToStuck:
    push ebp                                                    ; strat of function
    mov ebp, esp
    pushad
    mov [inputLength], dword 0                                  ; initialize the inputLength    
    _checkSpaceInStuck:
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi+4*stuckSize]
    cmp ebx, edx                                                ; check if the current cell is on the last cell 
    je _errorOperandStackOverflow
    _printThatNumberPushedToStuck:
        cmp [isDebugMode], byte 1                               ; check is debug mode is on
        je _printNumberPushed
        jmp _beforePush
        _printNumberPushed:                                     ; prints : "debug mode : Result pushed to stuck : " 
            cmp [bufferRead], byte 'n'
            je _pushThePushedDataOfN
            push bufferRead
            jmp _pushOthers
            _pushThePushedDataOfN:
                push bufferReadTempN
            _pushOthers:
                push debugPushedNumMGS        
                push format_string_debugMode
                push dword [stderr]
                call fprintf
                push dword 0
                call fflush
                add esp,20
    _beforePush:                                                ; ecx points to the correct buffer according to the state
        mov [inputLength], dword 0
        mov ecx, dword 0
        xor eax,eax
        cmp [bufferRead], byte 'n'
            je _moveToBufferReadTempN
        mov ecx,dword bufferRead
        jmp _removeZeros    
    _moveToBufferReadTempN:
        mov ecx,dword bufferReadTempN
    _removeZeros:                                               ; remove ziros from the input
        mov al,[ecx]
        cmp al, byte '0'
        je _incEcx
        cmp al, byte '0'
        jne _checkTheInputLength
        _incEcx:
            inc ecx
            jmp _removeZeros
    _checkTheInputLength:
        mov [inputLength], dword 0                              ; initialize inputLength
    _checkLength:
        add byte [inputLength],1                                ; inputLength++
        inc ecx                                                 ; moves to the next byte
        cmp byte [ecx], 0x0
        jne _checkLength                                        ; returns to the start of the loop 'checkTheInputLength        
        xor eax,eax
        push 1                      
        push 5                                                  ; calloc's second parameter: number of bytes to allocate
        call calloc
        add esp,8
        xor edx,edx
        mov edx, [inputLength]
        mov [edi], dword eax                                    ; edi and eax points to the same place
        add edi,4                                               ; set eax as the first link of the list in the stuck
        mov ebx,  eax
        xor ecx,ecx
        xor eax,eax
        cmp [bufferRead], byte 'n'                          
            je moveToBufferReadTempN
        mov ecx,dword bufferRead
        jmp removeZeros
        moveToBufferReadTempN:
            mov ecx,dword bufferReadTempN                       ; ecx points to the correct buffer according to the state
        removeZeros:                                            ; remove zeros from the input
            mov al,[ecx]
            cmp al, byte '0'
            je incEcx
            cmp al, byte '0'
            jne changePointer
            incEcx:
                inc ecx
                jmp removeZeros
    changePointer:
        cmp eax, dword 0
        je _updateEcx
        jmp _continueInsert
    _updateEcx:
        mov [ecx], dword 0x30                                   ; if the ecx is 0 then the bufferRead was originally 0
    _continueInsert:
        mov [inputLength],edx
        cmp byte [inputLength],1
        je _update
    _changePointer:
        inc ecx
        sub byte [inputLength],1                                ; inputLength--
        cmp byte [inputLength], 1
        jne _changePointer
    _update:
        mov [inputLength], edx                                  ; inputLength holds the length of the input(=length of list)
        mov [temp1], edx                                        ;temp1 holds the length of the input
        xor edx,edx
        jmp _insertAsLinkedList
_insertAsLinkedList:
    xor eax,eax
    mov dl, [ecx]
    mov [temp2], ecx                                            ; saves ecx address into temp2
    xor ecx,ecx
    mov cl, byte '9'
    _checkCharRange:
        cmp cl, byte '/'                                        ; if we ended the renge of '0'-'9'
        je _sub55
        cmp dl, cl
        je _sub48
        dec cl
        jmp _checkCharRange
    _sub48: sub dl,48                                           ; converts numbers between 0-9
            jmp _continue
    _sub55: sub dl,55                                           ; converts letters between A-F
    _continue: 
        xor ecx,ecx
        mov [ebx],dl
        cmp [temp1],dword 1
        je _notCalloc
        push 1
        push 5                                                  ; calloc's parameter: number of bytes to allocate
        call calloc
        add esp,8
    _notCalloc:                                                 ; there is no need to do one mor calloc = last link
        mov ecx, [temp2]                                        ; recover ecx last address from temp2
        mov [ebx+1],dword eax
        mov ebx,dword eax
        dec ecx
        sub byte [temp1],1 
        cmp [temp1],dword 0
        jne _insertAsLinkedList
    
    mov esp, ebp                                                ; end function
    pop ebp
    ret
        
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~errorOperandStackOverflow~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
_errorOperandStackOverflow: 
    push MSG_errorOperandStackOverflow   
    push format_string
    call printf
    push dword 0
    call fflush
    add esp,12
    mov [edi], dword 0 
    mov esp, ebp                                                ; end the calling function    
    pop ebp
    ret
        
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~errorInsufficientNumberOfArgumentsOnStack~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      

_errorInsufficientNumberOfArgumentsOnStack:
    push MSG_errorInsufficientNumberOfArgumentsOnStack
    push format_string
    call printf
    push dword 0
    call fflush
    add esp,12
    mov [edi], dword 0 
    mov esp, ebp                                                ; end the calling function
    pop ebp
    ret
        
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Pop~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
; A function that pops the top link in the stuck, and free the memory for each cell
_Pop:
    push ebp                                                    ; start of function
    mov ebp, esp
    pushad
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi]
    cmp ebx, edx                                                ; check if the current cell is the first cell,nothing in stuck 
    je _errorInsufficientNumberOfArgumentsOnStack
    xor ebx,ebx
    xor eax,eax
    xor edx,edx
    xor ecx,ecx
    lea ebx, [edi-4]       
    mov eax, [ebx]                                              ; the link that we want to push    
    _loop:                                                      ; loop all over the cells
        mov cl, [eax]                                               
        mov [data],cl
        xor ecx,ecx
        mov ecx, [eax+1]                                        ; ecx has the address for the next cell
        mov [temp1], ecx       
        push eax
        call free                                               ; call free to release memory
        add esp, 4
        xor ecx,ecx
        mov cl, [data]
        mov eax,[temp1]                                         ; edx and eax now points to the next cell to be free
        mov [data], dword 0
        mov [temp1], dword 0
        cmp eax,0
        jne _loop
        sub edi,4                                               ; update edi value, edi--
        mov [edi],dword 0
    
    mov esp, ebp                                                ; end function
    pop ebp
    ret
    
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Quit~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
    
_Quit:
    xor ebx,ebx
    xor edx,edx
    lea ebx, [edi]
    lea edx, [esi]
    cmp ebx, edx                                                ; check if the current cell is the first cell,nothing in stuck 
    jne _popEverythingFromStuck
    jmp _exit
    _popEverythingFromStuck:
        call _Pop                                               ; call pop function on every link that left in the stuck
        _checkQuit:
            xor ebx,ebx
            xor edx,edx
            lea ebx, [edi]
            lea edx, [esi]
            cmp ebx, edx                                        ; if we end the loop
            jne _popEverythingFromStuck
            jmp _exit
    _exit:                                                      ; exit the program
        mov esp, ebp
        pop ebp
        ret
	

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~SquareRoot~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~; 

_SquareRoot:
    push ebp                                                    ; start of function
    mov ebp, esp
    pushad
    call _errorSquareRootNotSupported
    mov esp, ebp                                                ; end function
    pop ebp
    ret


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~errorSquareRootNotSupported~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;      
        
_errorSquareRootNotSupported: 
    push MSG_errorSquareRootNotSupported   
    push format_string
    call printf
    push dword 0
    call fflush
    add esp,12
    mov [edi], dword 0 
    mov esp, ebp                                                ; end the calling function    
    pop ebp
    ret


