    .model large
    
    .stack 100h           
    
    .data 
    
        DTA             db  256 dup(0);
         
        SBuf            db  250; 
        SSize           db  ?;                                                      
        SData           db  251 dup('$');
        
        DirBuf          db  250; 
        DirSize         db  ?;                                                      
        DirData         db  251 dup('$');                                                                                                                           
            
        msgSTART        db  "  *******************************************************************Program start$";                                                       
        msgIncorrecDir  db  "  Incorrect path or empty dirrectory$";
        msgEnterDir     db  "  Enter dirrectory path:$"
        msgEnterStr     db  "  Enter desired string:$"
        msgFile         db  "  Finded file name:$"                                                                                                                  
        ENDLstr         db  0Ah, 0Dh, '$';
        msgEND          db  "  ********************************************************************Program end$";
        
        Fident          dw  ?;
        Fbuf            dw  32767;  
        FSize           dw  9;
        FData           db  32000   dup(0); 
        
        
        
        enter_str   macro   enterAdress;
            
            push    AX;
            push    DX;
            
            mov     AH,     0Ah;
            lea     DX,     enterAdress;  
            int     21h;  
            
            pop     DX;
            pop     AX;
            
        endm
        
        output_str  macro   outputAdress;
            
            push    AX;
            push    DX;
            
            mov     AH,     09h;
            lea     DX,     [outputAdress + 2];
            int     21h;
            
            pop     DX;
            pop     AX;
            
        endm       
        
        endl        macro
             
            push    AX;
            push    DX;
                         
            mov     AH,     09h;
            lea     DX,     ENDLstr;
            int     21h; 
            
            pop     DX;
            pop     AX;
            
        endm
        
        exit        macro   endMsg
            
            output_str      endMsg;
            mov     AX,     4c00h;
            int     21h;
            
        endm
        
        clearBuf    macro   strBuf
            
            push    CX;
            push    AX;
            push    DI;
            
            xor     CX,     CX;
            xor     AX,     AX;
            
            lea     DI,     strBuf + 1;
            mov     CL,     [DI];
            lea     DI,     strBuf + 2;
            mov     AL,     '$';
                
            rep    stosb;
                 
                 
            pop     DI;
            pop     AX;
            pop     CX;
                
        endm;
        
        print_symb macro symb
        mov dl, symb  
        mov ah, 06h
        int 21h    
        endm
                                                                                         
    .code

        main:
                

            mov     AX,     @data;
            mov     DS,     AX;
            lea     DX,     DTA;
            mov     AH,     1Ah;
            int     21h;                    init DTA area 
            
            call readCmdLine
            endl
                    
            mov     AX,     @data;
            mov     ES,     AX;
            
            output_str      msgSTART;
            output_str      SBuf;
            endl;
            output_str      DirBuf;
            endl;    
            call    DirInit;                init Dirrectory and first file in it
            
            jcxz    endMain; 
                 

            ;enter_str       SBuf;           enter siking substring
            ;endl;
  
            Main_Body:
                                                                            
                mov     AL,     0;              set file options for reading by all processes             
                mov     DX,     001Eh;      adressing DTA ASCIZ name of file                     
                mov     AH,     3Dh;
                int     21h;                open file; AX - file identity                        
                jb      endMain;
                
                lea     DI,     Fident;
                mov     [DI],   AX;
                
                lea     SI,     SData;      get offset of siking substring
                xor     AX,     AX;
                mov     AL,     [SI];       get first symbol of substring
                lea     DI,     FData;      get offset of file data buffer
   
                
                CYCLE_FIND:                ;finding first equal symbol in file data buffer
                
                    mov     CX,     1;
                    call    GetFileData;
                    jcxz    nextFile;      ;out of cycle if size of substring is bigger than remaining file data
                    cmp     AL,     [DI];
                    je      foundSymbol;   ;

                    
                jmp    CYCLE_FIND;
                
                nextFile:                  ;start next file if substring is finded or all buffer is checked
                mov     AH,     3Eh;
                int     21h;                close opened file
                
                mov     AH, 4Fh;            get next file to DTA area
                int     21h;
                jb      endMain;           ;getting out if there is no more files in dirrectory
                
                    
            jmp     Main_Body;             ;continue searching with next file
            
            
            endMain:
            exit    msgEND;
            
               
            foundSymbol:                   ;finding substring
            push    CX;                   ;save size of file data buffer
                    
            xor     CX,     CX;
            mov     CL,     SSize;         ;getting real size of substring
            inc     SI;
            dec     CX;
            push    CX;
            call    GetFileData;           ;getting file data to buffer as much as size of substring
            pop     CX; 
            repe    CMPSB;                 ;cycle comparing substring and file buffer
            jcxz    foundSubString;        ;mark for equal substrings
            pop     CX;                    ;getting size of file data buffer back
            lea     SI,     SData;         ;get offset of siking substring in the bad case
            lea     DI,     FData; 
            jmp     CYCLE_FIND;            ;continue searching
                    
            foundSubString:
            output_str      msgFile;       ;optional message
            
            mov     AH,     02h;           ;output of file name if substring was found
            mov     DL,     ' ';
            int     21h;
            lea     DI,     DTA;           
            add     DI,     001Eh;         ;getting offset of ASCIIZ name of file in DTA area
            CYCLE_Output:
            
                mov     DL,     [DI];
                inc     DI;
                cmp     DL,     0;
                je      CYCLE_Exit;        ;out of CYCLE if there is NULL symbol (name fo file is stored as C-string)
                int     21h;
                
            jmp     CYCLE_Output;
            
            CYCLE_Exit:                    
            pop     CX;                    ;getting size of file buffer back
            endl; 
            jmp     nextFile;              ;going to next file
            
            exit    msgEND;
            
        
    ;////////////////////////////////////////////////////////////     Proc     //////////////////////////////////////////////////////////// 
        
         
         
        readCmdLine proc
            
            push si
            push di
            push ax
            push cx
            push bx;
            
            xor bx, bx;
            xor cx, cx
            xor ax, ax
            mov si, 80h
            mov cl, es:[si]  ;cmdl length
            cmp cl, 1
            je  readEnd

            add si, 2        ;skip space
            mov al, es:[si]  ;first symbol
            cmp al, 0dh      ;check if the end of cmdl
            je readEnd
            
            print_symb al
            inc bx;
            lea di, SData
            mov ds:[di], al
            inc si
            inc di
            
            readLoop:
                
                mov al, es:[si]
                cmp al, 0dh
                je  readEnd
                cmp al, ' ';
                je  readEnd;
                print_symb al
                mov ds:[di], al
                inc di
                inc si
                inc bx;
                
            jmp readLoop
            
            readEnd:
     
            mov ds:[di], '$';
            lea di, SSize;
            mov ds:[di],  bl;
            
            
            mov cx, 256;
            readSpaces:
            
                mov al, es:[si];
                cmp al, ' ';
                jne Mark1;
                inc si;       
                       
                
            loop    readSpaces;
             
            Mark1:
            xor bx, bx;
            xor cx, cx 
            
            print_symb al
            inc bx;
            lea di, DirData
            mov ds:[di], al
            inc si
            inc di
            
            readLoop1:
                    
                mov al, es:[si]
                cmp al, 0dh
                je  readEnd1
                cmp al, ' ';
                je  readEnd1;
                print_symb al
                mov ds:[di], al
                inc di
                inc si
                inc bx;
                
            jmp readLoop1
            
            readEnd1:
     
            mov ds:[di], '$';
            lea di, DirSize;
            mov ds:[di],  bl;
            
           
            
             
            pop bx;
            pop cx   
            pop ax
            pop di
            pop si
            ret;
            
        readCmdLine endp
        
         
        DirInit                 proc;  proc will init DTA area(default - PSP:0080h) with first file info of dir; CX - uses as additional flag register
            
            push    AX;
            push    DI;
          
            mov     AX,     @data;
            mov     DS,     AX;
            mov     ES,     AX;
            
            ;output_str      msgEnterDir;
            ;endl;
            ;enter_str       Dirbuf;                   enter dirrectory in format -   .....\DIR
            ;endl;
            xor     AX,     AX;
            lea     DI,     DirData;
            xor     AX,     AX;
            mov     AL,     DirSize;                  get size of string
            add     DI,     AX;                     set DI on last symbol
            
            mov     AL,     0;                      reduce to dir path format   ...\DIR, 0;   
            stosb;
            lea     DX,     DirData;
            mov     AH,     3Bh;
            int     21h;                            set new dirrectory
            
            dec     DI;
            mov     AL,     '\';                       
            stosb;
            mov     AL,     '*';                       
            stosb;
            mov     AL,     '.';                  
            stosb;
            mov     AL,     '*';                   
            stosb;
            mov     AL,     0;                      reduce to any file of dir, format   .....\DIR\*.* , 0    
            stosb;        
            
            xor     CX,     CX;     
            mov     AH,     4Eh;                    end 21h(4eh) preperations 
            lea     DX,     DirData;
            int     21h;                            get first file;
              
            jb      DirInit_mark;
           
           
            clearBuf DirBuf;                          simle endp
            mov     CX,     1;
            pop     DI;
            pop     AX; 
            ret;
           
            DirInit_mark: 
            clearBuf DirBuf;                          error endp
            xor     CX,     CX;
            pop     DI;
            pop     AX;
            output_str      msgIncorrecDir; 
            endl;       
            ret; 
            
        DirInit                 endp;
        
        
        GetFileData             proc;       CX - uses as additional flag register, BX - DTA file identity
            
            push    AX;
            push    DX;
            push    DI;           
            
            mov     AX,     @data;
            mov     DS,     AX;
            mov     ES,     AX;
            
            push    CX;
            mov     CX,     FSize;                                                               
            lea     DI,     FData;                                                               
            mov     AL,     '$';                                                                 
            rep     stosb;                  clear File data buffer                                              
            pop     CX;
            
         
                                     
            lea     DI,     FSize; 
            mov     [DI],   CX;             save size of data to file buffer
               
            mov     BX,     Fident;             set file identity
            lea     DX,     FData;          adressing file buffer
            mov     AH,     3Fh; 
            int     21h;                    getting data to buffer
            
            cmp     CX,     AX;
            jg      GFD_mark;
            
             
                
       
            mov     CX,     1;              simple endp
            pop     DI;
            pop     DX;
            pop     AX;
            ret;
            
            GFD_Mark:                       ;error endp;
            xor     CX,     CX;
            pop     DI;
            pop     DX;
            pop     AX; 
            ret;
            
        GetFileData             endp;   
        
        end main;        
    code    ends