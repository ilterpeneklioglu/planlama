*&---------------------------------------------------------------------*
*& Include          ZIP_PROJE_PLANLAMA_MDL
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE alv OUTPUT.
  go_main->get_cont( ).
  go_main->alv( ).
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  go_main->user_command_0100( ).
ENDMODULE.
