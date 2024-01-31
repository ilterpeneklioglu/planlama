*&---------------------------------------------------------------------*
*& Report ZIP_PROJE_PLANLAMA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zip_proje_planlama MESSAGE-ID zip_001.

INCLUDE: zip_proje_planlama_top,
         zip_proje_planlama_cls,
         zip_proje_planlama_mdl.

AT SELECTION-SCREEN.
  go_main->at_selection_screen( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  go_main->on_value_request_for( ).

INITIALIZATION.
  go_main = lcl_main=>get_instance( ).

START-OF-SELECTION.
  go_main->start_of_selection( ).

END-OF-SELECTION.
