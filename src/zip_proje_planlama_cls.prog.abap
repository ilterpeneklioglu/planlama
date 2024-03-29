*&---------------------------------------------------------------------*
*& Include          ZIP_PROJE_PLANLAMA_CLS
*&---------------------------------------------------------------------*

CLASS lcl_main DEFINITION CREATE PRIVATE FINAL.

  PUBLIC SECTION.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_main) TYPE REF TO lcl_main.
    METHODS :
      at_selection_screen,
      on_value_request_for,
      start_of_selection,
      download_excel_template,
      fill_cell IMPORTING i    TYPE i
                          j    TYPE i
                          bold TYPE i
                          val  TYPE ddtext,
      upload_excel IMPORTING iv_file  TYPE rlgrap-filename
                   EXPORTING et_excel TYPE zip_tt_proje_planlama_excel,
      data_regulation,
      abap_section IMPORTING is_line TYPE zip_s_proje_planlama_excel,
      fiori_section IMPORTING is_line TYPE zip_s_proje_planlama_excel,
      pi_section IMPORTING is_line TYPE zip_s_proje_planlama_excel,
      modul_section IMPORTING is_line TYPE zip_s_proje_planlama_excel,
      get_cont,
      create_alv,
      display_alv,
      find_days,
      fill_dynamic_table,
      create_dynamic_fld,
      add_fields CHANGING it_comp_tab TYPE cl_abap_structdescr=>component_table,
      create_dyn_table CHANGING it_comp_tab TYPE cl_abap_structdescr=>component_table,
      create_fcat IMPORTING it_table TYPE STANDARD TABLE
                  EXPORTING et_fcat  TYPE lvc_t_fcat,
      alv,
      exclude RETURNING VALUE(rt_exclude) TYPE ui_functions,
      user_command_0100,
      handle_top_of_page FOR EVENT top_of_page OF cl_gui_alv_grid
        IMPORTING e_dyndoc_id table_index,
      day_formatting IMPORTING iv_date TYPE d
                     EXPORTING ev_date TYPE char10.

  PRIVATE SECTION.
    CLASS-DATA mo_main TYPE REF TO lcl_main.
    DATA mo_con        TYPE REF TO cl_gui_custom_container.
    DATA mo_grid       TYPE REF TO cl_gui_alv_grid.
    DATA ms_layout     TYPE        lvc_s_layo.

ENDCLASS.
CLASS lcl_main IMPLEMENTATION.
  METHOD get_instance.

    IF mo_main IS INITIAL.
      mo_main = NEW #( ).
    ENDIF.
    ro_main = mo_main.

    "Download Template - PushButton
    CONCATENATE icon_report 'Download Template'(029) INTO button1.
    "Table Maintenance - Pushbutton
    CONCATENATE icon_maintenance_object_list 'Employee Maintenance'(029) INTO button2.

  ENDMETHOD.
  METHOD at_selection_screen.
    CASE sy-ucomm.
      WHEN 'EXEC1'.
        download_excel_template( ).
      WHEN 'EXEC2'.
        CALL TRANSACTION 'ZIP_002'.
    ENDCASE.
  ENDMETHOD.
  METHOD on_value_request_for.

    CALL FUNCTION 'F4_FILENAME'
      IMPORTING
        file_name = p_file.

  ENDMETHOD.
  METHOD download_excel_template.

    DATA lv_col TYPE i.

    SELECT fieldname ,position, ddtext
    FROM dd03m INTO TABLE @DATA(lt_fields)
               WHERE tabname = 'ZIP_S_PROJE_PLANLAMA_EXCEL'
                 AND ddlanguage = @sy-langu ORDER BY position.

*  start excel
    CREATE OBJECT h_excel 'EXCEL.APPLICATION'.
*  PERFORM err_hdl.
    SET PROPERTY OF h_excel  'Visible' = 1.

* get list of workbooks, initially empty
    CALL METHOD OF
      h_excel
        'Workbooks' = h_mapl.

* add a new workbook
    CALL METHOD OF
      h_mapl
        'Add' = h_map.

    LOOP AT lt_fields ASSIGNING FIELD-SYMBOL(<fs_fields>).
      lv_col = lv_col + 1.
      fill_cell( i = 1 j = lv_col bold = 1 val = <fs_fields>-ddtext ).
    ENDLOOP.

    FREE OBJECT h_excel.

  ENDMETHOD.
  METHOD fill_cell.
    CALL METHOD OF
        h_excel
        'Cells' = h_zl
      EXPORTING
        #1      = i
        #2      = j.
    SET PROPERTY OF h_zl 'Value' = val .
    GET PROPERTY OF h_zl 'Font' = h_f.
    SET PROPERTY OF h_f 'Bold' = bold .
  ENDMETHOD.
  METHOD start_of_selection.

    upload_excel( EXPORTING iv_file = p_file IMPORTING et_excel = gt_excel ).
    data_regulation( ).
    create_alv( ).
    display_alv( ).

  ENDMETHOD.
  METHOD upload_excel.

    DATA : lt_table    TYPE TABLE OF zip_s_proje_planlama_excel,
           lv_filename TYPE string,
           lt_type     TYPE truxs_t_text_data.

    IF p_file IS NOT INITIAL.
      CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
        EXPORTING
          i_line_header        = 'X'
          i_tab_raw_data       = lt_type
          i_filename           = p_file
        TABLES
          i_tab_converted_data = et_excel
        EXCEPTIONS
          conversion_failed    = 1
          OTHERS               = 2.

      IF sy-subrc NE  0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ELSE.
      MESSAGE e000.
    ENDIF.

  ENDMETHOD.
  METHOD data_regulation.

    DATA : lv_num TYPE numc2.

    "Uyarlama tablosundan çalışılacak modül ve kişi sayıları alınır
    SELECT * FROM zip_t_kaynak INTO TABLE @DATA(lt_kaynak).
    IF sy-subrc <> 0.
      MESSAGE e001.
    ENDIF.

    "Tablodan alınan veriler çalışacak kişi sayısına göre ara bir tabloya alınarak çoklanır
    LOOP AT lt_kaynak INTO DATA(ls_kaynak).
      CLEAR lv_num.
      DO ls_kaynak-calisan TIMES.
        lv_num = lv_num + 1.
        CASE ls_kaynak-modul.
          WHEN 'ABAP'.
            APPEND INITIAL LINE TO gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_dist>).
            <fs_dist>-kaynak = |{ ls_kaynak-modul }{ lv_num }|.
            <fs_dist>-modul  = ls_kaynak-modul.
            UNASSIGN <fs_dist>.
          WHEN 'FIORI'.
            APPEND INITIAL LINE TO gt_dist_fiori ASSIGNING <fs_dist>.
            <fs_dist>-kaynak = |{ ls_kaynak-modul }{ lv_num }|.
            <fs_dist>-modul  = ls_kaynak-modul.
            UNASSIGN <fs_dist>.
          WHEN 'PI'.
            APPEND INITIAL LINE TO gt_dist_pi ASSIGNING <fs_dist>.
            <fs_dist>-kaynak = |{ ls_kaynak-modul }{ lv_num }|.
            <fs_dist>-modul  = ls_kaynak-modul.
            UNASSIGN <fs_dist>.
          WHEN OTHERS.
            APPEND INITIAL LINE TO gt_dist_modul ASSIGNING <fs_dist>.
            <fs_dist>-kaynak = |{ ls_kaynak-modul }{ lv_num }|.
            <fs_dist>-modul  = ls_kaynak-modul.
            UNASSIGN <fs_dist>.
        ENDCASE.
      ENDDO.
    ENDLOOP.

    SORT gt_excel ASCENDING BY faz oncelik.
    LOOP AT gt_excel ASSIGNING FIELD-SYMBOL(<fs_excel>) WHERE abap IS NOT INITIAL OR modul IS NOT INITIAL.
      abap_section( EXPORTING is_line = <fs_excel> ).
      fiori_section( EXPORTING is_line = <fs_excel> ).
      pi_section( EXPORTING is_line = <fs_excel> ).
      modul_section( EXPORTING is_line = <fs_excel> ).
    ENDLOOP.

  ENDMETHOD.
  METHOD abap_section.

    IF is_line-abap IS NOT INITIAL.
      ASSIGN gt_dist_abap[ 1 ]-t_dev TO FIELD-SYMBOL(<fs_abap>).
      IF <fs_abap> IS ASSIGNED.
        <fs_abap> = VALUE #( BASE <fs_abap> FOR i = 0 THEN i + 1 UNTIL i = is_line-abap ( development = is_line-gelistirme_maddesi ) ).
        UNASSIGN <fs_abap>.
      ENDIF.
      LOOP AT gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_dist_abap>).
        <fs_dist_abap>-count = lines( <fs_dist_abap>-t_dev ).
      ENDLOOP.
      SORT gt_dist_abap BY count ASCENDING.
    ENDIF.

  ENDMETHOD.
  METHOD fiori_section.

    IF is_line-fiori IS NOT INITIAL.
      ASSIGN gt_dist_fiori[ 1 ]-t_dev TO FIELD-SYMBOL(<fs_fiori>).
      IF <fs_fiori> IS ASSIGNED.
        <fs_fiori> = VALUE #( BASE <fs_fiori> FOR i = 0 THEN i + 1 UNTIL i = is_line-fiori ( development = is_line-gelistirme_maddesi ) ).
        UNASSIGN <fs_fiori>.
      ENDIF.
      LOOP AT gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_dist_fiori>).
        <fs_dist_fiori>-count = lines( <fs_dist_fiori>-t_dev ).
      ENDLOOP.
      SORT gt_dist_fiori BY count kaynak ASCENDING.
    ENDIF.

  ENDMETHOD.
  METHOD pi_section.

    IF is_line-pi IS NOT INITIAL.
      ASSIGN gt_dist_pi[ 1 ]-t_dev TO FIELD-SYMBOL(<fs_pi>).
      IF <fs_pi> IS ASSIGNED.
        <fs_pi> = VALUE #( BASE <fs_pi> FOR i = 0 THEN i + 1 UNTIL i = is_line-pi ( development = is_line-gelistirme_maddesi ) ).
        UNASSIGN <fs_pi>.
      ENDIF.
      LOOP AT gt_dist_pi ASSIGNING FIELD-SYMBOL(<fs_dist_pi>).
        <fs_dist_pi>-count = lines( <fs_dist_pi>-t_dev ).
      ENDLOOP.
      SORT gt_dist_pi BY count kaynak ASCENDING.
    ENDIF.

  ENDMETHOD.
  METHOD modul_section.

    IF is_line-modul IS NOT INITIAL.
      DATA(lt_dist) = FILTER #( gt_dist_modul USING KEY key1 WHERE modul = is_line-modul_adi ).
      SORT lt_dist BY count kaynak ASCENDING.

      ASSIGN lt_dist[ 1 ] TO FIELD-SYMBOL(<fs_dist_modul>).
      IF <fs_dist_modul> IS NOT ASSIGNED.
        EXIT.
      ENDIF.
      ASSIGN <fs_dist_modul>-t_dev TO FIELD-SYMBOL(<fs_modtab>) .

      CHECK is_line-modul IS NOT INITIAL..
      IF <fs_modtab> IS ASSIGNED.
        <fs_modtab> = VALUE #( BASE <fs_modtab> FOR i = 0 THEN i + 1 UNTIL i = is_line-modul ( development = is_line-gelistirme_maddesi ) ).
        UNASSIGN <fs_modtab>.
      ENDIF.
      MODIFY TABLE gt_dist_modul FROM <fs_dist_modul>.

      UNASSIGN <fs_dist_modul>.
      LOOP AT gt_dist_modul ASSIGNING <fs_dist_modul>.
        <fs_dist_modul>-count = lines( <fs_dist_modul>-t_dev ).
      ENDLOOP.
    ENDIF.

  ENDMETHOD.
  METHOD get_cont.

    IF o_cust IS NOT BOUND.

      CREATE OBJECT o_cust
        EXPORTING
          container_name = 'CCON'.

      CREATE OBJECT o_split
        EXPORTING
          parent  = o_cust
          rows    = 2
          columns = 1.

      CALL METHOD o_split->get_container
        EXPORTING
          row       = 2
          column    = 1
        RECEIVING
          container = o_ref.

      CALL METHOD o_split->get_container
        EXPORTING
          row       = 1
          column    = 1
        RECEIVING
          container = o_ref2.

      o_split->set_row_height( EXPORTING id = 1 height = 15 ).
      o_split->set_column_width( EXPORTING id = 1 width = 100 ).

    ENDIF.

  ENDMETHOD.
  METHOD create_alv.
    IF gt_dist_modul IS NOT INITIAL OR
       gt_dist_abap IS NOT INITIAL OR
       gt_dist_fiori IS NOT INITIAL OR
       gt_dist_pi IS NOT INITIAL.

      find_days( ).
      create_dynamic_fld( ).
      fill_dynamic_table( ).

    ELSE.
      MESSAGE e003.
    ENDIF.
  ENDMETHOD.
  METHOD find_days.

    DATA: lv_dayname TYPE char10,
          lv_count   TYPE sy-tabix.

    "ABAP
    APPEND INITIAL LINE TO gt_duration ASSIGNING FIELD-SYMBOL(<fs_duration>).
    SELECT MAX( gt~count ) FROM @gt_dist_abap  AS gt INTO @DATA(lv_abap).
    <fs_duration>-modul = 'ABAP'.
    <fs_duration>-duration = lv_abap.
    "MODUL
    APPEND INITIAL LINE TO gt_duration ASSIGNING <fs_duration>.
    SELECT MAX( gt~count ) FROM @gt_dist_modul AS gt INTO @DATA(lv_modul).
    <fs_duration>-modul = 'MODUL'.
    <fs_duration>-duration = lv_modul.
    "FIORI
    APPEND INITIAL LINE TO gt_duration ASSIGNING <fs_duration>.
    SELECT MAX( gt~count ) FROM @gt_dist_fiori AS gt INTO @DATA(lv_fiori).
    <fs_duration>-modul = 'FIORI'.
    <fs_duration>-duration = lv_fiori.
    "PI
    APPEND INITIAL LINE TO gt_duration ASSIGNING <fs_duration>.
    SELECT MAX( gt~count ) FROM @gt_dist_pi AS gt INTO @DATA(lv_pi).
    <fs_duration>-modul = 'PI'.
    <fs_duration>-duration = lv_pi.

    SORT gt_duration DESCENDING BY duration.
    gv_duration = VALUE #( gt_duration[ 1 ]-duration OPTIONAL ).

    REFRESH gt_days.
    p_enddat = p_begdat + gv_duration.
    CALL FUNCTION 'DAY_ATTRIBUTES_GET'
      EXPORTING
        factory_calendar           = 'TR'
        holiday_calendar           = 'TR'
        date_from                  = p_begdat
        date_to                    = p_enddat
        language                   = sy-langu
      TABLES
        day_attributes             = gt_days_detail
      EXCEPTIONS
        factory_calendar_not_found = 1
        holida>has_invalid_format  = 3
        date_inconsistency         = 4
        OTHERS                     = 5.

    IF p_pubhol IS NOT INITIAL.
      DELETE gt_days_detail WHERE holiday IS NOT INITIAL.
    ENDIF.
    IF p_strdy IS NOT INITIAL.
      DELETE gt_days_detail WHERE freeday IS NOT INITIAL AND weekday EQ '6'.
    ENDIF.
    IF p_sunday IS NOT INITIAL.
      DELETE gt_days_detail WHERE freeday IS NOT INITIAL AND weekday EQ '7'.
    ENDIF.

    LOOP AT gt_days_detail ASSIGNING FIELD-SYMBOL(<fs_date>).
      APPEND INITIAL LINE TO gt_days ASSIGNING FIELD-SYMBOL(<fs_day>).
      <fs_day>-periodat = <fs_date>-date.
    ENDLOOP.

  ENDMETHOD.
  METHOD fill_dynamic_table.

    DATA: iv_date TYPE d.


    DELETE gt_dist_abap WHERE count IS INITIAL.
    DELETE gt_dist_modul WHERE count IS INITIAL.
    DELETE gt_dist_fiori WHERE count IS INITIAL.
    DELETE gt_dist_pi WHERE count IS INITIAL.

    LOOP AT gt_days ASSIGNING FIELD-SYMBOL(<fs_days>).
      APPEND INITIAL LINE TO <gfs_tab> ASSIGNING FIELD-SYMBOL(<fs_tab>).
      ASSIGN COMPONENT 'DAY_VALUE' OF STRUCTURE <fs_tab> TO FIELD-SYMBOL(<fs_day_val>).
      CLEAR iv_date.
      iv_date = <fs_days>-periodat.
      day_formatting( EXPORTING iv_date = iv_date IMPORTING ev_date = DATA(ev_date) ).
      <fs_day_val> = ev_date.
      ASSIGN COMPONENT 'DAY_NAME' OF STRUCTURE <fs_tab> TO FIELD-SYMBOL(<fs_day_name>).
      READ TABLE gt_days_detail INTO DATA(ls_detail) WITH KEY date = <fs_days>-periodat.
      <fs_day_name> = ls_detail-weekday_l.
    ENDLOOP.


    "ABAP
    LOOP AT gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_abap>).
      LOOP AT <gfs_tab> ASSIGNING <fs_tab>.
        ASSIGN COMPONENT <fs_abap>-kaynak OF STRUCTURE <fs_tab> TO FIELD-SYMBOL(<fs_cell>).
        LOOP AT <fs_abap>-t_dev ASSIGNING FIELD-SYMBOL(<fs_line>).
          <fs_cell> = <fs_line>-development.
          DELETE <fs_abap>-t_dev.
          EXIT.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
    "FIORI
    LOOP AT gt_dist_fiori ASSIGNING FIELD-SYMBOL(<fs_fiori>).
      LOOP AT <gfs_tab> ASSIGNING <fs_tab>.
        ASSIGN COMPONENT <fs_fiori>-kaynak OF STRUCTURE <fs_tab> TO <fs_cell>.
        LOOP AT <fs_fiori>-t_dev ASSIGNING <fs_line>.
          <fs_cell> = <fs_line>-development.
          DELETE <fs_fiori>-t_dev.
          EXIT.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
    "PI
    LOOP AT gt_dist_pi ASSIGNING FIELD-SYMBOL(<fs_pi>).
      LOOP AT <gfs_tab> ASSIGNING <fs_tab>.
        ASSIGN COMPONENT <fs_fiori>-kaynak OF STRUCTURE <fs_tab> TO <fs_cell>.
        LOOP AT <fs_pi>-t_dev ASSIGNING <fs_line>.
          <fs_cell> = <fs_line>-development.
          DELETE <fs_pi>-t_dev.
          EXIT.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
    "MODUL
    LOOP AT gt_dist_modul ASSIGNING FIELD-SYMBOL(<fs_modul>).
      LOOP AT <gfs_tab> ASSIGNING <fs_tab>.
        ASSIGN COMPONENT <fs_modul>-kaynak OF STRUCTURE <fs_tab> TO <fs_cell>.
        LOOP AT <fs_modul>-t_dev ASSIGNING <fs_line>.
          <fs_cell> = <fs_line>-development.
          DELETE <fs_modul>-t_dev.
          EXIT.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

*    "ABAP
*    SORT gt_dist_abap ASCENDING BY kaynak.
*    LOOP AT gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_abap>).
*      APPEND INITIAL LINE TO <gfs_tab> ASSIGNING <fs_tab>.
*      ASSIGN COMPONENT <fs_abap>-kaynak OF STRUCTURE <fs_tab> TO FIELD-SYMBOL(<fs_cons>).
*      <fs_cons> = <fs_abap>-kaynak.
*      LOOP AT gt_days ASSIGNING <fs_days>.
*        ASSIGN COMPONENT <fs_days> OF STRUCTURE <fs_tab> TO FIELD-SYMBOL(<fs_date>).
*        LOOP AT <fs_abap>-t_dev ASSIGNING FIELD-SYMBOL(<fs_line>).
*          <fs_date> = <fs_line>-development.
*          DELETE <fs_abap>-t_dev.
*          EXIT.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*
*    "FIORI
*    SORT gt_dist_fiori ASCENDING BY kaynak.
*    LOOP AT gt_dist_fiori ASSIGNING FIELD-SYMBOL(<fs_fiori>).
*      APPEND INITIAL LINE TO <gfs_tab>  ASSIGNING <fs_tab>.
*      ASSIGN COMPONENT <fs_fiori>-kaynak OF STRUCTURE <fs_tab> TO <fs_cons>.
*      <fs_cons> = <fs_fiori>-kaynak.
*      UNASSIGN <fs_cons>.
*      LOOP AT gt_days ASSIGNING <fs_days>.
*        ASSIGN COMPONENT <fs_days> OF STRUCTURE <fs_tab> TO <fs_date>.
*        LOOP AT <fs_fiori>-t_dev ASSIGNING <fs_line>.
*          <fs_date> = <fs_line>-development.
*          DELETE <fs_fiori>-t_dev.
*          EXIT.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*
*    "PI
*    LOOP AT gt_dist_pi ASSIGNING FIELD-SYMBOL(<fs_pi>).
*      APPEND INITIAL LINE TO <gfs_tab> ASSIGNING <fs_tab>.
*      ASSIGN COMPONENT <fs_pi>-kaynak OF STRUCTURE <fs_tab> TO <fs_cons>.
*      <fs_cons> = <fs_pi>-kaynak.
*      UNASSIGN <fs_cons>.
*      LOOP AT gt_days ASSIGNING <fs_days>.
*        ASSIGN COMPONENT <fs_days> OF STRUCTURE <fs_tab> TO <fs_date>.
*        LOOP AT <fs_pi>-t_dev ASSIGNING <fs_line>.
*          <fs_date> = <fs_line>-development.
*          DELETE <fs_pi>-t_dev.
*          EXIT.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*
*    "MODUL
*    LOOP AT gt_dist_modul ASSIGNING FIELD-SYMBOL(<fs_modul>).
*      APPEND INITIAL LINE TO <gfs_tab> ASSIGNING <fs_tab>.
*      ASSIGN COMPONENT <fs_modul>-kaynak OF STRUCTURE <fs_tab> TO <fs_cons>.
*      <fs_cons> = <fs_modul>-kaynak.
*      UNASSIGN <fs_cons>.
*      LOOP AT gt_days ASSIGNING <fs_days>.
*        ASSIGN COMPONENT <fs_days> OF STRUCTURE <fs_tab> TO <fs_date>.
*        LOOP AT <fs_modul>-t_dev ASSIGNING <fs_line>.
*          <fs_date> = <fs_line>-development.
*          DELETE <fs_modul>-t_dev.
*          EXIT.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.


  ENDMETHOD.
  METHOD create_dynamic_fld.
    add_fields( CHANGING  it_comp_tab = gt_comp_tab ).
    create_dyn_table( CHANGING  it_comp_tab = gt_comp_tab ).
  ENDMETHOD.
  METHOD add_fields.

    DATA: lo_elem_type TYPE REF TO cl_abap_elemdescr,
          ls_comp_fld  TYPE cl_abap_structdescr=>component,
          lv_name      TYPE char10.

    "Hücre renklendirme için
    CLEAR: ls_comp_fld.
    lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'TY_COLOR' ).
    ls_comp_fld-name = 'COLOR_TAB'.
*    ls_comp_fld-type = cl_abap_elemdescr=>get_string( ).
    APPEND ls_comp_fld TO it_comp_tab.

    "İlk sütun olarak gün eklenir
    CLEAR: ls_comp_fld.
    lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'TEXT' ).
    ls_comp_fld-name = 'DAY_VALUE'.
    ls_comp_fld-type = cl_abap_elemdescr=>get_string( ).
    APPEND ls_comp_fld TO it_comp_tab.

    "İkinci sütun olarak gün eklenir
    CLEAR: ls_comp_fld.
    lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'TEXT' ).
    ls_comp_fld-name = 'DAY_NAME'.
    ls_comp_fld-type = cl_abap_elemdescr=>get_string( ).
    APPEND ls_comp_fld TO it_comp_tab.

    "ABAP
    SORT gt_dist_abap ASCENDING BY kaynak.
    LOOP AT gt_dist_abap ASSIGNING FIELD-SYMBOL(<fs_abap>).
      CLEAR: ls_comp_fld.
      lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'CHAR10' ).
      ls_comp_fld-name = <fs_abap>-kaynak.
      ls_comp_fld-type = cl_abap_elemdescr=>get_c( p_length = 10 ).
      APPEND ls_comp_fld TO it_comp_tab.
    ENDLOOP.

    "Modul
    SORT gt_dist_modul ASCENDING BY kaynak.
    LOOP AT gt_dist_modul ASSIGNING FIELD-SYMBOL(<fs_modul>).
      CLEAR: ls_comp_fld.
      lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'CHAR10' ).
      ls_comp_fld-name = <fs_modul>-kaynak.
      ls_comp_fld-type = cl_abap_elemdescr=>get_c( p_length = 10 ).
      APPEND ls_comp_fld TO it_comp_tab.
    ENDLOOP.

    "PI
    SORT gt_dist_pi ASCENDING BY kaynak.
    LOOP AT gt_dist_pi ASSIGNING FIELD-SYMBOL(<fs_pi>).
      CLEAR: ls_comp_fld.
      lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'CHAR10' ).
      ls_comp_fld-name = <fs_pi>-kaynak.
      ls_comp_fld-type = cl_abap_elemdescr=>get_c( p_length = 10 ).
      APPEND ls_comp_fld TO it_comp_tab.
    ENDLOOP.

    "FIORI
    SORT gt_dist_fiori ASCENDING BY kaynak.
    LOOP AT gt_dist_fiori ASSIGNING FIELD-SYMBOL(<fs_fiori>).
      CLEAR: ls_comp_fld.
      lo_elem_type ?= cl_abap_elemdescr=>describe_by_name( 'CHAR10' ).
      ls_comp_fld-name = <fs_fiori>-kaynak.
      ls_comp_fld-type = cl_abap_elemdescr=>get_c( p_length = 10 ).
      APPEND ls_comp_fld TO it_comp_tab.
    ENDLOOP.

  ENDMETHOD.
  METHOD create_dyn_table.

    DATA: lo_struct_type TYPE REF TO cl_abap_structdescr,
          lo_data_ref    TYPE REF TO data.

    lo_struct_type = cl_abap_structdescr=>create( p_components = it_comp_tab p_strict = space ).
    CREATE DATA lo_data_ref TYPE HANDLE lo_struct_type.
    ASSIGN lo_data_ref->* TO <gfs_str>.
    CREATE DATA lo_data_ref LIKE STANDARD TABLE OF <gfs_str>.
    ASSIGN lo_data_ref->* TO <gfs_tab>.

  ENDMETHOD.
  METHOD display_alv.
    IF <gfs_tab> IS NOT INITIAL.
      CALL SCREEN 100.
    ELSE.
      MESSAGE TEXT-001 TYPE 'S' DISPLAY LIKE 'E'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.
  METHOD create_fcat.

    DATA: lo_tabdescr TYPE REF TO cl_abap_structdescr,
          lo_data     TYPE REF TO data,
          lt_dfies    TYPE ddfields,
          iv_date     TYPE d.

    REFRESH :gt_fieldcat.
    CREATE DATA lo_data LIKE LINE OF it_table.
    lo_tabdescr ?= cl_abap_structdescr=>describe_by_data_ref( lo_data ).
    lt_dfies = cl_salv_data_descr=>read_structdescr( lo_tabdescr ).

    LOOP AT lt_dfies ASSIGNING FIELD-SYMBOL(<fs_dfies>).
      APPEND INITIAL LINE TO gt_fieldcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
      MOVE-CORRESPONDING <fs_dfies> TO <fs_fcat>.
*      iv_date = <fs_dfies>-fieldname.
*      day_formatting( EXPORTING iv_date = iv_date IMPORTING ev_date = DATA(ev_date) ).
*      <fs_fcat>-coltext = COND #( WHEN <fs_dfies>-fieldname EQ 'CONSULTANT' THEN <fs_dfies>-fieldname
*                                  ELSE ev_date ).
      <fs_fcat>-coltext = <fs_dfies>-fieldname.
      <fs_fcat>-col_opt = abap_true.
      <fs_fcat>-no_out = COND #( WHEN <fs_dfies>-fieldname EQ 'DAY_RAW' THEN abap_true ELSE '' ).
    ENDLOOP.

  ENDMETHOD.
  METHOD alv.

    DATA : go_event_top TYPE REF TO lcl_main,
           go_event     TYPE REF TO lcl_main.
    DATA : ls_variant TYPE disvariant.

    "ALV
    IF go_grid IS NOT BOUND.

      CREATE OBJECT go_docu
        EXPORTING
          style = 'ALV_GRID'.

      CREATE OBJECT go_grid
        EXPORTING
          i_parent = o_ref.

      CREATE OBJECT go_event.

      CLEAR ls_variant.
      ls_variant-report = sy-repid.
      ls_variant-handle = 'GO_GRID'.

      DATA(lt_exclude) = exclude( ).

      CALL METHOD go_grid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_modified
        EXCEPTIONS
          error      = 1
          OTHERS     = 2.

      SET HANDLER go_event->handle_top_of_page FOR go_grid.

      create_fcat( EXPORTING it_table = <gfs_tab>
                   IMPORTING et_fcat = gt_fieldcat ).

      CALL METHOD go_grid->set_table_for_first_display
        EXPORTING
          is_layout            = VALUE #( zebra = 'X' cwidth_opt = 'X' no_rowins = 'X' sel_mode = 'A' grid_title = 'Planlama Tablosu' ctab_fname = 'COLOR_TAB' )
          i_save               = 'A'
          it_toolbar_excluding = lt_exclude
        CHANGING
          it_fieldcatalog      = gt_fieldcat
          it_outtab            = <gfs_tab>.

      CALL METHOD go_grid->list_processing_events
        EXPORTING
          i_event_name = 'TOP_OF_PAGE'
          i_dyndoc_id  = go_docu.

    ELSE.
      CALL METHOD go_grid->refresh_table_display(
          is_stable      = VALUE lvc_s_stbl( col = 'X' row = 'X' )
          i_soft_refresh = 'X' ).
    ENDIF.

  ENDMETHOD.
  METHOD exclude.

    rt_exclude = VALUE #( ( cl_gui_alv_grid=>mc_fc_loc_copy_row      )
                          ( cl_gui_alv_grid=>mc_fc_loc_delete_row    )
                          ( cl_gui_alv_grid=>mc_fc_loc_append_row    )
                          ( cl_gui_alv_grid=>mc_fc_loc_insert_row    )
                          ( cl_gui_alv_grid=>mc_fc_loc_move_row      )
                          ( cl_gui_alv_grid=>mc_fc_loc_copy          )
                          ( cl_gui_alv_grid=>mc_fc_loc_cut           )
                          ( cl_gui_alv_grid=>mc_fc_loc_paste         )
                          ( cl_gui_alv_grid=>mc_fc_loc_paste_new_row )
                          ( cl_gui_alv_grid=>mc_fc_loc_undo          )
                          ( cl_gui_alv_grid=>mc_fc_graph             )
                          ( cl_gui_alv_grid=>mc_fc_info              )
                          ( cl_gui_alv_grid=>mc_fc_refresh           )
                          ( cl_gui_alv_grid=>mc_fc_detail            )
                          ( cl_gui_alv_grid=>mc_fc_print             )
                          ( cl_gui_alv_grid=>mc_fc_views             )
                          ( cl_gui_alv_grid=>mc_fc_check             ) ) .

  ENDMETHOD.
  METHOD user_command_0100.

    CASE sy-ucomm.
      WHEN 'BACK' OR '&ESC'.
        LEAVE TO SCREEN 0.
    ENDCASE.

  ENDMETHOD.
  METHOD handle_top_of_page.

    DATA: lv_text      TYPE sdydo_text_element.

    CLEAR:lv_text.
    lv_text = 'Number of Days:' .
    CALL METHOD go_docu->add_text
      EXPORTING
        text      = lv_text
        sap_style = cl_dd_document=>heading.

    CALL METHOD go_docu->new_line.
    CALL METHOD go_docu->new_line.

    "Day Total
    CLEAR:lv_text.
    lv_text  = gv_duration.
    CALL METHOD go_docu->add_text
      EXPORTING
        text         = lv_text
        sap_color    = cl_dd_document=>list_positive
        sap_fontsize = cl_dd_document=>large
        sap_emphasis = cl_dd_document=>strong.

    CALL METHOD go_docu->display_document
      EXPORTING
        parent = o_ref2.

  ENDMETHOD.
  METHOD day_formatting.
    CALL FUNCTION 'HRGPBS_HESA_DATE_FORMAT'
      EXPORTING
        p_date     = iv_date
      IMPORTING
        datestring = ev_date.
  ENDMETHOD.
ENDCLASS.

DATA go_main TYPE REF TO lcl_main.
