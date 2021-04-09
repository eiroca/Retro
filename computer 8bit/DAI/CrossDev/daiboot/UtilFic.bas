DECLARE FUNCTION TestParam! ()
DECLARE SUB SupprimerDansTOC (Index AS INTEGER)
DECLARE SUB TesterSupprimerDansToc ()
DECLARE FUNCTION RechercherDansTOC% (TypeFic AS INTEGER, NomDAI AS STRING)
DECLARE SUB TesterRechercherDansToc ()
TYPE OldTOCHeader
        IndexLibre AS INTEGER   ' Pour donner un nom DOS au prochain fichier … enregistrer
        Filer AS STRING * 64
END TYPE ' Longueur =

TYPE TOCHeader
        IndexLibre AS INTEGER   ' Pour donner un nom DOS au prochain fichier … enregistrer
        PtrDeb AS INTEGER       ' Pointeur sur premier fichier selon critŠre de tri
        PtrFin AS INTEGER       ' Pointeur sur dernier fichier selon critŠre de tri
        PtrCour AS INTEGER      ' Pointeur sur fichier suivant … lire (cas d'une lecture s‚quentielle)
        NbFic AS INTEGER        ' Nombre de fichiers dans le r‚pertoire
        Filer AS STRING * 60
END TYPE        ' Longueur = 70

TYPE OldTOCRec
        TypeFic AS INTEGER      ' type de fichier DAI :
                                        ' 0 = programme basic (commande LOAD)
                                        ' 1 = fichier binaire (commande UT puis R)
                                        ' 2 = tableau (commande LOADA)
        Index AS INTEGER        ' sert … constituer le nom enregistr‚ sur PC
        LgNom AS INTEGER        ' longueur du nom DAI
        NomDAI AS STRING * 60   ' nom donn‚ par le DAI
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

CONST DIRECT = 0
CONST INVERSE = 1

CONST NOIR = 0
CONST BLEU = 1
CONST VERT = 2
CONST CYAN = 3
CONST ROUGE = 4
CONST VIOLET = 5
CONST MARRON = 6
CONST BLANC = 7
CONST GRIS = 8
CONST BLEUB = 9
CONST VERTB = 10
CONST CYANB = 11
CONST ROUGEB = 12
CONST VIOLETB = 13
CONST JAUNE = 14
CONST BLANCB = 15

CONST FAUX = 0
CONST VRAI = 1
CONST NONTROUVE = -1

DECLARE SUB LirePrecedantDansToc (Handle AS INTEGER)
DECLARE SUB TesterAjouterDansToc ()
DECLARE SUB LireSuivantDansToc (Handle AS INTEGER)

DECLARE SUB ConvertirTOC ()
DECLARE SUB CreerTOC ()
DECLARE SUB ListerTOC ()
DECLARE SUB LireToc (NomFic AS STRING, Sens AS INTEGER)
DECLARE SUB AjouterDansToc (rec AS TOCrec)

DECLARE SUB AfficherMenu ()
DECLARE SUB ScrutClavier ()
DECLARE SUB PrintColor (s AS STRING, c AS INTEGER)




  
    AfficherMenu
   
    Touche$ = ""

    DO:
        DO WHILE Touche$ <> CHR$(27)
                ScrutClavier
        LOOP
      
    LOOP UNTIL Touche$ = CHR$(27)


END

SUB AfficherMenu
    CLS
    LOCATE 1, 1: PRINT "Appuyer sur Escape pour terminer le pgr"
    PRINT
    PRINT "Appuyer sur d pour tester une lecture sans nom de fichier sens DIRECT"
    PRINT "Appuyer sur i pour tester une lecture sans nom de fichier sens INVERSE"
    PRINT "Appuyer sur c convertir TOC en NewTOC"
    PRINT "Appuyer sur l lister NewTOC"
    PRINT "Appuyer sur n cr‚er une NewTOC vierge "
    PRINT "Appuyer sur m pour r‚afficher ce menu"
    PRINT "Appuyer sur a pour ajouter un enregistrement dans la TOC"
    PRINT "Appuyer sur r pour rechercher un enregistrement dans la TOC"
    PRINT "Appuyer sur s pour supprimer un enregistrement dans la TOC"
    PRINT
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

SUB ConvertirTOC

        DIM OldHeader AS OldTOCHeader
        DIM OldRec AS OldTOCRec

        DIM Header AS TOCHeader
        DIM rec AS TOCrec

        CLS
        CALL PrintColor("Conversion de OLDTOC vers TOC", ROUGEB)
        PRINT

        Handle = FREEFILE

        OPEN "OLDTOC" FOR RANDOM ACCESS READ LOCK READ AS Handle LEN = 66

        FHD$ = "\   \ \   \ \   \ &"
        FLD$ = "##### ##### #####  &"
       
        GET Handle, 1, OldHeader

        CreerTOC

        PtrPrec% = 2
      
        I% = 2
        PRINT USING FHD$; "TypF."; "Index"; "LgNom"; "Nom De Fichier DAI"
        PRINT USING FHD$; "====="; "====="; "====="; "=================="
        
        GET Handle, I%, OldRec
        WHILE NOT EOF(1)
              PRINT USING FLD$; OldRec.TypeFic; OldRec.Index; OldRec.LgNom; OldRec.NomDAI

              rec.TypeFic = OldRec.TypeFic
              rec.Index = OldRec.Index
              PtrPrec% = I%
              rec.LgNom = OldRec.LgNom
              rec.NomDAI = OldRec.NomDAI
              CALL AjouterDansToc(rec)

              I% = I% + 1
              GET Handle, I%, OldRec
        WEND

        CLOSE Handle
        CALL PrintColor("Fin de conversion de OLDTOC vers TOC", ROUGEB)
        PRINT

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

SUB LirePrecedantDansToc (Handle AS INTEGER)
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
      
        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                       \"
      
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
        FLD$ = "##### ##### ##### ##### ##### \                       \"
      
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

SUB LireToc (NomFic AS STRING, Sens AS INTEGER)

        DIM Header AS TOCHeader
        DIM rec AS TOCrec
      
        OPEN "TOC" FOR RANDOM ACCESS READ WRITE LOCK READ WRITE AS #1 LEN = 70

        IF NomFic = "" THEN
                IF Sens = DIRECT THEN
                        LireSuivantDansToc (1)
                ELSE
                        LirePrecedantDansToc (1)
                END IF
        ELSE
                PRINT "Routine … ‚crire"
        END IF
      

        CLOSE #1

END SUB

SUB ListerTOC
        DIM Header AS TOCHeader
        DIM rec AS TOCrec
        DIM Ligne AS INTEGER

        Handle = FREEFILE

        OPEN "TOC" FOR RANDOM ACCESS READ LOCK READ AS Handle LEN = 70
     

        FHD$ = "\   \ \   \ \   \ \   \ \   \ \         \"
        FLD$ = "##### ##### ##### ##### ##### \                                   \"
     
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
                IF Lignes = 40 THEN
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
        GOTO FinListerTOC

Titres:
        PRINT USING FHD$; "TypF."; "Index"; "LgNom"; "PtrPrec"; "PtrSuiv"; "Nom De Fichier DAI"
        PRINT USING FHD$; "====="; "====="; "====="; "======="; "======="; "=================="

        RETURN

FinListerTOC:
END SUB

SUB PrintColor (s AS STRING, c AS INTEGER)
COLOR c
PRINT s;
COLOR 7

END SUB

FUNCTION RechercherDansTOC% (TypeFic AS INTEGER, NomDAI AS STRING)
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

SUB ScrutClavier
        SHARED Touche$

        Touche$ = INKEY$

        IF Touche$ = "c" THEN
                ConvertirTOC
        END IF
       
        IF Touche$ = "l" THEN
                ListerTOC
        END IF
       
        IF Touche$ = "d" THEN
                CALL LireToc("", DIRECT)
        END IF
       
        IF Touche$ = "i" THEN
                CALL LireToc("", INVERSE)
        END IF
       
        IF Touche$ = "n" THEN
                CreerTOC
        END IF
       
        IF Touche$ = "m" THEN
                AfficherMenu
        END IF

        IF Touche$ = "a" THEN
                TesterAjouterDansToc
        END IF
       
        IF Touche$ = "r" THEN
                TesterRechercherDansToc
        END IF
       
        IF Touche$ = "s" THEN
                TesterSupprimerDansToc
        END IF
END SUB

SUB SupprimerDansTOC (Index AS INTEGER)
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

SUB TesterAjouterDansToc
        DIM rec AS TOCrec
        DIM NomDAI AS STRING

        INPUT "Nom de fichier … ins‚rer"; NomDAI
        rec.NomDAI = NomDAI
        rec.LgNom = LEN(NomDAI)

        INPUT "Type de fichier"; rec.TypeFic
        INPUT "Index du nom de fichier DOS"; rec.Index
        CALL AjouterDansToc(rec)
END SUB

SUB TesterRechercherDansToc
        DIM rec AS TOCrec

        PRINT "Si le nom contient des blancs en tˆte, alors mettre le nom entre guillemets"
        INPUT "Nom de fichier … rechercher"; NomDAI$
       
        INPUT "Type de fichier … rechercher"; TypeFic%

        Trouve% = RechercherDansTOC%(TypeFic%, NomDAI$)

        PRINT Trouve%


END SUB

SUB TesterSupprimerDansToc
        DIM rec AS TOCrec
        DIM Index AS INTEGER

        PRINT "Si le nom contient des blancs en tˆte, alors mettre le nom entre guillemets"
        INPUT "Nom de fichier … supprimer"; NomDAI$
      
        INPUT "Type de fichier … supprimer"; TypeFic%

        Index = RechercherDansTOC%(TypeFic%, NomDAI$)

        IF Index <> NONTROUVE THEN
                SupprimerDansTOC (Index)
        END IF
END SUB

