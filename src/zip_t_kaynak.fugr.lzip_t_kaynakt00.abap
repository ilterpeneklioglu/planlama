*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZIP_T_KAYNAK....................................*
DATA:  BEGIN OF STATUS_ZIP_T_KAYNAK                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZIP_T_KAYNAK                  .
CONTROLS: TCTRL_ZIP_T_KAYNAK
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZIP_T_KAYNAK                  .
TABLES: ZIP_T_KAYNAK                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
