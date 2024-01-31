*&---------------------------------------------------------------------*
*& Include          ZIP_PROJE_PLANLAMA_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS: icon,vrm.
TABLES : sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-s01.
  PARAMETERS : p_begdat TYPE datum.
  PARAMETERS : p_enddat TYPE datum NO-DISPLAY.
*  PARAMETERS : p_haftas AS CHECKBOX,
*               p_tatil  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-s02.
  PARAMETERS : p_file TYPE rlgrap-filename.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-s03.
  SELECTION-SCREEN PUSHBUTTON /1(30) button1 USER-COMMAND exec1.
SELECTION-SCREEN END OF BLOCK b3.
SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-s04.
  SELECTION-SCREEN PUSHBUTTON /1(30) button2 USER-COMMAND exec2.
SELECTION-SCREEN END OF BLOCK b4.
SELECTION-SCREEN : FUNCTION KEY 1.

DATA: h_excel TYPE ole2_object,        " Excel object
      h_mapl  TYPE ole2_object,         " list of workbooks
      h_map   TYPE ole2_object,          " workbook
      h_zl    TYPE ole2_object,           " cell
      h_f     TYPE ole2_object.            " font

DATA: gt_excel TYPE TABLE OF zip_s_proje_planlama_excel.
DATA: gt_kaynak TYPE zip_t_kaynak.

TYPES : BEGIN OF ty_develop,
          development TYPE char10,
        END OF ty_develop,
        tt_develop TYPE STANDARD TABLE OF ty_develop WITH EMPTY KEY.
TYPES: BEGIN OF ty_dist,
         kaynak TYPE char10, " Abap1 - Abap2 - Abap3
         modul  TYPE char20,
         t_dev  TYPE tt_develop,
         count  TYPE sy-tabix,
       END OF ty_dist.

TYPES: BEGIN OF ty_duration,
         modul TYPE char10,
         duration TYPE dec10,
       END OF ty_duration.

DATA: gt_dist_abap  TYPE TABLE OF ty_dist WITH EMPTY KEY,
      gt_dist_modul TYPE TABLE OF ty_dist WITH NON-UNIQUE SORTED KEY key1 COMPONENTS modul,
      gt_dist_fiori TYPE TABLE OF ty_dist WITH EMPTY KEY,
      gt_dist_pi    TYPE TABLE OF ty_dist WITH EMPTY KEY,
      gt_duration   TYPE TABLE OF ty_duration WITH EMPTY KEY.

DATA: gv_duration TYPE i,
      gt_days     TYPE TABLE OF rke_dat.

DATA: gt_comp_tab TYPE cl_abap_structdescr=>component_table.
FIELD-SYMBOLS : <gfs_tab> TYPE STANDARD TABLE,
                <gfs_str> TYPE any.

DATA: gt_fieldcat TYPE lvc_t_fcat,
      wa_fieldcat TYPE lvc_s_fcat.

DATA: o_cust       TYPE REF TO cl_gui_custom_container,
      o_split      TYPE REF TO cl_gui_splitter_container,
      o_ref        TYPE REF TO cl_gui_container,
      o_ref2       TYPE REF TO cl_gui_container,
      go_grid      TYPE REF TO cl_gui_alv_grid,
      go_docu      TYPE REF TO cl_dd_document,
      o_html_cntrl TYPE REF TO cl_gui_html_viewer.
