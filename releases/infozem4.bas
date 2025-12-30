' ==================================
' INFOZEM – databaza lokalit (POI)
' Version: 0.3
' Platform: PicoCalc / MMBasic
' Workflow: VSCode → GitHub → iPad → SD
' ==================================

' --------- KONFIGURACIA ---------
CONST MAX_LOC = 50
CONST MAX_TYPES = 6

' --------- TYPY LOKALIT ---------
DIM type_name$(MAX_TYPES)
type_name$(1) = "Mesto"
type_name$(2) = "Pamiatka"
type_name$(3) = "Vyhlad"
type_name$(4) = "Cerpacia stanica"
type_name$(5) = "Priechod"
type_name$(6) = "Ine"

' --------- DATA LOKALIT ---------
DIM loc_type(MAX_LOC)
DIM loc_name$(MAX_LOC)
DIM loc_desc$(MAX_LOC)
DIM loc_country$(MAX_LOC)
DIM loc_city$(MAX_LOC)
DIM loc_alt(MAX_LOC)
DIM loc_lat(MAX_LOC)
DIM loc_lon(MAX_LOC)

loc_count = 0
selected_type = 0
data_loaded = 0

GOSUB AutoLoad


' ==============================
' HLAVNY PROGRAM
' ==============================

DO
  CLS
  PRINT "========================"
  PRINT "  DATABAZA LOKALIT (POI)"
  PRINT "========================"
  PRINT
  PRINT "1 - Pridat lokalitu"
  PRINT "2 - Zoznam lokalit"
  PRINT "3 - Editovat lokalitu"
  PRINT "4 - Ulozit na SD"
  PRINT "5 - Nacitat zo SD"
  PRINT "0 - Koniec"
  PRINT
  INPUT "Volba: ", choice

  SELECT CASE choice
    CASE 1
      GOSUB AddLocation
    CASE 2
      GOSUB ListLocations
    CASE 3
      GOSUB EditLocation
    CASE 4
      GOSUB SaveToSD
    CASE 5
      GOSUB LoadFromSD
  END SELECT

LOOP UNTIL choice = 0

CLS
PRINT "Koniec programu."
END

' ===============================
' AutoLoad na zaciatku
' ===============================
AutoLoad:
  ON ERROR SKIP 1
  CHDIR "B:"
  OPEN "lokality.txt" FOR INPUT AS #1

  IF MM.ERRNO <> 0 THEN
    loc_count = 0
    data_loaded = 1
    ON ERROR ABORT
    RETURN
  ENDIF

  ON ERROR ABORT

  INPUT #1, loc_count

  FOR i = 1 TO loc_count
    INPUT #1, loc_type(i)
    LINE INPUT #1, loc_name$(i)
    LINE INPUT #1, loc_desc$(i)
    LINE INPUT #1, loc_country$(i)
    LINE INPUT #1, loc_city$(i)
    INPUT #1, loc_alt(i)
    INPUT #1, loc_lat(i)
    INPUT #1, loc_lon(i)
  NEXT i

  CLOSE #1
  data_loaded = 1
RETURN

' ==============================
' PRIDANIE LOKALITY
' ==============================

AddLocation:
  IF loc_count >= MAX_LOC THEN
    PRINT "Pamat je plna!"
    PAUSE 1500
    RETURN
  ENDIF

  loc_count = loc_count + 1

  GOSUB SelectType
  loc_type(loc_count) = selected_type

  INPUT "Nazov: ", loc_name$(loc_count)
  INPUT "Popis: ", loc_desc$(loc_count)
  INPUT "Stat: ", loc_country$(loc_count)
  INPUT "Mesto: ", loc_city$(loc_count)
  INPUT "Nadmorska vyska (m): ", loc_alt(loc_count)
  INPUT "Latitude: ", loc_lat(loc_count)
  INPUT "Longitude: ", loc_lon(loc_count)

  PRINT
  PRINT "Lokalita ulozena."
  PAUSE 1500
RETURN

' ==============================
' VYBER TYPU LOKALITY
' ==============================

SelectType:
  CLS
  PRINT "Vyber typ lokality:"
  PRINT "-------------------"
  FOR i = 1 TO MAX_TYPES
    PRINT i; " - "; type_name$(i)
  NEXT i
  PRINT
  
  PRINT "Typ (1-"; MAX_TYPES; "): ";
  INPUT selected_type


  IF selected_type < 1 OR selected_type > MAX_TYPES THEN
    PRINT "Neplatna volba!"
    PAUSE 1500
    GOTO SelectType
  ENDIF
RETURN

' ==============================
' EDITOVANIE LOKALITY
' ==============================
EditLocation:
  CLS
  IF loc_count = 0 THEN
    PRINT "Ziadne lokality na editaciu."
    PAUSE 1500
    RETURN
  ENDIF

  PRINT "Editacia lokality"
  PRINT "-----------------"

  FOR i = 1 TO loc_count
    PRINT i; ". "; loc_name$(i)
  NEXT i

  PRINT
  INPUT "Vyber cislo (0 = spat): ", idx

  IF idx = 0 THEN RETURN
  IF idx < 1 OR idx > loc_count THEN
    PRINT "Neplatny vyber!"
    PAUSE 1500
    RETURN
  ENDIF

  CLS
  PRINT "EDITUJES: "; loc_name$(idx)
  PRINT "(ENTER = bez zmeny)"
  PRINT

  ' ---------- TYP ----------
  PRINT "Aktualny typ: "; type_name$(loc_type(idx))
  PRINT "Novy typ (0 = bez zmeny):"
  FOR i = 1 TO MAX_TYPES
    PRINT i; " - "; type_name$(i)
  NEXT i
  INPUT "Typ: ", selected_type
  IF selected_type >= 1 AND selected_type <= MAX_TYPES THEN
    loc_type(idx) = selected_type
  ENDIF
  PRINT

  ' ---------- NAZOV ----------
  field_name$ = "Nazov"
  current_value$ = loc_name$(idx)
  GOSUB EditString
  loc_name$(idx) = edit_result$

  ' ---------- POPIS ----------
  field_name$ = "Popis"
  current_value$ = loc_desc$(idx)
  GOSUB EditString
  loc_desc$(idx) = edit_result$

  ' ---------- STAT ----------
  field_name$ = "Stat"
  current_value$ = loc_country$(idx)
  GOSUB EditString
  loc_country$(idx) = edit_result$

  ' ---------- MESTO ----------
  field_name$ = "Mesto"
  current_value$ = loc_city$(idx)
  GOSUB EditString
  loc_city$(idx) = edit_result$

  ' ---------- NADMORSKA VYSKA ----------
  field_name$ = "Nadmorska vyska"
  current_value = loc_alt(idx)
  GOSUB EditNumber
  loc_alt(idx) = edit_number

  ' ---------- LATITUDE ----------
  field_name$ = "Latitude"
  current_value = loc_lat(idx)
  GOSUB EditNumber
  loc_lat(idx) = edit_number

  ' ---------- LONGITUDE ----------
  field_name$ = "Longitude"
  current_value = loc_lon(idx)
  GOSUB EditNumber
  loc_lon(idx) = edit_number

  PRINT
  PRINT "Zmeny ulozene v pamati."
  PAUSE 1500
RETURN


' -------------------------
' Editacia textu
' -------------------------
EditString:
  PRINT field_name$; " ["; current_value$; "]: ";
  LINE INPUT tmp$
  IF tmp$ = "" THEN
    edit_result$ = current_value$
  ELSE
    edit_result$ = tmp$
  ENDIF
RETURN

' -------------------------
' Editacia cisla
' -------------------------
EditNumber:
  PRINT field_name$; " ["; current_value; "]: ";
  LINE INPUT tmp$
  IF tmp$ = "" THEN
    edit_number = current_value
  ELSE
    edit_number = VAL(tmp$)
  ENDIF
RETURN

' ==============================
' ZOZNAM LOKALIT
' ==============================

ListLocations:
  CLS
  IF loc_count = 0 THEN
    PRINT "Ziadne lokality."
  ELSE
    PRINT "Zoznam lokalit:"
    PRINT "----------------"
    FOR i = 1 TO loc_count
      PRINT i; ". ";
      PRINT loc_name$(i); " ("; type_name$(loc_type(i)); ")"
    NEXT i
  ENDIF

  PRINT
  PRINT "Stlac ENTER..."
  DO
    k$ = INKEY$
  LOOP UNTIL k$ = CHR$(13)
RETURN

' ==============================
' ULOZENIE NA SD KARTU
' ==============================

SaveToSD:

  IF data_loaded = 0 THEN
    PRINT "Data neboli nacitane!"
    PRINT "Ukladanie zablokovane."
    PAUSE 2000
    RETURN
  ENDIF

  CHDIR "B:"
  OPEN "lokality.txt" FOR OUTPUT AS #1
  PRINT #1, loc_count

  FOR i = 1 TO loc_count
    PRINT #1, loc_type(i)
    PRINT #1, loc_name$(i)
    PRINT #1, loc_desc$(i)
    PRINT #1, loc_country$(i)
    PRINT #1, loc_city$(i)
    PRINT #1, loc_alt(i)
    PRINT #1, loc_lat(i)
    PRINT #1, loc_lon(i)
  NEXT i

  CLOSE #1
  PRINT "Data ulozene na SD."
  PAUSE 1500
RETURN

' ==============================
' NACITANIE Z SD KARTY
' ==============================

LoadFromSD:
  ON ERROR SKIP 1
  CHDIR "B:"
  OPEN "lokality.txt" FOR INPUT AS #1
  IF MM.ERRNO <> 0 THEN
    PRINT "Subor neexistuje!"
    PAUSE 1500
    ON ERROR ABORT
    RETURN
  ENDIF
  ON ERROR ABORT

  INPUT #1, loc_count

  FOR i = 1 TO loc_count
    INPUT #1, loc_type(i)
    LINE INPUT #1, loc_name$(i)
    LINE INPUT #1, loc_desc$(i)
    LINE INPUT #1, loc_country$(i)
    LINE INPUT #1, loc_city$(i)
    INPUT #1, loc_alt(i)
    INPUT #1, loc_lat(i)
    INPUT #1, loc_lon(i)
  NEXT i

  CLOSE #1
  PRINT "Data nacitane."
  PAUSE 1500
RETURN
