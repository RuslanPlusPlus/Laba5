    .model large
    
    .stack 100h           
    
    .data 
    
        DTA             db  256 dup(0);
         
        SBuf            db  250; 
        SSize           db  1;                                                      
        SData           db  251   DUP ('$');                                                                                                                           
            
        msgSTART        db  "  *******************************************************************Program start$";                                                       
        msgIncorrecDir  db  "  Incorrect path or empty dirrectory$";
        msgEnterDir     db  "  Enter dirrectory path:$"
        msgEnterStr     db  "  Enter desired string:$"
        msgFile         db  "  Finded file name:$"                                                                                                                  
        ENDLstr         db  0Ah, 0Dh, '$';
        msgEND          db  "  ********************************************************************Program end$";
        
        Fbuf            dw  32767;  
        FSize           dw  1;
        FData           db  32000 dup(0); 
                                                                                         
    .code
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
    
        main:
        
            mov     AX,     @data;
            mov     DS,     AX;
            mov     ES,     AX;             init data segment
            lea     DX,     DTA;
            mov     AH,     1Ah;
            int     21h;                    init DTA area
           
            output_str      msgSTART;
            endl;
           
            call    DirInit;                init Dirrectory and first file in it
            
            jcxz    endMain; 
            
            output_str      msgEnterStr;
            endl;    
            enter_str       SBuf;           enter siking substring
            endl;
                    
            Main_Body:
            
                call    GetFileData;        get file data to buffer in DS 
                jcxz    endMain;            ебля началась
                
                lea     SI,     SData;      get offset of siking substring
                xor     AX,     AX;
                mov     AL,     [SI];       get first symbol of substring
                lea     DI,     FData;      get offset of file data buffer
                mov     CX,     FSize;      get size of file data buffer    
                
                CYCLE_FIND:                ;finding first equal symbol in file data buffer
                
                    cmp     AL,     [DI];
                    je      foundSymbol;
                    inc     DI;
                    
                loop    CYCLE_FIND;
                
                nextFile:                  ;start next file if substrign is finded or all buffer is checked
                mov     AH, 4Fh
                int     21h;
                jb      endMain;           ;gettind out if there is no more files in dirrectory
                    
            jmp     Main_Body;             ;continue searching with next file
            
            endMain:
            ;add first dir
            exit    msgEND;
               
            foundSymbol:                   ;finding substring
            push    CX;                    ;save size of file data buffer
            xor     CX,     CX;
            mov     CL,     SSize;         ;getting real size of substring
            inc cx
            repe    CMPSB;                 ;cycle comparing substring
            jcxz    foundSubString;        ;mark for equal substrings
            pop     CX;                    ;getting size of file data buffer back
            lea     SI,     SData;         ;get offset of siking substring in the bad case
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
        
        
        DirInit                 proc;  proc will init DTA area(default - 0000:0080h) with first file info of dir; CX - uses as additional flag register
            
            push    AX;
            push    DI;
          
            mov     AX,     @data;
            mov     DS,     AX;
            mov     ES,     AX;
            
            output_str      msgEnterDir;
            endl;
            enter_str       Sbuf;                   enter dirrectory in format -   .....\DIR
            endl;
            xor     AX,     AX;
            lea     DI,     SData;
            xor     AX,     AX;
            mov     AL,     Ssize;                  get size of string
            add     DI,     AX;                     set DI on last symbol
            
            mov     AL,     0;                      reduce to dir path format   ...\DIR, 0;   
            stosb;
            lea     DX,     SData;
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
            lea     DX,     SData;
            int     21h;                            get first file;
              
            jb      DirInit_mark;
           
           
            clearBuf Sbuf;                          simle endp
            mov     CX,     1;
            pop     DI;
            pop     AX; 
            ret;
           
            DirInit_mark: 
            clearBuf Sbuf;                          error endp
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
            
            mov     CX,     FSize;                                                               
            lea     DI,     FData;                                                               
            mov     AL,     '$';                                                                 
            rep     stosb;                  clear File data buffer                                              
            
            mov     AH,     3Dh;                                                                 
            mov     AL,     0;              set file options for reading by all processes         
            
            mov     DX,     001Eh;          adressing DTA ASCIZ name of file                     
            mov     AH,     3Dh;
            int     21h;                    open file; AX - file identity                        
            jb      GFD_Mark;
            
            mov     DI,     001Ah;          adressing DTA Size of file                           
            mov     CX,     [DI];
                                     
            lea     DI,     FSize; 
            mov     [DI],   CX;             save size of file to file buffer
               
            mov     BX,     AX;             set file identity
            lea     DX,     FData;          adressing file buffer
            mov     AH,     3Fh; 
            int     21h;                    getting data to buffer
            
            mov     AH,     3Eh;
            int     21h;                    close opened file          
                
       
            mov     CX,     1;              simple endp
            pop     DI;
            pop     DX;
            pop     AX;
            ret;
            
            GFD_Mark:                       ;error endp
            xor     CX,     CX;
            pop     DI;
            pop     DX;
            pop     AX; 
            ret;
            
        GetFileData             endp;   
        
        end main;        
    code    ends