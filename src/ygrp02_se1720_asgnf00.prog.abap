*&---------------------------------------------------------------------*
*& Include          YGRP02_SE1720_ASGNF00
*&---------------------------------------------------------------------*

*OK roi
*&---------------------------------------------------------------------*
*& Form create_po_bapi
*&---------------------------------------------------------------------*

FORM create_po_bapi .

  CLEAR gs_poheader.
  gs_poheader-comp_code = gs_po_header-gv_bukrs.
  gs_poheader-doc_type = gs_po_header-gv_bsart.
  gs_poheader-vendor = gs_po_header-gv_lifnr.
  gs_poheader-purch_org = gs_po_header-gv_ekorg.
  gs_poheader-pur_group = gs_po_header-gv_ekgrp.
*  GS_POHEADER-CURRENCY = GS_PO_HEADER-GV_WAERS.
*  GS_POHEADER-PMNTTRMS = GS_PO_HEADER-GV_ZTERM.
  gs_poheader-doc_date = sy-datum.


  CLEAR gs_poheaderx.
  gs_poheaderx-comp_code = 'X'.
  gs_poheaderx-doc_type   = 'X'.
  gs_poheaderx-vendor   = 'X'.
  gs_poheaderx-purch_org  = 'X'.
  gs_poheaderx-pur_group  = 'X'.
*  GS_POHEADERX-CURRENCY   = 'X'.
*  GS_POHEADERX-PMNTTRMS  = 'X'.
  gs_poheaderx-doc_date = 'X'.


  " Mapping item
  CLEAR gs_poitem.

  gs_poitem-po_item  = gs_po_item-gv_ebelp.
  gs_poitem-material = gs_po_item-gv_matnr.
  gs_poitem-plant = gs_po_item-gv_werks.
  gs_poitem-stge_loc = gs_po_item-gv_lgort.
  gs_poitem-quantity =  gs_po_item-gv_menge.
  gs_poitem-po_unit =  gs_po_item-gv_meins.
  gs_poitem-net_price = gs_po_item-gv_netpr.
*  GS_POITEM-TAX_CODE = GS_PO_ITEM-GV_MWSKZ.
*  GS_POITEM-FUNDS_CTR = GS_PO_ITEM-GV_FISTL.
  APPEND gs_poitem TO gt_poitem.

  CLEAR gs_poitemx.

  gs_poitemx-po_item   = gs_po_item-gv_ebelp.  " copy số item
  gs_poitemx-po_itemx  = 'X'.                " bật flag cho item này
  gs_poitemx-material  = 'X'.
  gs_poitemx-plant     = 'X'.
  gs_poitemx-stge_loc  = 'X'.
  gs_poitemx-quantity  = 'X'.
  gs_poitemx-po_unit   = 'X'.
  gs_poitemx-net_price = 'X'.
*  GS_POITEMX-TAX_CODE  = 'X'.
*  GS_POITEMX-FUNDS_CTR = 'X'.

  APPEND gs_poitemx TO gt_poitemx.

  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = gs_poheader
      poheaderx        = gs_poheaderx
*     TESTRUN          = 'X'
    IMPORTING
      exppurchaseorder = gv_po_number
    TABLES
      poitem           = gt_poitem
      poitemx          = gt_poitemx
      return           = gt_return.

**  ------------------------------------------------------------
**   4. Xử lý kết quả trả về
**  ------------------------------------------------------------
  DATA(ls_return) = VALUE bapiret2( ).

  READ TABLE gt_return INTO ls_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    " Có lỗi
    MESSAGE |{ TEXT-066 } { ls_return-message }| TYPE 'E' ##NO_TEXT.
    RETURN.
  ENDIF.

  READ TABLE gt_return INTO ls_return WITH KEY type = 'A'.
  IF sy-subrc = 0.
    MESSAGE |{ TEXT-067 } { ls_return-message }| TYPE 'A' ##NO_TEXT.
    EXIT.
  ENDIF.

  " Nếu không có lỗi thì commit dữ liệu
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  "------------------------------------------------------------
  " 5. Thông báo thành công
  "------------------------------------------------------------
  IF gv_po_number IS NOT INITIAL.
    MESSAGE |{ TEXT-064 } { gv_po_number } { TEXT-065 }| TYPE 'S' ##NO_TEXT.
  ELSE.
    MESSAGE TEXT-017 TYPE 'I'.
  ENDIF.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form upload_and_parse_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM upload_and_parse_file .
  DATA: lv_file TYPE string.

  IF p_file IS INITIAL.
    MESSAGE TEXT-019 TYPE 'E'.
    RETURN.
  ENDIF.


  " Upload file
  lv_file = P_file.
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename        = lv_file
      filetype        = 'ASC'
    TABLES
      data_tab        = gt_upload_raw
    EXCEPTIONS
      file_open_error = 1
      file_read_error = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE TEXT-018 TYPE 'E'.
    RETURN.
  ENDIF.


  IF gt_upload_raw IS INITIAL.
    MESSAGE TEXT-020 TYPE 'E'.
    RETURN.
  ENDIF.

  " Parse file content
  PERFORM parse_upload_file.

  " Display summary
  gv_lines_read = lines( gt_upload_items ).
  MESSAGE |{ TEXT-068 } { gv_lines_read } { TEXT-069 } { lines( gt_po_groups ) } { TEXT-070 }| TYPE 'S' ##NO_TEXT.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form parse_upload_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form parse_upload_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM parse_upload_file .
  DATA: lv_line        TYPE string,
        lt_words       TYPE TABLE OF string,
        lv_word        TYPE string,
        lv_skip_header TYPE abap_bool VALUE abap_true,
        lv_error       TYPE abap_bool,
        lv_error_msg   TYPE string,
        lv_line_num    TYPE i VALUE 0,
        lv_test_num    TYPE p DECIMALS 2.

  CLEAR: gt_upload_items, gt_po_groups.

  LOOP AT gt_upload_raw INTO lv_line.
    ADD 1 TO lv_line_num.

    " Skip empty lines
    IF lv_line IS INITIAL OR strlen( lv_line ) < 5.
      CONTINUE.
    ENDIF.

    " Skip header row
    IF lv_skip_header = abap_true.
      lv_skip_header = abap_false.
      CONTINUE.
    ENDIF.

    " Parse data line (tab-separated)
    CLEAR lt_words.
    SPLIT lv_line AT cl_abap_char_utilities=>horizontal_tab INTO TABLE lt_words.

    " If no tabs, try space separation
    IF lines( lt_words ) < 12.
      CLEAR lt_words.
      SPLIT lv_line AT space INTO TABLE lt_words.
      DELETE lt_words WHERE table_line IS INITIAL.
    ENDIF.

    " Format: Supplier CompCode DocType PurchOrg PurchGrp ItemNo Material Plant Storage Qty Unit NetPrice
    IF lines( lt_words ) >= 12.
      CLEAR: gs_upload_item, lv_error, lv_error_msg.

      " Field 1: Supplier
      READ TABLE lt_words INTO lv_word INDEX 1.
      IF lv_word IS INITIAL.
        lv_error = abap_true.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-052 }|.


      ELSE.
        TRY.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = lv_word
              IMPORTING
                output = gs_upload_item-supplier.
          CATCH cx_root INTO DATA(lx_error).
            lv_error = abap_true.
            lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-053 } '{ lv_word }'|.
        ENDTRY.
      ENDIF.

      " Field 2: Company Code
      READ TABLE lt_words INTO lv_word INDEX 2.
      gs_upload_item-comp_code = lv_word.

      " Field 3: Doc Type
      READ TABLE lt_words INTO lv_word INDEX 3.
      gs_upload_item-doc_type = lv_word.

      " Field 4: Purchase Org
      READ TABLE lt_words INTO lv_word INDEX 4.
      gs_upload_item-purch_org = lv_word.

      " Field 5: Purchase Group
      READ TABLE lt_words INTO lv_word INDEX 5.
      gs_upload_item-pur_group = lv_word.

      " Field 6: Item No
      READ TABLE lt_words INTO lv_word INDEX 6.
      gs_upload_item-item_no = lv_word.

      " Field 7: Material
      READ TABLE lt_words INTO lv_word INDEX 7.
      IF lv_word IS INITIAL.
        lv_error = abap_true.
        lv_error_msg = |{ TEXT-051 }  { lv_line_num } { TEXT-053 }|.
      ELSE.
        TRY.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = lv_word
              IMPORTING
                output = gs_upload_item-material.
          CATCH cx_root INTO lx_error.
            lv_error = abap_true.
            lv_error_msg = |{ TEXT-051 } { lv_line_num }  { TEXT-054 }  '{ lv_word }'|.
        ENDTRY.
      ENDIF.

      " Field 8: Plant
      READ TABLE lt_words INTO lv_word INDEX 8.
      gs_upload_item-plant = lv_word.

      " Field 9: Storage
      READ TABLE lt_words INTO lv_word INDEX 9.
      gs_upload_item-storage = lv_word.

      " Field 10: Quantity (must be numeric)
      READ TABLE lt_words INTO lv_word INDEX 10.
      IF lv_word IS INITIAL.
        lv_error = abap_true.
        lv_error_msg = |{ TEXT-051 }  { lv_line_num }  { TEXT-055 }|.
      ELSE.
        " Validate numeric value
        TRY.
            CLEAR lv_test_num.
            lv_test_num = lv_word.
            gs_upload_item-quantity = lv_word.
          CATCH cx_sy_conversion_no_number INTO lx_error.
            lv_error = abap_true.
            lv_error_msg = |{ TEXT-051 }  { lv_line_num } { TEXT-056 }'{ lv_word }' { TEXT-057 }|.
        ENDTRY.
      ENDIF.

      " Field 11: Unit
      READ TABLE lt_words INTO lv_word INDEX 11.
      gs_upload_item-unit = lv_word.

      " Field 12: Net Price (must be numeric)
      READ TABLE lt_words INTO lv_word INDEX 12.
      IF lv_word IS INITIAL.
        lv_error = abap_true.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-058 } |.
      ELSE.
        " Validate numeric value
        TRY.
            CLEAR lv_test_num.
            lv_test_num = lv_word.
            gs_upload_item-net_price = lv_word.
          CATCH cx_sy_conversion_no_number INTO lx_error.
            lv_error = abap_true.
            lv_error_msg = |{ TEXT-051 } { lv_line_num }  { TEXT-059 } '{ lv_word }' { TEXT-057 }|.
        ENDTRY.
      ENDIF.

      " If validation error occurred, display message and stop
      IF lv_error = abap_true.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      " Validate mandatory PO header fields before proceeding
      IF gs_upload_item-supplier IS INITIAL.
        lv_error_msg = |{ TEXT-051 } { lv_line_num }  { TEXT-071 }  |.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      IF gs_upload_item-comp_code IS INITIAL.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-072 } |.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      IF gs_upload_item-doc_type IS INITIAL.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-073 } |.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      IF gs_upload_item-purch_org IS INITIAL.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-074 } |.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      IF gs_upload_item-pur_group IS INITIAL.
        lv_error_msg = |{ TEXT-051 } { lv_line_num } { TEXT-075 } |.
        MESSAGE lv_error_msg TYPE 'E'.
        EXIT.
      ENDIF.

      " Append valid item
      APPEND gs_upload_item TO gt_upload_items.

      " Add to PO groups (unique suppliers)
      CLEAR gs_po_group.
      gs_po_group-supplier   = gs_upload_item-supplier.
      gs_po_group-comp_code  = gs_upload_item-comp_code.
      gs_po_group-doc_type   = gs_upload_item-doc_type.
      gs_po_group-purch_org  = gs_upload_item-purch_org.
      gs_po_group-pur_group  = gs_upload_item-pur_group.
      INSERT gs_po_group INTO TABLE gt_po_groups.
    ELSE.
      " Invalid number of columns
      MESSAGE |{ TEXT-051 } { lv_line_num } { TEXT-060 } { lines( lt_words ) }| TYPE 'E'.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF gt_upload_items IS INITIAL.
    MESSAGE TEXT-021 TYPE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_multiple_pos
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_multiple_pos .
  DATA: lt_items_for_supplier TYPE TABLE OF ty_upload_item,
        lv_po_number          TYPE ebeln,
        lv_success            TYPE abap_bool.

  IF gt_upload_items IS INITIAL.
    MESSAGE TEXT-022 TYPE 'E'.
    RETURN.
  ENDIF.

  CLEAR: gv_po_created, gv_po_failed, gt_po_results.

  " Loop through each unique supplier
  LOOP AT gt_po_groups INTO gs_po_group.
    CLEAR: lt_items_for_supplier, lv_po_number, lv_success.

    " Get all items for this supplier
    LOOP AT gt_upload_items INTO gs_upload_item WHERE supplier = gs_po_group-supplier.
      APPEND gs_upload_item TO lt_items_for_supplier.
    ENDLOOP.

    IF lt_items_for_supplier IS NOT INITIAL.
      " Create PO for this supplier
      PERFORM create_po_for_supplier USING gs_po_group
                                           lt_items_for_supplier
                                     CHANGING lv_po_number
                                              lv_success
                                              gs_po_result.

      " Store result
      gs_po_result-supplier = gs_po_group-supplier.
      IF lv_success = abap_true.
        gs_po_result-po_number = lv_po_number.
        gs_po_result-status = 'S'.
        APPEND gs_po_result TO gt_po_results.
        gv_po_created = gv_po_created + 1.
      ELSE.
        gs_po_result-po_number = ''.
        gs_po_result-status = 'E'.
        APPEND gs_po_result TO gt_po_results.
        gv_po_failed = gv_po_failed + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Final summary
  MESSAGE |{ TEXT-061 } { gv_po_created } { TEXT-062 }, { gv_po_failed } { TEXT-063 }| TYPE 'S' ##NO_TEXT.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_po_for_supplier
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_PO_GROUP
*&      --> LT_ITEMS_FOR_SUPPLIER
*&      <-- LV_PO_NUMBER
*&      <-- LV_SUCCESS
*&      <-- GS_PO_RESULT
*&---------------------------------------------------------------------*
FORM create_po_for_supplier USING is_po_group  TYPE ty_po_group
                                  it_items     TYPE table
                            CHANGING cv_po_number TYPE ebeln
                                     cv_success   TYPE abap_bool
                                     cs_result    TYPE ty_po_result.

  cv_success = abap_false.
  CLEAR: gs_poheader, gs_poheaderx, gt_poitem, gt_poitemx, gt_return.

  " Fill header - same as your code
  gs_poheader-comp_code = is_po_group-comp_code.
  gs_poheader-doc_type  = is_po_group-doc_type.
  gs_poheader-vendor    = is_po_group-supplier.
  gs_poheader-purch_org = is_po_group-purch_org.
  gs_poheader-pur_group = is_po_group-pur_group.
  gs_poheader-doc_date  = sy-datum.

  " Fill headerX
  gs_poheaderx-comp_code = 'X'.
  gs_poheaderx-doc_type  = 'X'.
  gs_poheaderx-vendor    = 'X'.
  gs_poheaderx-purch_org = 'X'.
  gs_poheaderx-pur_group = 'X'.
  gs_poheaderx-doc_date  = 'X'.

  " Fill items
  LOOP AT it_items INTO gs_upload_item.
    CLEAR: gs_poitem, gs_poitemx.

    gs_poitem-po_item   = gs_upload_item-item_no.
    gs_poitem-material  = gs_upload_item-material.
    gs_poitem-plant     = gs_upload_item-plant.
    gs_poitem-stge_loc  = gs_upload_item-storage.
    gs_poitem-quantity  = gs_upload_item-quantity.
    gs_poitem-po_unit   = gs_upload_item-unit.
    gs_poitem-net_price = gs_upload_item-net_price.
    APPEND gs_poitem TO gt_poitem.

    gs_poitemx-po_item   = gs_upload_item-item_no.
    gs_poitemx-po_itemx  = 'X'.
    gs_poitemx-material  = 'X'.
    gs_poitemx-plant     = 'X'.
    gs_poitemx-stge_loc  = 'X'.
    gs_poitemx-quantity  = 'X'.
    gs_poitemx-po_unit   = 'X'.
    gs_poitemx-net_price = 'X'.
    APPEND gs_poitemx TO gt_poitemx.
  ENDLOOP.

  " Call BAPI - same as your code
  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = gs_poheader
      poheaderx        = gs_poheaderx
    IMPORTING
      exppurchaseorder = cv_po_number
    TABLES
      poitem           = gt_poitem
      poitemx          = gt_poitemx
      return           = gt_return.

  " Check errors - same as your code
  READ TABLE gt_return INTO gs_return WITH KEY type = 'E'.
  IF sy-subrc = 0.
    cs_result-message = gs_return-message.
    RETURN.
  ENDIF.

  READ TABLE gt_return INTO gs_return WITH KEY type = 'A'.
  IF sy-subrc = 0.
    cs_result-message = gs_return-message.
    RETURN.
  ENDIF.

  " Commit
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  cv_success = abap_true.
  MESSAGE |{ TEXT-064 } { gv_po_number } { TEXT-065 } | TYPE 'S' ##NO_TEXT.
ENDFORM.
