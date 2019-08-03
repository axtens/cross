MODULE CROSS;
    FROM SYSTEM IMPORT OFS, ADR;
    FROM Files IMPORT Open, READ, Close, Create, Write, StdOut;
    FROM XDOS IMPORT BlockReadCreate, BlockReadDestroy, BlockReadLine;
    FROM DevIO IMPORT WriteOut, LineOut, NLOut, CardOut, LineErr, WriteErr;
    FROM System IMPORT Terminate, GetArg;
    FROM Directories IMPORT NORMAL, DirQuery, DirEntry;
    FROM Strings IMPORT Length, Assign, Pos, Append;
    FROM XString IMPORT RightTrim, UpperCase;
    FROM Storage IMPORT ALLOCATE, DEALLOCATE;
    FROM INLine IMPORT IsIn;
    FROM DEBUG IMPORT DebugS, DebugL, DebugC, SetDebugEnv;
    FROM NumberConversion IMPORT CardToString;
    TYPE
        tString = ARRAY [0..255] OF CHAR;
        tOutput = RECORD
                    sFilename : ARRAY [0..12] OF CHAR;
                    sVarname  : ARRAY [0..29] OF CHAR;
                    sLine,
                    sOffset   : ARRAY [0..5] OF CHAR;
                  END;
    VAR

        sQ  : CHAR;
        sQuotes,
        sTemp,
        sInFile,
        sSym,
        sOutFile,
        sWhite,
        sPunct,
        sComments,
        sSearch : tString;
        cInCount,
        cInLength,
        cOffset,
        cLimit,
        cTemp     : CARDINAL;
        bFlag1,
        bFlag2,
        bFlag     : BOOLEAN;
        iBuf     : INTEGER;
        iBuf2    : INTEGER;
        sOutput  : tOutput;

PROCEDURE instruct;
BEGIN
     LineOut('CROSS InputFile');
     LineOut('');
     LineOut('Output goes to StdOut.');
     Terminate(2);

END instruct;
PROCEDURE Skipwhite( VAR cHere : CARDINAL; cHigh : CARDINAL) : BOOLEAN;
BEGIN
        IF cHere > cHigh THEN RETURN FALSE END;
        LOOP
            IF IsIn(sTemp[cHere],sWhite) THEN
                INC( cHere);
                IF cHere > cHigh THEN EXIT END
            ELSE
                EXIT
            END;
        END;
        IF cHere > cHigh THEN RETURN FALSE ELSE RETURN TRUE END;
END Skipwhite;
PROCEDURE Skippunct( VAR cHere : CARDINAL; cHigh : CARDINAL) : BOOLEAN;
BEGIN
        IF cHere > cHigh THEN RETURN FALSE END;
        LOOP
            IF IsIn(sTemp[cHere],sPunct) THEN
                INC( cHere);
                IF cHere > cHigh THEN EXIT END
            ELSE
                EXIT
            END;
        END;
        IF cHere > cHigh THEN RETURN FALSE ELSE RETURN TRUE END;
END Skippunct;

PROCEDURE WriteIt( sFILE, sWORD : ARRAY OF CHAR; cLINE, cOFFSET : CARDINAL);
VAR
    sCRLF : ARRAY [0..1] OF CHAR;
    p     : POINTER TO CHAR;
    c     : CARDINAL;
BEGIN
    UpperCase(sFILE);
    UpperCase(sWORD);
    DebugS("WriteIt: ");
    DebugL(sWORD);
    sCRLF[0] := CHR(13);
    sCRLF[1] := CHR(10);
    IF (sWORD[0] = 0C) OR (sWORD[Length(sWORD)-1]="(") THEN
    ELSE
        DebugS("WriteIt: ");
        DebugL(sWORD);

        DebugL("Clear record");

        p := ADR(sOutput);
        FOR c := 0 TO SIZE(sOutput)-1 DO
            p^ := 0C;
            p.OFS := p.OFS + 1
        END;

        DebugL("Insert data in record");


        WITH sOutput DO
            c := 0;
            WHILE (sFILE[c] # 0C) AND (c <= HIGH(sFILE)) DO
                DebugS("c=");
                DebugC(c);
                DebugL("");
                sFilename[c] := sFILE[c];
                INC(c)
            END;

            c := 0;
            WHILE (sWORD[c] # 0C) AND (c <= HIGH(sWORD)) DO
                DebugS("c=");
                DebugC(c);
                DebugL("");
                sVarname[c] := sWORD[c];
                INC(c)
            END;

            CardToString(cLINE,sLine,5);
            CardToString(cOFFSET,sOffset,5);
        END;

        DebugL("Fill record with spaces");

        p := ADR(sOutput);
        FOR c := 0 TO SIZE(sOutput)-1 DO
            IF p^ = 0C THEN p^ := " " END;
            p.OFS := p.OFS + 1
        END;

        DebugL("Write record");

        Write(StdOut,ADR(sOutput),SIZE(sOutput),cLINE);
        Write(StdOut,ADR(sCRLF),2,cLINE);
        (*
        WriteString( sFILE);
        WriteString(" ");
        WriteString(sWORD);
        WriteString(" ");
        WriteCard(cLINE,1);
        WriteString(" ");
        WriteCard(cOFFSET,1);
        WriteLine("")*)
    END
END WriteIt;

BEGIN
    LineErr("CROSS v1.1 (c) Copyright Bruce M. Axtens, 1993.");
    SetDebugEnv("CROSS$DBG","ON");
    sWhite := " ";
    sSym := "" ; (*"ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz(";*)
    sPunct := "!@#%^&*)-+={}[]|\<>,.:;'/0123456789";
    sQuotes := "'";
    Append(sQuotes,'"');
    Append(sPunct,'"');
    sComments := "*";
    GetArg(sInFile,cTemp);
    IF cTemp=0 THEN
      instruct;
    END;
    WriteErr("Processing: ");
    LineErr(sInFile);

(*    GetArg(sOutFile,cTemp);
    IF cTemp=0 THEN
      instruct;
    END;
    *)
    Open(iBuf,sInFile,READ);
    (*Create(iBuf2,sOutFile,NORMAL);*)
    BlockReadCreate(32767);
    BlockReadLine(iBuf,sTemp,cInLength);
    LOOP
        IF cInLength = 0 THEN EXIT END;
        RightTrim( sTemp);
        cTemp := 0;
        cLimit := Length(sTemp);
        INC(cInCount);
        IF NOT Skipwhite(cTemp, cLimit) THEN END;
        IF NOT IsIn(sTemp[cTemp],sComments) THEN
            LOOP
                IF cTemp > cLimit THEN EXIT END;

                REPEAT
                    bFlag1 := Skipwhite( cTemp, cLimit);
                    bFlag2 := Skippunct( cTemp, cLimit);
                UNTIL (bFlag1 AND bFlag2) OR (cTemp > cLimit);

                IF cTemp > cLimit THEN EXIT END;

                IF (NOT IsIn(sTemp[cTemp],sPunct)) AND (NOT IsIn(sTemp[cTemp],sWhite)) THEN
                    cOffset := cTemp;
                    sSym := '';
                    WHILE (NOT IsIn(sTemp[cTemp],sPunct)) AND (NOT IsIn(sTemp[cTemp],sWhite)) DO
                        IF sTemp[cTemp] = "(" THEN
                            Append(sSym, sTemp[cTemp]);
                            WriteIt( sInFile, sSym, cInCount, cOffset);
                            EXIT
                        END;
                        Append(sSym, sTemp[cTemp]);
                        INC( cTemp);
                        IF cTemp > cLimit THEN
                            WriteIt( sInFile, sSym, cInCount, cOffset);
                            EXIT
                        END;
                    END;
                    WriteIt( sInFile, sSym, cInCount, cOffset)
                ELSE
                    IF IsIn(sTemp[cTemp],sPunct) THEN
                        IF NOT Skippunct( cTemp, cLimit) THEN EXIT END;
                    ELSE
                        IF IsIn(sTemp[cTemp],sWhite) THEN
                            IF NOT Skipwhite( cTemp, cLimit) THEN EXIT END;
                        END
                    END
                END;
                IF IsIn( sTemp[cTemp], sQuotes) THEN
                    sQ := sTemp[cTemp];
                    REPEAT
                        INC(cTemp);
                        IF cTemp > cLimit THEN EXIT END;
                    UNTIL sTemp[cTemp] = sQ
                END;
            END;
         END;
        BlockReadLine(iBuf,sTemp,cInLength);
    END;
    Close(iBuf);
(*    Close(iBuf2);*)
    BlockReadDestroy;
END CROSS.


