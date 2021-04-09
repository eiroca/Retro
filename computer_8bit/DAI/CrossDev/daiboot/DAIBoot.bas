TYPE TypeRec
        Byte AS STRING * 1
END TYPE

TYPE LgBloc
        LgBloc AS STRING * 2
END TYPE

TYPE TOCHeader
        IndexLibre AS INTEGER   ' Pour donner un nom DOS au prochain fichier … enregistrer
        PtrDeb AS INTEGER       ' Pointeur sur premier fichier selon critŠre de tri
        PtrFin AS INTEGER       ' Pointeur sur dernier fichier selon critŠre de tri
        PtrCour AS INTEGER      ' Pointeur sur fichier suivant … lire (cas d'une lecture s‚quentielle)
        NbFic AS INTEGER        ' Nombre de fichiers dans le r‚pertoire
        Filer AS STRING * 60
END TYPE        ' Longueur = 70

TYPE TOCrec
        PtrPrec AS INTEGER       ' Pointeur sur premier fichier selon critŠre de tri
        PtrSuiv AS INTEGER       ' Pointeur sur dernier fichier selon critŠre de tri
        Index AS INTEGER        ' sert … constituer le nom enregistr‚ sur PC
        TypeFic AS INTEGER      ' type de fichier DAI :
                                        ' 0 = programme basic (commande LOAD)
                                        ' 1 = fichier binaire (commande UT puis R)
                                        ' 2 = tableau (commande LOADA)
        LgNom AS INTEGER        ' longueur du nom DAI
        NomDAI AS STRING * 60   ' nom donn‚ par le DAI
END TYPE        ' Longueur = 70

DECLARE SUB AfficherListe ()
DECLARE SUB AfficherMenu ()
DECLARE SUB AjouterDansToc (rec AS TOCrec)
DECLARE SUB AppelerFonction (Touche AS STRING)
DECLARE SUB BarreProg (ACTION AS INTEGER, Courant AS INTEGER, Cible AS INTEGER)
DECLARE SUB bootstrap (AdBoot AS LONG, Org AS STRING)
DECLARE SUB ControleDai ()
DECLARE SUB CreerTOC ()
DECLARE SUB DelaiSaisie (T)
DECLARE SUB EnvoiCar (Car AS INTEGER)
DECLARE SUB GererFichiers ()
DECLARE SUB Init ()
DECLARE SUB LibererControleDai ()
DECLARE SUB LirePrecedantDansToc (Handle AS INTEGER)
DECLARE SUB LireSuivantDansToc (Handle AS INTEGER)
DECLARE SUB LireSurIndexTOC (Index AS INTEGER, rec AS ANY)
DECLARE SUB LireToc (NomFIc AS STRING, Sens AS INTEGER)
DECLARE SUB ListerTOC ()
DECLARE SUB PRINTCOLOR (s AS STRING, C AS INTEGER, RetourLigne AS INTEGER)
DECLARE SUB PRINTPROTOCOLE (Sens AS INTEGER, TypeProto AS INTEGER, Mes AS STRING)
DECLARE SUB Reprise ()
DECLARE SUB RoutineTemporaire (IndexDOS AS INTEGER, TypeF AS INTEGER, Nom AS STRING)
DECLARE SUB SupprimerDansToc (Index AS INTEGER)
DECLARE SUB TesterRechercherDansToc ()
DECLARE SUB WaitAck ()
DECLARE SUB WaitRep (Car AS INTEGER)

DECLARE FUNCTION AffBin$ (n%)
DECLARE FUNCTION AffHex$ (n%)
DECLARE FUNCTION DebDial% ()
DECLARE FUNCTION FinDial% ()
DECLARE FUNCTION GesFicDAI% (ACTION AS INTEGER, TypeFic AS INTEGER, NomFIc AS STRING)
DECLARE FUNCTION readByte$ (Index AS LONG)
DECLARE FUNCTION ReadTypeOfFile$ ()
DECLARE FUNCTION RechercherDansTOC% (TypeFic AS INTEGER, NomDAI AS STRING)
DECLARE FUNCTION RechercherTypeSuivantDansTOC% (TypeFic AS INTEGER)
DECLARE FUNCTION ScrutClavier$ ()
DECLARE FUNCTION CheckSum% (Operation AS INTEGER, ValeurActuelle AS INTEGER, OctetEnCours AS INTEGER)
DECLARE FUNCTION WaitAnyCar% ()
DECLARE FUNCTION WaitCar% (Car AS INTEGER)

REM ========================
REM Constantes protocolaires
REM ========================
CONST ACK = 6
CONST DLE = 16
CONST ENQ = 5
CONST EOT = 4
CONST LOAD = 1
CONST RBLK = 2
CONST SI = 15
CONST SO = 14
CONST DAIPC = 0
CONST PCDAI = 1
CONST DEBDIALP = 0
CONST DIALP = 1
CONST FINDIALP = 2

REM ======================
REM Constantes de couleurs
REM ======================
CONST BLANC = 7
CONST BLANCB = 15
CONST BLEU = 1
CONST BLEUB = 9
CONST CYAN = 3
CONST CYANB = 11
CONST GRIS = 8
CONST JAUNE = 14
CONST MARRON = 6
CONST NOIR = 0
CONST ROUGE = 4
CONST ROUGEB = 12
CONST VERT = 2
CONST VERTB = 10
CONST VIOLET = 5
CONST VIOLETB = 13

CONST FONDECMENU = 0
CONST CARDECMENU = 14

CONST FONDECLISTE = 0
CONST CARDECLISTE = 14

CONST FONDDEBDIALDAI = 2
CONST FONDDEBDIALPC = 2
CONST CARDEBDIALDAI = 15
CONST CARDEBDIALPC = 11

CONST FONDDIALDAI = 2
CONST FONDDIALPC = 2
CONST CARDIALDAI = 15
CONST CARDIALPC = 11

CONST FONDFINDIALDAI = 12
CONST FONDFINDIALPC = 12
CONST CARFINDIALDAI = 10
CONST CARFINDIALPC = 1

CONST ECMENU = 1
CONST ECLISTE = 2

REM ===================
REM Constantes de temps
REM ===================
CONST DELGENBAS = .6

REM ======================
REM Constantes bool‚ennes
REM ======================
CONST FAUX = 0
CONST NONTROUVE = -1
CONST VRAI = 1
CONST DIRECT = 0
CONST INVERSE = 1

REM =================================
REM Constantes pour fonction Checksum
REM =================================
CONST CTRLCKS = 2
CONST INITCKS = 0
CONST MAJCKS = 1

REM ===================================================
REM Constantes gestion fichiers pour fonction GesFicDAI
REM ===================================================
CONST FINIT = 0       ' Pour initialiser la routine de gestion de fichiers
CONST FOPEN = 1       ' Pour ouvrir un fichier DAI
CONST FREADBYTE = 2   ' Pour lire le byte du pointeur courant
CONST FREADBLK = 3    ' pour lire le bloc en courant sans envoyer sur RS232
CONST FREADBLKRS232 = 4  ' Pour lire le bloc courant et l'envoyer sur RS232
CONST FREADTYPEOFFILE = 5  ' Pour lire le type de fichier ouvert
CONST FCLOSE = 6      ' Pour clore le fichier DAI ouvert

REM =================================
REM Constantes pour programme de boot
REM =================================
CONST ADRBOOT = &H2EC             ' Adr implantation pgr sur DAI' d‚but en 2EC
CONST ADRBOOT2000 = &H2000        ' Adr implantation pgr sur DAI' d‚but en 2000
CONST ADRBOOTA000 = 40960       ' Adr implantation pgr sur DAI' d‚but en A000
CONST ORGBOOT = "760"            ' Adr appel version m‚moire basse sur DAI
CONST ORGBOOT2000 = "#200C"       ' Adr appel version m‚moire moyenne sur DAI
CONST ORGBOOTA000 = "#A00C"       ' Adr appel version m‚moire haute sur DAI

CONST LGBOOTSTRAP1 = &H30         ' Long bootstrap
CONST LGSUITEBS1 = &H106          ' long suite bootstrap


REM ==========================
REM Constantes gestion clavier
REM ==========================
CONST TLISTERTOC = "l"
CONST TMENU = "m"
CONST TLIBCTRDAI = "o"
CONST TGESFIC = "g"
CONST TRECHTOC = "f"
CONST TCTRDAI = "r"
CONST TBOOT1 = "b"
CONST TBOOT2 = "B"
CONST TBOOT3 = "a"
CONST TLECPREC = "i"
CONST TLECSUIV = "d"
CONST ESCAPE = 27

'Passer les paramŠtres IndexDOS, TypeFic, NomDAI
'===============================================
'CALL RoutineTemporaire(147, 1, "A")
'END
   
    Init
  
    AfficherMenu

    Touche$ = ""

    PtrFic% = 0

    OPEN "FICDAI.TXT" FOR BINARY AS #2
   
    DO:
        LSR% = INP(AdrLSR%)       ' LSR ‚tat de ligne

        DO WHILE (LSR% AND 1) <> 1 AND (Touche$ <> CHR$(27))
                LSR% = INP(AdrLSR%)
                Touche$ = ScrutClavier
        LOOP
       
        IF Touche$ <> CHR$(27) THEN
                RBR% = INP(AdrRBR%)       ' RBR Tampon r‚ception


                REM ################################################
                REM ### Log des caractŠres re‡us dans le fichier ###
                REM ################################################
                B$ = CHR$(RBR%)
                PtrFic% = PtrFic% + 1
                PUT #2, PtrFic%, B$
  
        END IF


    LOOP UNTIL Touche$ = CHR$(27)



    CLOSE #2
 REM   COM(1) OFF

END

REM ==========================================================================
REM ==== Version m‚moire basse Programme assembleur … charger dans le DAI ====
REM ==========================================================================
DATA2EC:
DATA &H3A,&H03,&HFF,&HE6,&H08,&HCA,&HEC,&H02,&H3A,&H00,&HFF,&HC9,&HF5,&HC5,&HE5,&H21
DATA &H1C,&H03,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&HFE,&H02,&H32,&H06,&HFF,&HCD,&HEC,&H02
DATA &H4F,&HCD,&HEC,&H02,&H47,&HCD,&HEC,&H02,&H77,&H23,&H0B,&H78,&HB1,&HC2,&H11,&H03
DATA &H21,&H4C,&H03,&H22,&HCF,&H02,&H21,&H76,&H03,&H22,&HD2,&H02,&H21,&HCF,&H03,&H22
DATA &HD5,&H02,&H21,&H22,&H04,&H22,&H9B,&H02,&HE5,&HC1,&H2A,&H9D,&H02,&H09,&H22,&H9F
DATA &H02,&H23,&H22,&HA1,&H02,&H23,&H22,&HA3,&H02,&HCD,&HB8,&HDE,&HE1,&HC1,&HF1,&HC9
DATA &HCD,&H05,&H04,&H3E,&H01,&HCD,&HDF,&H03,&H78,&HCD,&HDF,&H03,&H5E,&H16,&H00,&H23
DATA &H7B,&HCD,&HDF,&H03,&HE5,&HD5,&HB7,&HCA,&H6F,&H03,&H7E,&HCD,&HDF,&H03,&H23,&H1D
DATA &HC2,&H66,&H03,&HD1,&HE1,&HCD,&H15,&H04,&H78,&HC9,&HC5,&HD5,&HCD,&H05,&H04,&H3E
DATA &H02,&HCD,&HDF,&H03,&H3E,&H06,&HCD,&HF5,&H03,&H16,&H56,&HCD,&HED,&H03,&HCD,&HEC
DATA &H02,&H47,&HAA,&H07,&H57,&HCD,&HED,&H03,&HCD,&HEC,&H02,&H4F,&HAA,&H07,&H57,&HCD
DATA &HED,&H03,&HCD,&HEC,&H02,&HCD,&HDA,&H03,&H37,&HC2,&HC8,&H03,&H16,&H56,&HCD,&HED
DATA &H03,&HCD,&HEC,&H02,&H77,&H23,&HAA,&H07,&H57,&H0B,&H78,&HB1,&HC2,&HAA,&H03,&HCD
DATA &HED,&H03,&HCD,&HEC,&H02,&HCD,&HDA,&H03,&H37,&HCA,&HC9,&H03,&H3F,&HCD,&H15,&H04
DATA &HD1,&HC1,&HC9,&HCD,&H05,&H04,&H3E,&H04,&HCD,&HDF,&H03,&HC3,&H15,&H04,&HBA,&HC8
DATA &H3E,&H02,&HC9,&HF5,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&HE0,&H03,&HF1,&H32,&H06,&HFF
DATA &HC9,&HF5,&H3E,&H06,&HCD,&HDF,&H03,&HF1,&HC9,&HC5,&HF5,&HC1,&HC5,&HCD,&HEC,&H02
DATA &HC1,&HB8,&HC2,&HF8,&H03,&HC5,&HF1,&HC1,&HC9,&H3E,&H05,&HCD,&HDF,&H03,&H3E,&H06
DATA &HCD,&HF5,&H03,&H3E,&H0E,&HCD,&HDF,&H03,&HC9,&HF5,&H3E,&H0F,&HCD,&HDF,&H03,&H3E
DATA &H06,&HCD,&HF5,&H03,&HF1,&HC9,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00


REM ==========================================================================
REM ==== Version m‚moire haute Programme assembleur … charger dans le DAI ====
REM ==========================================================================
DATA2000:
DATA &H3A,&H03,&HFF,&HE6,&H08,&HCA,&H00,&H20,&H3A,&H00,&HFF,&HC9,&HF5,&HC5,&HE5,&H21
DATA &H30,&H20,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&H12,&H20,&H32,&H06,&HFF,&HCD,&H00,&H20
DATA &H4F,&HCD,&H00,&H20,&H47,&HCD,&H00,&H20,&H77,&H23,&H0B,&H78,&HB1,&HC2,&H25,&H20
DATA &H21,&H60,&H20,&H22,&HCF,&H02,&H21,&H8A,&H20,&H22,&HD2,&H02,&H21,&HE3,&H20,&H22
DATA &HD5,&H02,&H21,&H36,&H21,&H22,&H9B,&H02,&HE5,&HC1,&H2A,&H9D,&H02,&H09,&H22,&H9F
DATA &H02,&H23,&H22,&HA1,&H02,&H23,&H22,&HA3,&H02,&HCD,&HB8,&HDE,&HE1,&HC1,&HF1,&HC9
DATA &HCD,&H19,&H21,&H3E,&H01,&HCD,&HF3,&H20,&H78,&HCD,&HF3,&H20,&H5E,&H16,&H00,&H23
DATA &H7B,&HCD,&HF3,&H20,&HE5,&HD5,&HB7,&HCA,&H83,&H20,&H7E,&HCD,&HF3,&H20,&H23,&H1D
DATA &HC2,&H7A,&H20,&HD1,&HE1,&HCD,&H29,&H21,&H78,&HC9,&HC5,&HD5,&HCD,&H19,&H21,&H3E
DATA &H02,&HCD,&HF3,&H20,&H3E,&H06,&HCD,&H09,&H21,&H16,&H56,&HCD,&H01,&H21,&HCD,&H00
DATA &H20,&H47,&HAA,&H07,&H57,&HCD,&H01,&H21,&HCD,&H00,&H20,&H4F,&HAA,&H07,&H57,&HCD
DATA &H01,&H21,&HCD,&H00,&H20,&HCD,&HEE,&H20,&H37,&HC2,&HDC,&H20,&H16,&H56,&HCD,&H01
DATA &H21,&HCD,&H00,&H20,&H77,&H23,&HAA,&H07,&H57,&H0B,&H78,&HB1,&HC2,&HBE,&H20,&HCD
DATA &H01,&H21,&HCD,&H00,&H20,&HCD,&HEE,&H20,&H37,&HCA,&HDD,&H20,&H3F,&HCD,&H29,&H21
DATA &HD1,&HC1,&HC9,&HCD,&H19,&H21,&H3E,&H04,&HCD,&HF3,&H20,&HC3,&H29,&H21,&HBA,&HC8
DATA &H3E,&H02,&HC9,&HF5,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&HF4,&H20,&HF1,&H32,&H06,&HFF
DATA &HC9,&HF5,&H3E,&H06,&HCD,&HF3,&H20,&HF1,&HC9,&HC5,&HF5,&HC1,&HC5,&HCD,&H00,&H20
DATA &HC1,&HB8,&HC2,&H0C,&H21,&HC5,&HF1,&HC1,&HC9,&H3E,&H05,&HCD,&HF3,&H20,&H3E,&H06
DATA &HCD,&H09,&H21,&H3E,&H0E,&HCD,&HF3,&H20,&HC9,&HF5,&H3E,&H0F,&HCD,&HF3,&H20,&H3E
DATA &H06,&HCD,&H09,&H21,&HF1,&HC9,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00

REM ==========================================================================
REM ==== Version m‚moire haute Programme assembleur … charger dans le DAI ====
REM ==========================================================================
DATAA000:
DATA &H3A,&H03,&HFF,&HE6,&H08,&HCA,&H00,&HA0,&H3A,&H00,&HFF,&HC9,&HF5,&HC5,&HE5,&H21
DATA &H30,&HA0,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&H12,&HA0,&H32,&H06,&HFF,&HCD,&H00,&HA0
DATA &H4F,&HCD,&H00,&HA0,&H47,&HCD,&H00,&HA0,&H77,&H23,&H0B,&H78,&HB1,&HC2,&H25,&HA0
DATA &H21,&H60,&HA0,&H22,&HCF,&H02,&H21,&H8A,&HA0,&H22,&HD2,&H02,&H21,&HE3,&HA0,&H22
DATA &HD5,&H02,&H21,&H36,&HA1,&H22,&H9B,&H02,&HE5,&HC1,&H2A,&H9D,&H02,&H09,&H22,&H9F
DATA &H02,&H23,&H22,&HA1,&H02,&H23,&H22,&HA3,&H02,&HCD,&HB8,&HDE,&HE1,&HC1,&HF1,&HC9
DATA &HCD,&H19,&HA1,&H3E,&H01,&HCD,&HF3,&HA0,&H78,&HCD,&HF3,&HA0,&H5E,&H16,&H00,&H23
DATA &H7B,&HCD,&HF3,&HA0,&HE5,&HD5,&HB7,&HCA,&H83,&HA0,&H7E,&HCD,&HF3,&HA0,&H23,&H1D
DATA &HC2,&H7A,&HA0,&HD1,&HE1,&HCD,&H29,&HA1,&H78,&HC9,&HC5,&HD5,&HCD,&H19,&HA1,&H3E
DATA &H02,&HCD,&HF3,&HA0,&H3E,&H06,&HCD,&H09,&HA1,&H16,&H56,&HCD,&H01,&HA1,&HCD,&H00
DATA &HA0,&H47,&HAA,&H07,&H57,&HCD,&H01,&HA1,&HCD,&H00,&HA0,&H4F,&HAA,&H07,&H57,&HCD
DATA &H01,&HA1,&HCD,&H00,&HA0,&HCD,&HEE,&HA0,&H37,&HC2,&HDC,&HA0,&H16,&H56,&HCD,&H01
DATA &HA1,&HCD,&H00,&HA0,&H77,&H23,&HAA,&H07,&H57,&H0B,&H78,&HB1,&HC2,&HBE,&HA0,&HCD
DATA &H01,&HA1,&HCD,&H00,&HA0,&HCD,&HEE,&HA0,&H37,&HCA,&HDD,&HA0,&H3F,&HCD,&H29,&HA1
DATA &HD1,&HC1,&HC9,&HCD,&H19,&HA1,&H3E,&H04,&HCD,&HF3,&HA0,&HC3,&H29,&HA1,&HBA,&HC8
DATA &H3E,&H02,&HC9,&HF5,&H3A,&H03,&HFF,&HE6,&H10,&HCA,&HF4,&HA0,&HF1,&H32,&H06,&HFF
DATA &HC9,&HF5,&H3E,&H06,&HCD,&HF3,&HA0,&HF1,&HC9,&HC5,&HF5,&HC1,&HC5,&HCD,&H00,&HA0
DATA &HC1,&HB8,&HC2,&H0C,&HA1,&HC5,&HF1,&HC1,&HC9,&H3E,&H05,&HCD,&HF3,&HA0,&H3E,&H06
DATA &HCD,&H09,&HA1,&H3E,&H0E,&HCD,&HF3,&HA0,&HC9,&HF5,&H3E,&H0F,&HCD,&HF3,&HA0,&H3E
DATA &H06,&HCD,&H09,&HA1,&HF1,&HC9,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00,&H00


ToucheF1:
        AppelerFonction (TMENU)
        RETURN
ToucheF2:
        AppelerFonction (TGESFIC)
        RETURN
ToucheF3:
        AppelerFonction (TRECHTOC)
        RETURN
ToucheF4:
        AppelerFonction (TCTRDAI)
        RETURN
ToucheF5:
        AppelerFonction (TBOOT1)
        RETURN
ToucheF6:
        AppelerFonction (TBOOT2)
        RETURN
ToucheF7:
        AppelerFonction (TBOOT3)
        RETURN
ToucheF8:
        AppelerFonction (TLISTERTOC)
        RETURN
ToucheF9:
        AppelerFonction (TLECPREC)
        RETURN
ToucheF10:
        AppelerFonction (TLECSUIV)
        RETURN

FUNCTION AffBin$ (n%)
        Octet$ = ""
        q% = n%
        FOR I% = 1 TO 8
                r% = q% MOD 2
                IF r% = 1 THEN
                        Octet$ = "1" + Octet$
                ELSE
                        Octet$ = "0" + Octet$
                END IF
                q% = INT(q% / 2)
        NEXT I%
        AffBin$ = Octet$
END FUNCTION

SUB AffCTSDSR
            CTSDSR% = MSR0% AND 48
            SELECT CASE CTSDSR%
                CASE 3 'CTS et DSR ont chang‚ simultan‚ment
                        LOCATE 20, 1: PRINT "CTS et DSR ont chang‚ simultan‚ment"
                CASE 2 'DSR a chang‚
                        LOCATE 20, 1: PRINT "DSR a chang‚"
                CASE 1 'CTS a chang‚
                        LOCATE 20, 1: PRINT "CTS a chang‚"
                CASE ELSE 'ni CTS ni DSR n'a chang‚

            END SELECT

END SUB

FUNCTION AffHex$ (n%)

        AffHex$ = RIGHT$("0" + HEX$(n%), 2)

END FUNCTION

SUB AfficherListe
    SCREEN 0, 1, ECLISTE
END SUB

SUB AfficherMenu
    SCREEN 0, 1, ECMENU
END SUB

SUB AjouterDansToc (rec AS TOCrec)

        DIM Header AS TOCHeader
        DIM RecFin AS TOCrec
        DIM Handle AS INTEGER

        Handle = 255

        OPEN "TOC" FOR RANDOM ACCESS READ WRITE LOCK READ WRITE AS Handle LEN = 70

        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                       \"

        GET Handle, 1, Header

        IndexLibre% = Header.IndexLibre
        PtrFin% = Header.PtrFin
        NbFic% = Header.NbFic

        Header.PtrFin = Header.IndexLibre
        Header.IndexLibre = Header.IndexLibre + 1
        Header.NbFic = Header.NbFic + 1
        Header.PtrCour = Header.PtrFin
        IF PtrFin% = 1 THEN Header.PtrDeb = 2   'Cas o— la TOC est initialement vide

        PUT Handle, 1, Header


        IF PtrFin% = 1 THEN      'Dans ce cas c'est le premier enregistrement
                rec.PtrPrec = 2  'qu'on ajoute, dans ces conditions on peut
                                 ' se permettre de fixer le premier indice …
                                 ' 2 (et d'ailleurs il le faut)

        ELSE                     'Sinon c'est qu'il existe d'autres enregistrement
                                 'il faut donc mettre … jour le dernier pour qu'il
                                 'pointe sur le nouveau.
                                 

                GET Handle, PtrFin%, RecFin
                RecFin.PtrSuiv = IndexLibre%
                PUT Handle, PtrFin%, RecFin
                rec.PtrPrec = PtrFin%
        END IF
        rec.PtrSuiv = IndexLibre%
        PUT Handle, IndexLibre%, rec

        CLOSE Handle

END SUB

SUB AppelerFonction (Touche AS STRING)
        SELECT CASE Touche
              
                CASE TBOOT1
                        AfficherListe
                        RESTORE DATA2EC
                        CALL bootstrap(ADRBOOT, ORGBOOT)
                        AfficherMenu

                CASE TBOOT2
                        AfficherListe
                        RESTORE DATA2000
                        CALL bootstrap(ADRBOOT2000, ORGBOOT2000)
                        AfficherMenu
               
                CASE TBOOT3
                        AfficherListe
                        RESTORE DATAA000
                        CALL bootstrap(ADRBOOTA000, ORGBOOTA000)
                        AfficherMenu
              
                CASE TLECSUIV
                        AfficherListe
                        CALL LireToc("", DIRECT)

                CASE TRECHTOC
                        AfficherListe
                        TesterRechercherDansToc
                        AfficherMenu

                CASE TGESFIC
                        AfficherListe
                        GererFichiers
                        AfficherMenu

                CASE TLECPREC
                        AfficherListe
                        CALL LireToc("", INVERSE)
              
                CASE TLISTERTOC
                        AfficherListe
                        ListerTOC
              
                CASE TMENU
                        AfficherMenu
             
                CASE TLIBCTRDAI
                        AfficherListe
                        LibererControleDai
                        AfficherMenu
              
                CASE TCTRDAI
                        AfficherListe
                        ControleDai
                        AfficherMenu
              
        END SELECT

END SUB

SUB BarreProg (ACTION AS INTEGER, Courant AS INTEGER, Cible AS INTEGER)

        DIM MotifProg AS INTEGER
        STATIC X0, Y0 AS INTEGER
        STATIC X AS INTEGER
        DIM XPREC AS INTEGER
       
        DIM CHG AS STRING
        DIM CBG AS STRING
        DIM CHD AS STRING
        DIM CBD AS STRING
        DIM Haut AS STRING
        DIM Bas  AS STRING
        DIM Gauche AS STRING
        DIM Droite AS STRING

        CHG = CHR$(201)
        CBG = CHR$(200)
        CHD = CHR$(187)
        CBD = CHR$(188)
        Haut = CHR$(205)
        Bas = CHR$(205)
        Gauche = CHR$(186)
        Droite = CHR$(186)

      

        MotifProg = 219

        IF ACTION = 0 THEN 'Initialisation
                Y0 = CSRLIN
                X0 = POS(0)
                X = POS(0)
                PRINT CHG; STRING$(20, Haut); CHD: LOCATE CSRLIN, X0
                PRINT Gauche; STRING$(20, " "); Droite: LOCATE CSRLIN, X0
                PRINT CBG; STRING$(20, Bas); CBD; : LOCATE CSRLIN - 1, X0 + 1
        END IF

        IF ACTION = 1 THEN 'MAJ barre progression
                XPREC = X
                X = X0 + (100 * (Courant / Cible) \ 5)
                IF X <> (X0) THEN
                  IF (X - XPREC) > 1 THEN
                        LOCATE CSRLIN, XPREC + 1: PRINT STRING$(X - XPREC, CHR$(MotifProg));
                  ELSE
                        LOCATE CSRLIN, X: PRINT CHR$(MotifProg);
                  END IF
                END IF
        END IF

END SUB

SUB bootstrap (AdBoot AS LONG, Org AS STRING)
        SHARED AdrTHR%
        DIM FINLIGNE AS STRING
        FINLIGNE = CHR$(13) + CHR$(10)
        DIM bytestr AS STRING * 1  'one byte transfers

        B$ = LTRIM$(STR$(AdBoot))
        B2$ = LTRIM$(STR$(AdBoot + LGBOOTSTRAP1 - 1))
        A$ = "POKE #FF06,16:FOR X=" + B$ + " TO " + B2$ + ":WAIT MEM #FF03,8:POKE X,PEEK(#FF00):NEXT X:CALLM " + Org + ":POKE 662,0" + CHR$(13)
        GOSUB EnvoiChaine
       
        tmp% = WaitCar(DLE)

REM        print "Génial"

        FOR X1% = 1 TO LGBOOTSTRAP1
                DelaiSaisie (.05)

                READ X%
REM               PRINT "X%=";X%
                A$ = CHR$(X%)
                GOSUB EnvoiChaine
        NEXT X1%
 BBB:
        tmp% = WaitCar(DLE)
       
        IF tmp% <> DLE THEN 
            print "Car reçu =";tmp%
            print "boucle"
            GOTO BBB
        END IF
        
        Print "Génial2"

        LSB% = LGSUITEBS1 MOD 256
        MSB% = LGSUITEBS1 \ 256

        PRINT "LSB = "; LSB%
        PRINT "MSB = "; MSB%
        
        EnvoiCar (LSB%) ' Envoi de la longueur de la suite du programme
        EnvoiCar (MSB%)

        FOR I% = 1 TO LGSUITEBS1
                READ X%
                EnvoiCar (X%)
        NEXT I%

        GOTO FBootStrap

EnvoiChaine:
        FOR I% = 1 TO LEN(A$)
            DelaiSaisie (.05)
            bytestr=MID$(A$, I%, 1):PUT #1, , bytestr
        NEXT I%
        RETURN

FBootStrap:
END SUB

FUNCTION CheckSum% (Operation AS INTEGER, ValeurActuelle AS INTEGER, OctetEnCours AS INTEGER)

SELECT CASE Operation

    CASE INITCKS
         CheckSum% = &H56
    CASE MAJCKS
         REM XOR + rotation gauche et recopie du bit7 dans le bit0
         CheckSum% = ((((ValeurActuelle XOR OctetEnCours) * 2) \ 256) + ((ValeurActuelle XOR OctetEnCours) * 2)) MOD 256
    CASE CTRLCKS
        REM Si le r‚sultat est 0 alors c'est que le checksum est bon
        CheckSum% = ValeurActuelle XOR OctetEnCours
    CASE ELSE
        CheckSum% = ValeurActuelle

END SELECT

END FUNCTION

SUB ControleDai
    DIM bytestr AS STRING * 1  'one byte transfers

    bytestr =" "
    PUT #1,, bytestr

END SUB

SUB CreerTOC
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
        DIM Handle AS INTEGER

        Handle = 255

        OPEN "TOC" FOR RANDOM ACCESS WRITE LOCK WRITE AS Handle LEN = 70

        FHD$ = "\   \ \   \ \   \ &"
        FLD$ = "##### ##### #####  &"
     
        Header.IndexLibre = 2
        Header.PtrDeb = 1
        Header.PtrFin = 1
        Header.PtrCour = 1
        Header.NbFic = 0
        Header.Filer = SPACE$(60)
        PUT Handle, 1, Header

        CLOSE Handle
END SUB

FUNCTION DebDial%
        DIM Car AS INTEGER
        DIM Bruno%
       

        Car = WaitCar(ENQ)
       
        IF Car <> ESCAPE THEN

                CALL PRINTPROTOCOLE(DAIPC, DEBDIALP, "ENQ")
                EnvoiCar (ACK)

                CALL PRINTPROTOCOLE(PCDAI, DEBDIALP, "ACK")
                
                Car = WaitAnyCar%
                SELECT CASE Car
             
                        CASE SO
                                CALL PRINTPROTOCOLE(DAIPC, DEBDIALP, "SO")
                        CASE ESCAPE
                                PRINT "Touche ESCAPE !"
                        CASE ELSE
                                CALL PRINTCOLOR("FONCTION DebDial% CAS NON PREVU", ROUGEB, VRAI)
                                Print "Car ="; Car
                END SELECT
        END IF

        DebDial% = Car
END FUNCTION

SUB DelaiSaisie (T)
        time0 = TIMER
                      
        DO
                time1 = TIMER
        LOOP WHILE (time1 - time0) < T

REM        FOR ZZ = 1 TO 8000
REM        NEXT ZZ

END SUB

SUB EnvoiCar (Car AS INTEGER)
    DIM bytestr AS STRING * 1  'one byte transfers

    bytestr = CHR$(Car)
    PUT #1, ,bytestr

END SUB

FUNCTION FinDial%
        DIM Car AS INTEGER

        Car = WaitCar(SI)
        IF Car <> ESCAPE THEN
                CALL PRINTPROTOCOLE(DAIPC, FINDIALP, "SI")
                EnvoiCar (ACK)
                CALL PRINTPROTOCOLE(PCDAI, FINDIALP, "ACK")
                FinDial% = Car
                PRINT STRING$(80, 176)
        ELSE
                FinDial% = ESCAPE
        END IF

END FUNCTION

SUB GererFichiers

    DIM fin AS INTEGER
           
    fin = FAUX

    CALL PRINTCOLOR("D‚but GererFichiers", CYANB, VRAI)

    DO
        SELECT CASE DebDial%
          CASE SO
              SELECT CASE WaitAnyCar%
                  CASE LOAD
                      CALL PRINTPROTOCOLE(DAIPC, DIALP, "LOAD")
                                                                                                                                                                                                                       
                      Car1% = WaitAnyCar%
                      TypeFic% = Car1% - 48
                      Mes$ = "TypeFic (" + LTRIM$(STR$(TypeFic%)) + ")"
                      CALL PRINTPROTOCOLE(DAIPC, DIALP, Mes$)

                      Lg% = WaitAnyCar%
                      Mes$ = "LgNomFic (" + LTRIM$(STR$(Lg%)) + ")"
                      CALL PRINTPROTOCOLE(DAIPC, DIALP, Mes$)

                      IF Lg% <> 0 THEN
                          NomFIc$ = ""
                          DO
                                  CarNom% = WaitAnyCar%
                                  NomFIc$ = NomFIc$ + CHR$(CarNom%)
                                  Lg% = Lg% - 1
                          LOOP UNTIL Lg% = 0
                                                                                                                                                                                                                                                           
                          Mes$ = "NomFic (" + NomFIc$ + ")"
                          CALL PRINTPROTOCOLE(DAIPC, DIALP, Mes$)
                                                                                                                                                                                                                                                           
                          tmp% = GesFicDAI(FOPEN, TypeFic%, NomFIc$)
'                          tmp% = GesFicDAI(FREADTYPEOFFILE, 0, "") ' Pour se positionner sur le bloc 1
                      ELSE
                          PRINT "Pas de nom de fichier indiqu‚"
                          PRINT "On charge le fichier suivant"
                          tmp% = GesFicDAI(FOPEN, TypeFic%, "")
'                          tmp% = GesFicDAI(FREADTYPEOFFILE, 0, "") ' Pour se positionner sur le bloc 1
                      END IF
                      Car% = FinDial%
                  CASE RBLK
                      CALL PRINTPROTOCOLE(DAIPC, DIALP, "RBLK")
                      EnvoiCar (ACK)
                      CALL PRINTPROTOCOLE(PCDAI, DIALP, "ACK")
                      tmp% = GesFicDAI(FREADBLKRS232, 0, "")
                      Car% = FinDial%
                  CASE EOT
                      CALL PRINTPROTOCOLE(DAIPC, DIALP, "EOT")
                      tmp% = GesFicDAI(FCLOSE, 0, "")
                      Car% = FinDial%
                  CASE ELSE
                      CALL PRINTCOLOR("Cas non pr‚vu", ROUGEB, VRAI)
                      END
              END SELECT
          CASE ESCAPE
                  fin = VRAI
        END SELECT
    LOOP UNTIL fin = VRAI

    CALL PRINTCOLOR("Fin GererFichiers", CYANB, VRAI)

END SUB

FUNCTION GesFicDAI% (ACTION AS INTEGER, TypeFic AS INTEGER, NomFIc AS STRING)

    DIM Header AS TOCHeader
    DIM rec AS TOCrec
    STATIC Index AS INTEGER
    STATIC FichierOuvert AS INTEGER
    DIM CR AS INTEGER
    STATIC PtrFic AS LONG
    DIM Lg AS TypeRec
    DIM RS232 AS INTEGER
    DIM LgBloc AS INTEGER, I AS INTEGER
    DIM A AS INTEGER

    SELECT CASE ACTION
        CASE FINIT
            FichierOuvert = FAUX
            Index = NONTROUVE
            PtrFic = 0
        CASE FOPEN
            IF FichierOuvert = VRAI THEN
                STOP ' Traiter cette erreur si elle survient
            ELSE
                IF NomFIc = "" THEN
                       Index = RechercherTypeSuivantDansTOC(TypeFic)
                ELSE
                       Index = RechercherDansTOC(TypeFic, NomFIc)
                END IF


                IF Index <> NONTROUVE THEN
                       CALL LireSurIndexTOC(Index, rec)
                      
                       NomFIc$ = RIGHT$((STRING$(4, 48) + LTRIM$(STR$(rec.Index))), 5)
                       PRINT "Nom DOS : "; NomFIc$

                       OPEN NomFIc$ FOR BINARY ACCESS READ AS #3 LEN = 1
                       FichierOuvert = VRAI
                       PtrFic = 2
                       RS232 = FAUX
                       GOSUB GesFicDAIReadBlk
                       
                END IF

                GesFicDAI% = Index
            END IF
        CASE FCLOSE
            IF FichierOuvert = VRAI THEN
                CLOSE #3
                FichierOuvert = FAUX
                PtrFic = 0
                CR = Index
                Index = NONTROUVE
            ELSE
                STOP ' Traiter cette erreur si elle survient
            END IF
            GesFicDAI% = CR
        CASE FREADTYPEOFFILE
            GET #3, 1, Lg
            PtrFic = 2
            GesFicDAI% = ASC(Lg.Byte)

        CASE FREADBYTE
            GET #3, PtrFic, Lg
            PtrFic = PtrFic + 1
            GesFicDAI% = ASC(Lg.Byte)
        CASE FREADBLK
            RS232 = FAUX
            GOSUB GesFicDAIReadBlk
        CASE FREADBLKRS232
            RS232 = VRAI
            GOSUB GesFicDAIReadBlk
    END SELECT
    GOTO FinGesFicDAI:

FREADBLKRS232:
  IF RS232 = VRAI THEN
    WaitAck
    EnvoiCar (A)
  END IF
    RETURN

GesFicDAIReadBlk:
    Cks% = CheckSum(INITCKS, 0, 0)      'initialisation du checksum
    A = GesFicDAI(FREADBYTE, 0, "")     ' Lecture MSB longueur bloc
            Cks% = CheckSum(MAJCKS, Cks%, A) 'MAJ checksum
            GOSUB FREADBLKRS232:
            LgBloc = A * 256
            PRINT AffHex$(A);
            
    A = GesFicDAI(FREADBYTE, 0, "") ' Lecture LSB longueur bloc
            Cks% = CheckSum(MAJCKS, Cks%, A) 'MAJ checksum
            GOSUB FREADBLKRS232:
            LgBloc = LgBloc + A
            PRINT " "; AffHex$(A);

            PRINT " => Longueur de bloc = "; LgBloc

    A = GesFicDAI(FREADBYTE, 0, "") ' Lecture Checksum longueur bloc
            GOSUB FREADBLKRS232:
            PRINT USING "&    => Checksum de la longueur de bloc"; AffHex$(A)
            Cks% = CheckSum(CTRLCKS, Cks%, A) ' Contr“le checksum
            IF Cks% = 0 THEN
               PRINT "Checksum OK"
            ELSE
               PRINT "Checksum erron‚"
               STOP
            END IF

    Cks% = CheckSum(INITCKS, 0, 0)      'initialisation du checksum
    I = 0

    CALL BarreProg(0, 0, LgBloc)

    DO
        A = GesFicDAI(FREADBYTE, 0, "")
        Cks% = CheckSum(MAJCKS, Cks%, A) 'MAJ checksum
        I = I + 1
        CALL BarreProg(1, I, LgBloc)
        GOSUB FREADBLKRS232:
    LOOP WHILE I < LgBloc

    KEY OFF
    LOCATE CSRLIN + 1, POS(0): PRINT
    KEY ON
    PRINT "Nb octets lus dans le bloc = "; I

    A = GesFicDAI(FREADBYTE, 0, "") ' Checksum longueur bloc
            GOSUB FREADBLKRS232:
            PRINT USING "&    => Checksum du bloc"; AffHex$(A)
            
    Cks% = CheckSum(CTRLCKS, Cks%, A) ' Contr“le checksum
            
    IF Cks% = 0 THEN
       PRINT "Checksum OK"
    ELSE
       PRINT "Checksum erron‚"
       STOP
    END IF

    RETURN


FinGesFicDAI:



END FUNCTION

SUB Init
    SHARED AdrTHR%, AdrBA%, AdrRBR%, AdrIER%, AdrIIR%, AdrLCR%, AdrMCR%, AdrLSR%, AdrMSR%
  
    CLS

    OPEN "COM1:9600,N,8,1,CD0,CS0,DS0,OP0,RS,TB2048,RB2048" FOR RANDOM AS #1

    AdrBA% = &H3F8      'COM1
    AdrRBR% = AdrBA%
    AdrIER% = AdrBA% + 1
    AdrIIR% = AdrBA% + 2
    AdrLCR% = AdrBA% + 3
    AdrMCR% = AdrBA% + 4
    AdrLSR% = AdrBA% + 5
    AdrMSR% = AdrBA% + 6
    AdrTHR% = AdrBA%
   
 REM   Reprise  'Met DTR et RTS … 1 : cet ordinateur se comporte comme un ETCD
   
 REM   OUT AdrIER%, 0       ' Invalide les interruptions

    tmp% = GesFicDAI(FINIT, 0, "")

    SCREEN 0, 1, ECMENU
REM    _FULLSCREEN
    COLOR CARDECMENU, FONDECMENU
  
    CLS
    KEY 1, "MENU"
    KEY 2, "GesFic"
    KEY 3, "Recherche"
    KEY 4, "CtrDAI"
    KEY 5, "Boot1"
    KEY 6, "Boot2"
    KEY 7, "Boot3"
    KEY 9, "Prec"
    KEY 10, "Suiv"
    KEY 8, "DIR"


    KEY ON
    KEY(1) ON
    KEY(2) ON
    KEY(3) ON
    KEY(4) ON
    KEY(5) ON
    KEY(6) ON
    KEY(7) ON
    KEY(8) ON
    KEY(9) ON
    KEY(10) ON

    ON KEY(1) GOSUB ToucheF1
    ON KEY(2) GOSUB ToucheF2
    ON KEY(3) GOSUB ToucheF3
    ON KEY(4) GOSUB ToucheF4
    ON KEY(5) GOSUB ToucheF5
    ON KEY(6) GOSUB ToucheF6
    ON KEY(7) GOSUB ToucheF7
    ON KEY(8) GOSUB ToucheF8
    ON KEY(9) GOSUB ToucheF9
    ON KEY(10) GOSUB ToucheF10


    LOCATE 1, 10: PRINT "Affectation des touches du menu"
    LOCATE 2, 10: PRINT "==============================="
    PRINT
  
    PRINT "  ESC ==> fin programme"
    PRINT "  a   ==> bootstrap version A000 sur le DAI"
    PRINT "  b   ==> bootstrap version  2EC sur le DAI"
    PRINT "  B   ==> bootstrap version 2000 sur le DAI"
    PRINT "  d   ==> lecture TOC sans nom de fichier sens DIRECT"
    PRINT "  f   ==> rechercher un enregistrement dans la TOC"
    PRINT "  g   ==> le gestionnaire de fichiers … l'‚coute du DAI"
    PRINT "  i   ==> lecture TOC sans nom de fichier sens INVERSE"
    PRINT "  l   ==> lister TOC"
    PRINT "  m   ==> r‚afficher ce menu"
    PRINT "  o   ==> lib‚rer le contr“le du DAI"
    PRINT "  r   ==> prendre contr“le du DAI aprŠs un reset de ce dernier"

    SCREEN 0, 1, ECLISTE
    COLOR CARDECLISTE, FONDECLISTE
    CLS


END SUB

SUB LibererControleDai
       
        SHARED AdrTHR%

       
        A$ = "POKE #296,0"
        A$ = A$ + CHR$(13)
        A$ = A$ + CHR$(10)

        PRINT A$
       
        FOR I% = 1 TO LEN(A$)
                DelaiSaisie (.01)
                print "CHANGER ICI POUR WINDOWS7"
                OUT AdrTHR%, ASC(MID$(A$, I%, 1))

        NEXT I%

END SUB

SUB LirePrecedantDansToc (Handle AS INTEGER)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
     
        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                                         \"
     
        GET Handle, 1, Header
                    
        IF Header.PtrCour <> 1 THEN
                PRINT USING FHD$; "TypF."; "Index"; "LgNom"; "PtrPrec"; "PtrSuiv"; "Nom De Fichier DAI"
                PRINT USING FHD$; "====="; "====="; "====="; "======="; "======="; "=================="
              
                GET Handle, Header.PtrCour, rec

                IF Header.PtrCour = Header.PtrDeb THEN
                        Header.PtrCour = Header.PtrFin
                ELSE
                        Header.PtrCour = rec.PtrPrec
                END IF
           
                PUT Handle, 1, Header
                            
                GET Handle, Header.PtrCour, rec
                   
                PRINT USING FLD$; rec.TypeFic; rec.Index; rec.LgNom; rec.PtrPrec; rec.PtrSuiv; rec.NomDAI
              
        ELSE
                PRINT "Pas de fichier dans ce r‚pertoire"
        END IF
END SUB

SUB LireSuivantDansToc (Handle AS INTEGER)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
      
        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                                      \"
      
        GET Handle, 1, Header
                     
        IF Header.PtrCour <> 1 THEN
                PRINT USING FHD$; "TypF."; "Index"; "LgNom"; "PtrPrec"; "PtrSuiv"; "Nom De Fichier DAI"
                PRINT USING FHD$; "====="; "====="; "====="; "======="; "======="; "=================="
                             
                GET Handle, Header.PtrCour, rec
                    
                PRINT USING FLD$; rec.TypeFic; rec.Index; rec.LgNom; rec.PtrPrec; rec.PtrSuiv; rec.NomDAI
              
                IF Header.PtrCour = Header.PtrFin THEN
                        Header.PtrCour = Header.PtrDeb
                ELSE
                        Header.PtrCour = rec.PtrSuiv
                END IF
               
                PUT Handle, 1, Header

        ELSE
                PRINT "Pas de fichier dans ce r‚pertoire"
        END IF

END SUB

SUB LireSurIndexTOC (Index AS INTEGER, rec AS TOCrec)
        DIM Header AS TOCHeader
        DIM Handle AS INTEGER

        Handle = FREEFILE
       
       
        OPEN "TOC" FOR RANDOM ACCESS READ WRITE LOCK READ WRITE AS Handle LEN = 70

        GET Handle, Index, rec

        GET Handle, 1, Header

        Header.PtrCour = rec.PtrSuiv
        PUT Handle, 1, Header

        CLOSE Handle


END SUB

SUB LireToc (NomFIc AS STRING, Sens AS INTEGER)

        DIM Header AS TOCHeader
        DIM rec AS TOCrec
        DIM Handle AS INTEGER

        Handle = FREEFILE
       
        OPEN "TOC" FOR RANDOM ACCESS READ WRITE LOCK READ WRITE AS Handle LEN = 70

        IF NomFIc = "" THEN
                IF Sens = DIRECT THEN
                        LireSuivantDansToc (Handle)
                ELSE
                        LirePrecedantDansToc (Handle)
                END IF
        ELSE
                PRINT "Routine … ‚crire"
        END IF
      

        CLOSE Handle

END SUB

SUB ListerTOC
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
        DIM Ligne AS INTEGER

        Handle = FREEFILE
       
        KEY(8) OFF

        OPEN "TOC" FOR RANDOM ACCESS READ LOCK READ AS Handle LEN = 70
      

        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                                              \"
      
        GET Handle, 1, Header
        PRINT "Index Libre :"; Header.IndexLibre
        PRINT "PtrDeb      :"; Header.PtrDeb
        PRINT "PtrFin      :"; Header.PtrFin
        PRINT "PtrCour     : "; Header.PtrCour
        PRINT "NbFic       :"; Header.NbFic

        
        GOSUB Titres
        Lignes = 0
       
        NbFic% = Header.NbFic
        PtrFic% = Header.PtrDeb

        WHILE NbFic% > 0
                GET Handle, PtrFic%, rec
                IF Lignes = 10 THEN
                        PRINT "Appuyer sur la touche ESPACE pour continuer"
                        DO
                        LOOP WHILE INKEY$ <> " "
                        GOSUB Titres
                        Lignes = 0
                END IF
                PRINT USING FLD$; rec.TypeFic; rec.Index; rec.LgNom; rec.PtrPrec; rec.PtrSuiv; rec.NomDAI
                Lignes = Lignes + 1
                PtrFic% = rec.PtrSuiv
                NbFic% = NbFic% - 1
        WEND

        CLOSE Handle
        KEY(8) ON
        GOTO FinListerTOC

Titres:
        PRINT USING FHD$; "TypF."; "Index"; "LgNom"; "PtrPrec"; "PtrSuiv"; "Nom De Fichier DAI"
        PRINT USING FHD$; "====="; "====="; "====="; "======="; "======="; "=================="

        RETURN

FinListerTOC:
END SUB

SUB PRINTCOLOR (s AS STRING, C AS INTEGER, RetourLigne AS INTEGER)
        COLOR C
        IF RetourLigne = VRAI THEN
                PRINT s
        ELSE
                PRINT s;
        END IF
        COLOR CARDECLISTE, FONDECLISTE
END SUB

SUB PRINTPROTOCOLE (Sens AS INTEGER, TypeProto AS INTEGER, Mes AS STRING)

     DIM FONdPC AS INTEGER
     DIM CarPC AS INTEGER
     DIM FONdDAI AS INTEGER
     DIM CarDAI AS INTEGER

     SELECT CASE TypeProto
        CASE DEBDIALP
                FONdDAI = FONDDEBDIALDAI
                FONdPC = FONDDEBDIALPC
                CarDAI = CARDEBDIALDAI
                CarPC = CARDEBDIALPC

        CASE DIALP
                FONdDAI = FONDDIALDAI
                FONdPC = FONDDIALPC
                CarDAI = CARDIALDAI
                CarPC = CARDIALPC

        CASE FINDIALP
                FONdDAI = FONDFINDIALDAI
                FONdPC = FONDFINDIALPC
                CarDAI = CARFINDIALDAI
                CarPC = CARFINDIALPC

     END SELECT

     IF Sens = DAIPC THEN
        COLOR CarDAI, FONdDAI
        PRINT "<-- "; Mes;
        COLOR CARDECLISTE, FONDDECLISTE
        PRINT
     ELSE
        COLOR CarPC, FONdPC
        PRINT Mes; " -->";
        COLOR CARDECLISTE, FONDDECLISTE
        PRINT
     END IF
END SUB

FUNCTION readByte$ (Index AS LONG)

        STATIC IndexFic AS LONG

        IF Index <> 0 THEN IndexFic = Index

        DIM Lg AS TypeRec
       
        GET #3, IndexFic, Lg
        IndexFic = IndexFic + 1

        readByte$ = Lg.Byte

END FUNCTION

FUNCTION ReadTypeOfFile$
        ReadTypeOfFile$ = readByte(1)
END FUNCTION

FUNCTION RechercherDansTOC% (TypeFic AS INTEGER, NomDAI AS STRING)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
        DIM Handle AS INTEGER
        Handle = FREEFILE

        OPEN "TOC" FOR RANDOM ACCESS READ LOCK READ AS Handle LEN = 70
    

        GET Handle, 1, Header
      
        NbFic% = Header.NbFic
        PtrFic% = Header.PtrCour
        Trouve% = FAUX

        WHILE (NbFic% > 0 AND Trouve% = FAUX)
                GET Handle, PtrFic%, rec
              
                IF (rec.TypeFic = TypeFic) THEN
                        IF LEFT$(rec.NomDAI, LEN(NomDAI)) = NomDAI THEN
                                Trouve% = VRAI
                        ELSE
                            IF rec.PtrSuiv <> PtrFic% THEN
                                PtrFic% = rec.PtrSuiv
                            ELSE
                                PtrFic% = Header.PtrDeb
                            END IF
                        END IF
                ELSE
                    IF rec.PtrSuiv <> PtrFic% THEN
                        PtrFic% = rec.PtrSuiv
                    ELSE
                        PtrFic% = Header.PtrDeb
                    END IF
                END IF
              
                NbFic% = NbFic% - 1
        WEND
      
        CLOSE Handle
      
        IF Trouve% = VRAI THEN
                RechercherDansTOC% = PtrFic%
        ELSE
                RechercherDansTOC% = NONTROUVE
        END IF


END FUNCTION

FUNCTION RechercherTypeSuivantDansTOC% (TypeFic AS INTEGER)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec

        Handle = FREEFILE

        OPEN "TOC" FOR RANDOM ACCESS READ LOCK READ AS Handle LEN = 70
     

        GET Handle, 1, Header
       
        NbFic% = Header.NbFic
        PtrFic% = Header.PtrCour
        Trouve% = FAUX
        
        WHILE (NbFic% > 0 AND Trouve% = FAUX)
                GET Handle, PtrFic%, rec
               
                IF (rec.TypeFic = TypeFic) THEN
                        Trouve% = VRAI
                ELSE
                        PtrFic% = rec.PtrSuiv
                END IF
               
                NbFic% = NbFic% - 1
        WEND
       
        CLOSE Handle
       
        IF Trouve% = VRAI THEN
                RechercherTypeSuivantDansTOC% = PtrFic%
        ELSE
                RechercherTypeSuivantDansTOC% = NONTROUVE
        END IF

END FUNCTION

SUB Reprise
        SHARED AdrMCR%

        MCR% = INP(AdrMCR%)       ' MCR commande de modem

                'mise … 1 de DTR (broche 20 DB25) ou (broche 4 DB9)
                'mise … 1 de RTS (broche 4 DB25) ou (broche 7 DB9)
        OUT (AdrMCR%), (MCR% OR 3)
END SUB

SUB RoutineTemporaire (IndexDOS AS INTEGER, TypeF AS INTEGER, Nom AS STRING)

    DIM Re AS TOCrec

    NomFIc$ = Nom

    Re.TypeFic = TypeF
    Re.LgNom = LEN(NomFIc$)
    Re.NomDAI = NomFIc$
    Re.Index = IndexDOS

    CALL AjouterDansToc(Re)


    tmp% = GesFicDAI(FOPEN, TypeF, NomFIc$)
    tmp% = GesFicDAI(FREADTYPEOFFILE, 0, "")
    PRINT "Type de fichier : "; tmp%
    tmp% = GesFicDAI(FREADBLK, 0, "")
    tmp% = GesFicDAI(FREADBLK, 0, "")
    tmp% = GesFicDAI(FREADBLK, 0, "")
    tmp% = GesFicDAI(FCLOSE, 0, "")


END SUB

FUNCTION ScrutClavier$
        DIM T AS STRING
       
        T = INKEY$
        IF T <> CHR$(ESCAPE) THEN

                CALL AppelerFonction(T)

        END IF
       
        ScrutClavier$ = T
END FUNCTION

SUB SupprimerDansToc (Index AS INTEGER)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec

        DIM cas, Ptp, Pts, Handle AS INTEGER


        Handle = FREEFILE

        OPEN "TOC" FOR RANDOM ACCESS READ WRITE LOCK READ WRITE AS Handle LEN = 70

        GET Handle, Index, rec

        Ptp = rec.PtrPrec
        Pts = rec.PtrSuiv

        cas = 0
        IF Index = rec.PtrPrec THEN cas = cas + 1
        IF Index = rec.PtrSuiv THEN cas = cas + 2

        SELECT CASE cas
                CASE 0  ' L'enregistrement a supprimer est coinc‚ entre 2 autres

                        ' Mise … jour de l'enregistrement pr‚c‚dent
                        GET Handle, Ptp, rec
                        rec.PtrSuiv = Pts
                        PUT Handle, Ptp, rec

                        ' Mise … jour de l'enregistrement suivant
                        GET Handle, Pts, rec
                        rec.PtrPrec = Ptp
                        PUT Handle, Pts, rec
                       
                        ' Mise … jour du Header
                        GET Handle, 1, Header
                        IF Header.PtrCour = Index THEN Header.PtrCour = Pts
                        Header.NbFic = Header.NbFic - 1
                        PUT Handle, 1, Header

                        CLOSE Handle

                CASE 1  ' L'enregistrement a supprimer est le premier d'une liste
                       
                        ' Mise … jour de l'enregistrement suivant
                        GET Handle, Pts, rec
                        rec.PtrPrec = Pts
                        PUT Handle, Pts, rec

                        ' Mise … jour du Header
                        GET Handle, 1, Header
                        Header.PtrDeb = Pts
                        IF Header.PtrCour = Index THEN Header.PtrCour = Pts
                        Header.NbFic = Header.NbFic - 1
                        PUT Handle, 1, Header

                        CLOSE Handle

                CASE 2  ' L'enregistrement a supprimer est le dernier d'une liste

                        ' Mise … jour de l'enregistrement pr‚c‚dent
                        GET Handle, Ptp, rec
                        rec.PtrSuiv = Ptp
                        PUT Handle, Ptp, rec

                        ' Mise … jour du Header
                        GET Handle, 1, Header
                        Header.PtrFin = Ptp
                        IF Header.PtrCour = Index THEN Header.PtrCour = Ptp
                        Header.NbFic = Header.NbFic - 1
                        PUT Handle, 1, Header

                        CLOSE Handle

                CASE 3  ' L'enregistrement a supprimer est le seul de la liste
                        CLOSE Handle

                        CreerTOC
        END SELECT

END SUB

SUB TesterRechercherDansToc
        DIM rec AS TOCrec

        PRINT "Si le nom contient des blancs en tˆte, alors mettre le nom entre guillemets"
        INPUT "Nom de fichier … rechercher"; NomDAI$
       
        INPUT "Type de fichier … rechercher"; TypeFic%

        Trouve% = RechercherDansTOC%(TypeFic%, NomDAI$)

        PRINT Trouve%


END SUB

SUB WaitAck
 REM  SHARED AdrRBR%, AdrLSR%
 DIM bytestr AS STRING * 1  'one byte transfers
 RBR%=-1


        DO       
            IF LOC(1) THEN 
                GET #1, , bytestr
                RBR%= ASC(MID$(bytestr, 1, 1))
            END IF
            
       LOOP UNTIL  (RBR%=ACK)

END SUB

FUNCTION WaitAnyCar%
   DIM Touche AS STRING
   DIM bytestr AS STRING * 1  'one byte transfers


   RBR%=-1

  REM      print "Attendu = ["+CHR$(SO)+"]"+"["+CHR$(LOAD)+"]"
        DO       
           Touche = INKEY$
            IF LOC(1) THEN 
                GET #1, , bytestr
                RBR%= ASC(MID$(bytestr, 1, 1))
                PRINT RBR%
            END IF
       
       LOOP UNTIL  (RBR%<>-1) OR (Touche = CHR$(ESCAPE))

        IF Touche = CHR$(ESCAPE) THEN
                WaitAnyCar% = ESCAPE
        ELSE
                WaitAnyCar% = RBR%
        END IF

END FUNCTION

FUNCTION WaitCar% (Car AS INTEGER)
REM   SHARED AdrRBR%, AdrLSR%
   DIM Touche AS STRING
   DIM bytestr AS STRING * 1  'one byte transfers

   DO
           Touche = INKEY$
           GET #1, , bytestr
           RBR%= ASC(MID$(bytestr, 1, 1))

    LOOP UNTIL (RBR% = Car) OR (Touche = CHR$(ESCAPE))

REM print "Coucou"
REM print RBR%
REM print Car
   IF RBR% = Car THEN
        WaitCar% = Car
   ELSE
        WaitCar% = ESCAPE

   END IF

END FUNCTION

SUB WaitRep (Car AS INTEGER)
   SHARED AdrRBR%


   DO
        RBR% = INP(AdrRBR%)       ' RBR Tampon r‚ception
   LOOP UNTIL RBR% = Car

END SUB

