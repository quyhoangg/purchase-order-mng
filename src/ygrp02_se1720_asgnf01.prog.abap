*&---------------------------------------------------------------------*
*& Include          YGRP02_SE1720_ASGNF01
*&---------------------------------------------------------------------*

*OK roi

*&---------------------------------------------------------------------*
*& Form GET_PO_BAPI
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_EBELN
*&---------------------------------------------------------------------*
FORM get_po_bapi  USING    pv_ebeln TYPE ekko-ebeln .

  CLEAR: gt_poheader, gt_poitem.

  CALL FUNCTION 'BAPI_PO_GETDETAIL1'
    EXPORTING
      purchaseorder = pv_ebeln
    IMPORTING
      poheader      = gs_poheader
    TABLES
      poitem        = gt_poitem
      return        = gt_return.

  " Check error
  READ TABLE gt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MESSAGE TEXT-015 TYPE 'E'.
    EXIT.
  ENDIF.
  APPEND gs_poheader TO gt_poheader.
*  CLEAR: pv_ebeln, GV_EBELN.

  IF go_grid_01 IS BOUND.
    go_grid_01->refresh_table_display( ).
  ENDIF.
  IF go_grid_02 IS BOUND.
    go_grid_02->refresh_table_display( ).
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form Create_alv_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- GO_GRID_01
*&---------------------------------------------------------------------*
FORM Create_alv_object USING pv_grid_nm TYPE fieldname  CHANGING go_grid_01.
  CASE pv_grid_nm.
    WHEN 'GO_GRID_01'.
      go_custom_cont_01 = NEW #( repid          = sy-repid
                                 dynnr          = sy-dynnr
                                 container_name = 'GO_CUSTOM_CONT_01' ).
      go_grid_01 = NEW cl_gui_alv_grid( i_parent = go_custom_cont_01 ).
    WHEN 'GO_GRID_02'.
      go_custom_cont_02 = NEW #( repid          = sy-repid
                                 dynnr          = sy-dynnr
                                 container_name = 'GO_CUSTOM_CONT_02' ).
      go_grid_02 = NEW cl_gui_alv_grid( i_parent = go_custom_cont_02 ).
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_grid_display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM alv_grid_display  USING pv_grid_nm TYPE fieldname .
  PERFORM: alv_layout    USING pv_grid_nm,
        alv_variant   USING pv_grid_nm,
        alv_toolbar   USING pv_grid_nm,
        alv_fieldcatalog USING pv_grid_nm,
        alv_event     USING pv_grid_nm,
        alv_outtab_display USING pv_grid_nm.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_layout  USING    pv_grid_nm TYPE fieldname.
  CLEAR: gv_grid_title, gs_layout.
  CASE pv_grid_nm.
      "GO_GRID_01
    WHEN 'GO_GRID_01' OR 'GO_GRID_02'.
      gs_layout-no_rowmark = abap_false.
  ENDCASE.
*    PERFORM alv_set_gridtitle USING pv_grid_nm.
  gs_layout = VALUE #( no_rowins = abap_on
                       sel_mode = 'D'
                       "stylefname = 'STYLE' "Turn off stylef so it don't override the <lfs_fieldcat>-edit = auto on.
                       smalltitle = abap_on
                       cwidth_opt = abap_on
                       grid_title = gv_grid_title
*                         edit = abap_on        "If you put this on, every field is open for editing.
                                                    ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_variant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_variant  USING    pv_grid_nm TYPE fieldname.
  CLEAR: gs_variant.
  CASE pv_grid_nm.
      "GO_GRID_01
    WHEN 'GO_GRID_01' OR 'GO_GRID_02'.
      gs_variant = VALUE #( report = sy-repid
                            username = sy-uname
                            handle = '01' ).
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_toolbar  USING    pv_grid_nm TYPE fieldname.
  CLEAR gt_exclude.
  CASE 'pv_grid_nm'.
    WHEN 'GO_GRID_01' OR 'GO_GRID_02'.
      PERFORM get_alv_exclude_tb_func USING gt_exclude.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_alv_exclude_tb_func
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GT_EXCLUDE
*&---------------------------------------------------------------------*
FORM get_alv_exclude_tb_func  USING    pt_exclude TYPE ui_functions.
  "ALV Exclude button function
  pt_exclude = VALUE #( "-- NO USE
                        ( cl_gui_alv_grid=>mc_fc_check        )
                        ( cl_gui_alv_grid=>mc_fc_refresh      )
                        ( cl_gui_alv_grid=>mc_fc_loc_cut      )
                        ( cl_gui_alv_grid=>mc_fc_loc_paste     )
                        ( cl_gui_alv_grid=>mc_fc_loc_paste_new_row     )
                        ( cl_gui_alv_grid=>mc_fc_loc_undo      )
                        ( cl_gui_alv_grid=>mc_fc_loc_paste      )
                        ( cl_gui_alv_grid=>mc_fc_loc_append_row      )
                        ( cl_gui_alv_grid=>mc_fc_loc_insert_row      )
                        ( cl_gui_alv_grid=>mc_fc_loc_delete_row      )
                        ( cl_gui_alv_grid=>mc_fc_loc_copy_row        )
                        ( cl_gui_alv_grid=>mc_fc_print         )
                        ( cl_gui_alv_grid=>mc_fc_print_prev         )
                        ( cl_gui_alv_grid=>mc_fc_view_grid         )
                        ( cl_gui_alv_grid=>mc_fc_view_excel         )
                        ( cl_gui_alv_grid=>mc_fc_view_crystal         )
                        ( cl_gui_alv_grid=>mc_fc_word_processor         )
                        ( cl_gui_alv_grid=>mc_fc_pc_file         )
                        ( cl_gui_alv_grid=>mc_fc_send         )
                        ( cl_gui_alv_grid=>mc_fc_to_office         )
                        ( cl_gui_alv_grid=>mc_fc_call_abc         )
                        ( cl_gui_alv_grid=>mc_fc_expcrdesig         )
                        ( cl_gui_alv_grid=>mc_fc_expcrtempl         )
                        ( cl_gui_alv_grid=>mc_fc_html         )
                        ( cl_gui_alv_grid=>mc_fc_url_copy_to_clipboard         )
                        ( cl_gui_alv_grid=>mc_fc_variant_admin         )
                        ( cl_gui_alv_grid=>mc_fc_graph         )
                        ( cl_gui_alv_grid=>mc_fc_info         )
                        ( cl_gui_alv_grid=>mc_fc_loc_copy         )   ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_fieldcatalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_fieldcatalog  USING    pv_grid_nm TYPE fieldname.
  CLEAR gt_fieldcat.
  CASE pv_grid_nm.
      "GO_GRID_01
    WHEN 'GO_GRID_01'.
      PERFORM alv_fieldcatalog_01 CHANGING gt_fieldcat.
    WHEN 'GO_GRID_02'.
      PERFORM alv_fieldcatalog_02 CHANGING gt_fieldcat02.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_fieldcatalog_01
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- GT_FIELDCAT
*&--------------------------------------------------------------------*
FORM alv_fieldcatalog_01  CHANGING pt_fieldcat TYPE lvc_t_fcat.
  DATA: lt_fcat TYPE slis_t_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'BAPIMEPOHEADER'
    CHANGING
      ct_fieldcat            = lt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc EQ 0.
    pt_fieldcat = CORRESPONDING #( lt_fcat ).
  ENDIF.
  DEFINE _mapping_fieldcat.
    WHEN &1.
      <lfs_fieldcat>-just        = &2.     " Alignment (C=center, L=left)
      <lfs_fieldcat>-datatype    = &3.     "Data type
      <lfs_fieldcat>-col_opt     = &4.     " Optimize column width
      <lfs_fieldcat>-coltext     = &5.     " Column title
      <lfs_fieldcat>-seltext     = &5.
      <lfs_fieldcat>-tooltip     = &5.
      <lfs_fieldcat>-scrtext_l   = &5.
      <lfs_fieldcat>-scrtext_m   = &5.
      <lfs_fieldcat>-scrtext_s   = &5.
      <lfs_fieldcat>-fix_column  = &6.     " Lock column on scroll
      <lfs_fieldcat>-edit        = &7.  "Open for editing
      <lfs_fieldcat>-key         = &8.

  END-OF-DEFINITION.

  FIELD-SYMBOLS <lfs_fieldcat> TYPE lvc_s_fcat.

  LOOP AT pt_fieldcat ASSIGNING <lfs_fieldcat>.
    CASE <lfs_fieldcat>-fieldname.
        _mapping_fieldcat:
          'PO_NUMBER'       'CHAR'       'C' abap_on TEXT-023    abap_on    abap_off   abap_on,
          'COMP_CODE'       'CHAR'       'C' abap_on TEXT-024    abap_on    abap_off   abap_off,
          'DOC_TYPE'        'CHAR'       'C' abap_on TEXT-025    abap_off   abap_off   abap_off,
          'VENDOR'          'CHAR'       'C' abap_on TEXT-026    abap_off   abap_off   abap_off,
          'PURCH_ORG'       'CHAR'       'C' abap_on TEXT-027    abap_off   abap_off   abap_off,
          'PUR_GROUP'       'CHAR'       'C' abap_on TEXT-028    abap_off   abap_off   abap_off,
          'CURRENCY'        'CUKY'       'C' abap_on TEXT-029    abap_off   abap_off   abap_off.

      WHEN OTHERS.
        <lfs_fieldcat>-tech = abap_on.  "Hide other fields
    ENDCASE.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_event
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_event  USING   pv_grid_nm TYPE fieldname.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_outtab_display
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PV_GRID_NM
*&---------------------------------------------------------------------*
FORM alv_outtab_display  USING    pv_grid_nm TYPE fieldname.
  CASE pv_grid_nm.
    WHEN 'GO_GRID_01'.

      CHECK go_grid_01  IS BOUND.
      go_grid_01->set_ready_for_input( i_ready_for_input = 0 ). "Open ready for input
      go_grid_01->set_table_for_first_display(
        EXPORTING
          i_buffer_active      = abap_true
          i_bypassing_buffer   = abap_true
          i_save               = 'A'
          i_default            = abap_true
          is_layout            = gs_layout
          is_variant           = gs_variant
          it_toolbar_excluding = gt_exclude
        CHANGING
          it_outtab            = gt_poheader
          it_fieldcatalog      = gt_fieldcat ).
      cl_gui_control=>set_focus( control = go_grid_01 ).
      cl_gui_cfw=>flush( ).
    WHEN 'GO_GRID_02'.

      CHECK go_grid_02  IS BOUND.
      go_grid_02->set_ready_for_input( i_ready_for_input = 0 ). "Open ready for input
      go_grid_02->set_table_for_first_display(
        EXPORTING
          i_buffer_active      = abap_true
          i_bypassing_buffer   = abap_true
          i_save               = 'A'
          i_default            = abap_true
          is_layout            = gs_layout
          is_variant           = gs_variant
          it_toolbar_excluding = gt_exclude
        CHANGING
          it_outtab            = gt_poitem
          it_fieldcatalog      = gt_fieldcat02 ).
      cl_gui_control=>set_focus( control = go_grid_02 ).
      cl_gui_cfw=>flush( ).


  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form alv_fieldcatalog_02
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- GT_FIELDCAT
*&---------------------------------------------------------------------*
FORM alv_fieldcatalog_02  CHANGING pt_fieldcat TYPE lvc_t_fcat.
  DATA: lt_fcat TYPE slis_t_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'BAPIMEPOITEM'
    CHANGING
      ct_fieldcat            = lt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc EQ 0.
    pt_fieldcat = CORRESPONDING #( lt_fcat ).
  ENDIF.
  DEFINE _mapping_fieldcat.
    WHEN &1.
      <lfs_fieldcat>-just        = &2.     " Alignment (C=center, L=left)
      <lfs_fieldcat>-datatype    = &3.     "Data type
      <lfs_fieldcat>-col_opt     = &4.     " Optimize column width
      <lfs_fieldcat>-coltext     = &5.     " Column title
      <lfs_fieldcat>-seltext     = &5.
      <lfs_fieldcat>-tooltip     = &5.
      <lfs_fieldcat>-scrtext_l   = &5.
      <lfs_fieldcat>-scrtext_m   = &5.
      <lfs_fieldcat>-scrtext_s   = &5.
      <lfs_fieldcat>-fix_column  = &6.     " Lock column on scroll
      <lfs_fieldcat>-edit        = &7.  "Open for editing
      <lfs_fieldcat>-key         = &8.

  END-OF-DEFINITION.

  FIELD-SYMBOLS <lfs_fieldcat> TYPE lvc_s_fcat.

  LOOP AT pt_fieldcat ASSIGNING <lfs_fieldcat>.
    CASE <lfs_fieldcat>-fieldname.
        _mapping_fieldcat:
          'PO_ITEM'         'NUMC'       'C' abap_on TEXT-031       abap_on    abap_off    abap_on,
          'MATERIAL'        'CHAR'       'C' abap_on TEXT-032       abap_on    abap_off    abap_off,
          'PLANT'           'CHAR'       'C' abap_on TEXT-033       abap_off   abap_off    abap_off,
          'STGE_LOC'        'CHAR'       'C' abap_on TEXT-034       abap_off   abap_off    abap_off,
          'QUANTITY'        'QUAN'       'C' abap_on TEXT-035       abap_off   abap_off    abap_off,
          'PO_UNIT'         'UNIT'       'C' abap_on TEXT-036       abap_off   abap_off    abap_off,
          'NET_PRICE'       'DEC'        'C' abap_on TEXT-037       abap_off   abap_off    abap_off.

      WHEN OTHERS.
        <lfs_fieldcat>-tech = abap_on.  "Hide other fields
    ENDCASE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_po_bapi
*&---------------------------------------------------------------------*
FORM update_po_bapi USING pv_ebeln TYPE ekko-ebeln.

*   CLEAR: gt_poitem, gt_poitemx, gt_return, gv_message.

*  CLEAR: gt_poitem, gt_poitemx, gt_return, gv_message.
*  CLEAR: gs_poheader, gs_poheaderx.
*
*  " ========== PREPARE ITEM DATA ==========
*  CLEAR: gs_poitem, gs_poitemx.


  gs_poitem-po_item    = gs_po_item-gv_ebelp.   " ← BẮT BUỘC!
  gs_poitem-quantity   = gs_po_item-gv_menge.
  gs_poitem-po_unit    = gs_po_item-gv_meins.
  gs_poitem-net_price  = gs_po_item-gv_netpr.
  APPEND gs_poitem TO gt_poitem.

  " Set flag X cho item fields
  gs_poitemx-po_item   = gs_po_item-gv_ebelp.   " ← BẮT BUỘC!
  gs_poitemx-po_itemx  = 'X'.


  IF gs_po_item-gv_menge IS NOT INITIAL.
    gs_poitemx-quantity = 'X'.
  ENDIF.

  IF gs_po_item-gv_meins IS NOT INITIAL.
    gs_poitemx-po_unit = 'X'.
  ENDIF.

  IF gs_po_item-gv_netpr IS NOT INITIAL.
    gs_poitemx-net_price = 'X'.
  ENDIF.

  APPEND gs_poitemx TO gt_poitemx.


  " ========== CALL BAPI ==========
  CALL FUNCTION 'BAPI_PO_CHANGE'
    EXPORTING
      purchaseorder = pv_ebeln
      poheader      = gs_poheader
      poheaderx     = gs_poheaderx
    TABLES
      return        = gt_return
      poitem        = gt_poitem
      poitemx       = gt_poitemx.

  " ========== CHECK RETURN ==========
  DATA(ls_return) = VALUE bapiret2( ).
  READ TABLE gt_return INTO ls_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    LOOP AT gt_return INTO ls_return WHERE type = 'E' OR type = 'A'.
      CONCATENATE gv_message ls_return-message INTO gv_message SEPARATED BY '; '.
    ENDLOOP.
    MESSAGE gv_message TYPE 'E' DISPLAY LIKE 'E'.

  ENDIF.

  " ========== COMMIT ==========
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  " ========== SUCCESS MESSAGE ==========
  CONCATENATE 'PO' pv_ebeln TEXT-040 INTO gv_message SEPARATED BY space.
  MESSAGE gv_message TYPE 'S'.

  " ========== REFRESH DATA ==========
  PERFORM get_po_bapi USING pv_ebeln.
  CLEAR: gt_poitem, gt_poitemx, gt_return, gv_message.
  CLEAR: gs_poheader, gs_poheaderx.

  " ========== PREPARE ITEM DATA ==========
  CLEAR: gs_poitem, gs_poitemx.
  CLEAR: gs_po_item.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form delete_po_item
*&---------------------------------------------------------------------*
FORM delete_po_item  USING    pv_ebeln TYPE ekko-ebeln
                              pv_ebelp TYPE ekpo-ebelp.

  DATA: lv_answer TYPE c LENGTH 1,
        lv_text   TYPE string.
*  CLEAR: gt_poitem, gt_poitemx, gt_return, gv_message.


  lv_text = TEXT-043.

  REPLACE '&1' IN lv_text WITH pv_ebelp.
  REPLACE '&2' IN lv_text WITH pv_ebeln.

  " ========== POPUP CONFIRMATION ==========
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = TEXT-030
      text_question         = lv_text
      text_button_1         = TEXT-038 " Button 1
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = TEXT-039  "Button 2
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = 'X'
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    MESSAGE TEXT-016 TYPE 'I'.
    EXIT.
  ENDIF.

  " ========== PREPARE ITEM DATA FOR DELETION ==========
  CLEAR: gs_poitem, gs_poitemx.

  "CHỈ CẦN PO_ITEM NUMBER
  gs_poitem-po_item    =  pv_ebelp.   " ← BẮT BUỘC!
  gs_poitem-delete_ind = 'X'.
  APPEND gs_poitem TO gt_poitem.

  "SET DELETE FLAG
  gs_poitemx-po_item    =  pv_ebelp.   " ← BẮT BUỘC!
  gs_poitemx-po_itemx  = 'X'.
  gs_poitemx-delete_ind = 'X'.           " ← DELETE FLAG
  APPEND gs_poitemx TO gt_poitemx.

  " ========== CALL BAPI ==========
  CALL FUNCTION 'BAPI_PO_CHANGE'
    EXPORTING
      purchaseorder = gv_ebeln
    TABLES
      return        = gt_return
      poitem        = gt_poitem
      poitemx       = gt_poitemx.

  " ========== CHECK RETURN ==========
  DATA: ls_return TYPE bapiret2.

  READ TABLE gt_return INTO ls_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    CLEAR gv_message.
    LOOP AT gt_return INTO ls_return WHERE type = 'E' OR type = 'A'.
      IF gv_message IS INITIAL.
        gv_message = ls_return-message.
      ELSE.
        CONCATENATE gv_message ls_return-message INTO gv_message SEPARATED BY '; '.
      ENDIF.
    ENDLOOP.
    MESSAGE gv_message TYPE 'E' DISPLAY LIKE 'E'.

  ENDIF.

  READ TABLE gt_return INTO ls_return WITH KEY type = 'A'.
  IF sy-subrc = 0.
    DATA(lv_abort_text) = CONV string( TEXT-042 ).
    REPLACE '&1' IN lv_abort_text WITH ls_return-message.
    MESSAGE lv_abort_text TYPE 'A'.
    EXIT.
  ENDIF.

  " ========== COMMIT ==========
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  " ========== SUCCESS MESSAGE ==========
  CONCATENATE TEXT-045 pv_ebelp TEXT-041 pv_ebeln
    INTO gv_message SEPARATED BY space.
  MESSAGE gv_message TYPE 'S'.

  " ========== REFRESH DATA ==========
  PERFORM get_po_bapi USING pv_ebeln.
  CLEAR: gt_poitem, gt_poitemx, gt_return, gv_message.
  CLEAR: gs_po_item.

ENDFORM.
