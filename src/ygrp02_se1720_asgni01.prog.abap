*&---------------------------------------------------------------------*
*& Include          YGRP02_SE1720_ASGNI01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CASE gv_okcode.
    WHEN 'EXIT' OR 'BACK'.
      IF gv_okcode = 'BACK'.
        LEAVE TO SCREEN 0.
      ELSE.
        LEAVE PROGRAM.
      ENDIF.

  ENDCASE.

  CLEAR gv_okcode.

ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE gv_okcode.
    WHEN 'RUN'.
      IF r_create = 'X'.
        CALL SCREEN 200.
      ELSEIF r_upload = 'X'.
        CALL SCREEN 300.
      ELSEIF r_disp = 'X'.
        CALL SCREEN 400.
      ENDIF.
  ENDCASE.
  CLEAR gv_okcode.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE gv_okcode.
    WHEN 'CREATE'.
      PERFORM create_po_bapi.
*    WHEN 'REFRESH' OR 'ENTER'.
*      gs_po_header-gv_ekorg = gv_ekorg.
*      gs_po_item-gv_matnr = gv_matnr.
*      gs_po_item-gv_werks = gv_werks.
  ENDCASE.
  CLEAR gv_okcode.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*

MODULE user_command_0400 INPUT.
  CASE gv_okcode.
    WHEN 'DISPLAY'.
      IF r_display = 'X'.
        PERFORM get_po_bapi USING gv_ebeln .
        CALL SCREEN 410.
        CLEAR: gs_po_item.
      ELSEIF r_upd = 'X'.
        PERFORM get_po_bapi USING gv_ebeln.

        " Map từ gs_poheader sang gs_poheader để hiển thị trên màn hình
        READ TABLE gt_poheader INTO gs_poheader INDEX 1.
        IF sy-subrc = 0.
          gs_po_header-gv_bukrs = gs_poheader-comp_code.
          gs_po_header-gv_bsart = gs_poheader-doc_type.
          gs_po_header-gv_lifnr = gs_poheader-vendor.
          gs_po_header-gv_ekorg = gs_poheader-purch_org.
          gs_po_header-gv_ekgrp = gs_poheader-pur_group.

        ENDIF.

        READ TABLE gt_poitem INTO gs_poitem INDEX 1.
        IF sy-subrc = 0.
          gs_po_item-gv_ebelp = gs_poitem-po_item.
          gs_po_item-gv_matnr = gs_poitem-material.
          gs_po_item-gv_werks = gs_poitem-plant.
          gs_po_item-gv_lgort = gs_poitem-stge_loc.
          gs_po_item-gv_menge = gs_poitem-quantity.
          gs_po_item-gv_meins = gs_poitem-po_unit.
          gs_po_item-gv_netpr = gs_poitem-net_price.
        ENDIF.
        CALL SCREEN 420.
      ELSEIF r_del = 'X'.
        PERFORM get_po_bapi USING gv_ebeln .
        READ TABLE gt_poitem INTO gs_poitem INDEX 1.
        IF sy-subrc = 0.
          gv_ebelp = gs_poitem-po_item.

        ENDIF.
        PERFORM delete_po_item USING gv_ebeln
                                     gv_ebelp.
      ENDIF.
  ENDCASE.
  CLEAR gv_okcode.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  VALUE_REQUEST_LIFNR  INPUT
*&---------------------------------------------------------------------*
MODULE value_request_lifnr INPUT.

  TYPES: BEGIN OF ty_supplier,
           lifnr      TYPE lifnr,
           name1      TYPE name1_gp,  " Tên supplier
           bukrs      TYPE bukrs,     " Company Code
           ekorg      TYPE ekorg,     " Purchasing Org
           ekgrp      TYPE ekgrp,     " Purchasing Group
           werks      TYPE werks_d,   " Plant
           matnr      TYPE matnr,     " Material
           lgort      TYPE lgort_d,   " Storage Location
           unique_key TYPE char100,   " Field ẩn làm unique key
         END OF ty_supplier.

  DATA: lt_supplier   TYPE TABLE OF ty_supplier,
        lt_return_tab TYPE TABLE OF ddshretval,
        ls_supplier   TYPE ty_supplier,
        lv_unique_key TYPE char100.

  " Lấy supplier có đủ: Company Code, Purchasing Org, Purchasing Group, Plant, Material và Storage Location
  " - Query dùng INNER JOIN cho data bắt buộc (nếu thiếu → loại supplier)
  " - LEFT OUTER JOIN cho data optional (stock/company link, nếu thiếu → vẫn giữ nhưng filter sau)
  SELECT DISTINCT
    a~lifnr,          " Vendor number (mã supplier chính, khóa chính của LFA1)
    a~name1,          " Supplier name (tên supplier từ master data)
    g~bwkey AS bukrs, " Company Code (lấy từ plant-company link ở T001K; alias bukrs cho dễ dùng)
    b~ekorg,          " Purchasing Organization (từ LFM1, bắt buộc cho PO)
    b~ekgrp,          " Purchasing Group (từ LFM1, bắt buộc cho PO)
    d~werks,          " Plant (từ EINE, plant liên kết với info record)
    c~matnr,          " Material Number (từ EINA, material liên kết với supplier)
    e~lgort           " Storage Location (từ MARD, stock location cho material/plant; có thể rỗng nếu chưa stock)
  FROM lfa1 AS a                " Bảng master data supplier (LFA1: Vendor Master General Data)
  INNER JOIN lfm1 AS b         " INNER JOIN với LFM1: Vendor Master Purchasing Organization Data
    ON a~lifnr = b~lifnr       " Điều kiện join: Khớp supplier number (bắt buộc có purch data → nếu thiếu EKORG/EKGRP, loại supplier)
  INNER JOIN eina AS c         " INNER JOIN với EINA: Purchasing Info Record General Data (info record cho supplier-material)
    ON a~lifnr = c~lifnr       " Điều kiện join: Khớp supplier number (bắt buộc có info record cho material → nếu thiếu, loại)
  INNER JOIN eine AS d         " INNER JOIN với EINE: Purchasing Info Record Purchasing Organization Data
    ON c~infnr = d~infnr       " Điều kiện join: Khớp Info Record Number (bắt buộc có plant data trong info record → nếu thiếu WERKS, loại)
  LEFT OUTER JOIN mard AS e    " LEFT OUTER JOIN với MARD: Material Stock (stock data cho material/plant)
    ON c~matnr = e~matnr       " Điều kiện join phần 1: Khớp Material Number
    AND d~werks = e~werks      " Điều kiện join phần 2: Khớp Plant (nếu không có stock ở plant này, field LGORT sẽ rỗng nhưng row vẫn giữ)
  LEFT OUTER JOIN t001k AS g   " LEFT OUTER JOIN với T001K: Valuation Area (link plant với company code)
    ON d~werks = g~bwkey       " Điều kiện join: Khớp Plant (WERKS) với Valuation Area (nếu plant chưa link company, BUKRS rỗng nhưng row vẫn giữ)

      WHERE  a~loevm = @space           " Supplier không bị xóa
*      AND b~loevm = @space           " Purchasing Org data không bị xóa
        AND b~ekorg IS NOT INITIAL     " Có Purchasing Org
        AND b~ekgrp IS NOT INITIAL     " Có Purchasing Group
*      AND c~loekz = @space           " Material data không bị xóa
        AND c~matnr IS NOT INITIAL     " Có Material
*      AND d~loekz = @space           " Plant data không bị xóa
        AND d~werks IS NOT INITIAL     " Có Plant
        AND e~lgort IS NOT INITIAL     " Có Storage Location
        AND g~bukrs IS NOT INITIAL    " Có Company Code
        INTO TABLE @lt_supplier.

  IF lt_supplier IS INITIAL.
    MESSAGE TEXT-001 TYPE 'I'.
    RETURN.
  ENDIF.

  " Tạo unique key cho mỗi dòng (kết hợp LIFNR + MATNR + WERKS + LGORT)
  " Unique key này đảm bảo mỗi combination là duy nhất
  LOOP AT lt_supplier ASSIGNING FIELD-SYMBOL(<fs_supplier>).
    <fs_supplier>-unique_key = |{ <fs_supplier>-lifnr }|
                             && |{ <fs_supplier>-matnr }|
                             && |{ <fs_supplier>-werks }|
                             && |{ <fs_supplier>-lgort }|.
  ENDLOOP.

  " Gọi F4 với danh sách supplier đã lọc
  " retfield = 'UNIQUE_KEY' để F4 trả về unique key thay vì chỉ LIFNR
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'UNIQUE_KEY'    " ĐỔI THÀNH UNIQUE_KEY
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GS_PO_HEADER-GV_LIFNR'
      value_org       = 'S'
      window_title    = TEXT-002
    TABLES
      value_tab       = lt_supplier
      return_tab      = lt_return_tab
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  " Kiểm tra kết quả từ F4
  IF sy-subrc <> 0.
    MESSAGE TEXT-003 TYPE 'I'.
    RETURN.
  ENDIF.

  " Kiểm tra user có chọn gì không
  IF lt_return_tab IS INITIAL.
    MESSAGE TEXT-004 TYPE 'I'.
    RETURN.
  ENDIF.

  " Đọc unique key được chọn
  READ TABLE lt_return_tab INTO DATA(ls_return) INDEX 1.
  IF sy-subrc <> 0.
    MESSAGE TEXT-005 TYPE 'I'.
    RETURN.
  ENDIF.

  " Lấy unique key từ giá trị return
  lv_unique_key = ls_return-fieldval.

  " Tìm thông tin đầy đủ của supplier đã chọn dùng unique key
  " Unique key đảm bảo tìm đúng 1 dòng duy nhất
  READ TABLE lt_supplier INTO ls_supplier
    WITH KEY unique_key = lv_unique_key.

  IF sy-subrc <> 0.
    MESSAGE |{ TEXT-006 }{ lv_unique_key }|  TYPE 'I' .
    RETURN.
  ENDIF.

  " Convert LIFNR với leading zeros (cho đúng format SAP)
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_supplier-lifnr
    IMPORTING
      output = ls_supplier-lifnr.

  " Cập nhật biến global
  gv_lifnr = ls_supplier-lifnr.
  gv_ekorg = ls_supplier-ekorg.
  gv_werks = ls_supplier-werks.
  gv_matnr = ls_supplier-matnr.

  " Tự động điền các field - PO HEADER
  gs_po_header-gv_lifnr = gv_lifnr.
  gs_po_header-gv_bukrs = ls_supplier-bukrs.  " Company Code
  gs_po_header-gv_ekorg = gv_ekorg.
  gs_po_header-gv_ekgrp = ls_supplier-ekgrp.  " Purchasing Group

  " Tự động điền các field - PO ITEM
  gs_po_item-gv_ebelp   = '00010'.            " Item Number (default 10)
  gs_po_item-gv_werks   = gv_werks.
  gs_po_item-gv_matnr   = gv_matnr.
  gs_po_item-gv_lgort   = ls_supplier-lgort.  " Storage Location

  " Thông báo thành công
  MESSAGE |{ TEXT-007 }{ ls_supplier-bukrs }{ TEXT-008 } { gv_matnr }{ TEXT-009 }{ gv_werks }{ TEXT-010 }{ gv_ekorg }{ TEXT-011 }{ ls_supplier-ekgrp }{ TEXT-012 }{ ls_supplier-lgort }| TYPE 'S' DISPLAY LIKE 'I'.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  F4_EBELN  INPUT
*&---------------------------------------------------------------------*

MODULE f4_ebeln INPUT.

  DATA: lt_return TYPE TABLE OF ddshretval.

  " Lấy danh sách PO
  SELECT ebeln, bukrs, bsart, ernam, lastchangedatetime
    FROM ekko
    INTO TABLE @DATA(lt_po)
    UP TO 20 ROWS
    WHERE bukrs = 'FU24'
    ORDER BY aedat DESCENDING.

  IF lt_po IS NOT INITIAL.
    " Hiển thị popup chỉ 3 cột
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield    = 'EBELN'
        dynpprog    = sy-repid
        dynpnr      = sy-dynnr
        dynprofield = 'GV_EBELN'
        value_org   = 'S'
      TABLES
        value_tab   = lt_po
        return_tab  = lt_return
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    IF sy-subrc = 0 AND lt_return IS NOT INITIAL.
      READ TABLE lt_return INTO DATA(ls_return1)  INDEX 1.
      gv_ebeln = ls_return1-fieldval.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0420  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0420 INPUT.
  CASE gv_okcode.
    WHEN 'UPDATE'.
      PERFORM update_po_bapi USING gv_ebeln.

  ENDCASE.
  CLEAR gv_okcode.


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  F4_SELECT_UPLOAD_FILE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_select_upload_file INPUT.
  DATA: lt_file_table TYPE filetable,
        lv_rc         TYPE i,
        lv_action     TYPE i,
        lv_filter     TYPE string.
  lv_filter = TEXT-014.

  TRY.
      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING
          file_filter = lv_filter
        CHANGING
          file_table  = lt_file_table
          rc          = lv_rc
          user_action = lv_action ).

      IF lv_action = cl_gui_frontend_services=>action_ok.
        READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
        IF sy-subrc = 0.
          p_file = ls_file.
        ENDIF.
      ENDIF.

    CATCH cx_root INTO DATA(lx_error).
      MESSAGE lx_error->get_text( ) TYPE 'E'.
  ENDTRY.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  CASE gv_okcode.

    WHEN 'UPLOAD'.


      PERFORM upload_and_parse_file.


      PERFORM create_multiple_pos.

  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  VALUE_REQUEST_EBELP  INPUT
*&---------------------------------------------------------------------*
MODULE value_request_ebelp INPUT.
  "==== TYPE DETAIL ====
  TYPES: BEGIN OF ty_f4_item,
           unique_key TYPE char100,  " Key duy nhất cho item
           po_item    TYPE ebelp,
           material   TYPE matnr,
           plant      TYPE werks_d,
           stge_loc   TYPE lgort_d,
           quantity   TYPE menge_d,
           po_unit    TYPE meins,
           net_price  TYPE bprei,
         END OF ty_f4_item.

  DATA: lt_f4_data TYPE TABLE OF ty_f4_item,
        ls_f4_data TYPE ty_f4_item,
        ls_poitem  TYPE bapimepoitem.


  "==== CLEAR RETURN TABLE - QUAN TRỌNG ====
  CLEAR: gt_return_tab.

  "==== PREPARE DATA FOR F4 (Remove duplicates) ====
  CLEAR: lt_f4_data.

  "==== PREPARE DATA FOR F4 ====
  LOOP AT gt_poitem INTO ls_poitem.
    CLEAR ls_f4_data.

    ls_f4_data-po_item    = ls_poitem-po_item.
    ls_f4_data-material   = ls_poitem-material.
    ls_f4_data-plant      = ls_poitem-plant.
    ls_f4_data-stge_loc   = ls_poitem-stge_loc.
    ls_f4_data-quantity   = ls_poitem-quantity.
    ls_f4_data-po_unit    = ls_poitem-po_unit.
    ls_f4_data-net_price  = ls_poitem-net_price.

    " Unique key: PO item combo
    ls_f4_data-unique_key = |{ ls_poitem-po_item }| && |{ ls_poitem-material }| && |{ ls_poitem-plant }|.

    APPEND ls_f4_data TO lt_f4_data.
  ENDLOOP.

  IF lt_f4_data IS INITIAL.
    MESSAGE TEXT-046 TYPE 'I'.
    RETURN.
  ENDIF.

  "==== F4 DISPLAY ====
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'UNIQUE_KEY'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'GS_PO_ITEM-GV_EBELP'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4_data
      return_tab  = lt_return_tab
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0 OR lt_return_tab IS INITIAL.
    RETURN.
  ENDIF.

  "==== GET SELECTED VALUE ====
  READ TABLE lt_return_tab INTO DATA(ls_return2) INDEX 1.
  lv_unique_key = ls_return2-fieldval.

  READ TABLE lt_f4_data INTO ls_f4_data
    WITH KEY unique_key = lv_unique_key.

  IF sy-subrc <> 0.
    MESSAGE TEXT-047 TYPE 'I'.
    RETURN.
  ENDIF.

  "==== FILL GLOBAL STRUCTURE ====
  gs_po_item-gv_ebelp = ls_f4_data-po_item.
  gs_po_item-gv_matnr = ls_f4_data-material.
  gs_po_item-gv_werks = ls_f4_data-plant.
  gs_po_item-gv_lgort = ls_f4_data-stge_loc.
  gs_po_item-gv_menge = ls_f4_data-quantity.
  gs_po_item-gv_meins = ls_f4_data-po_unit.
  gs_po_item-gv_netpr = ls_f4_data-net_price.

  DATA: lv_text1 TYPE string,
        lv_text2 TYPE string,
        lv_msg   TYPE string.
  lv_text1 = TEXT-048.
  lv_text2 = TEXT-049.
  CONCATENATE lv_text1 ls_f4_data-po_item lv_text2 INTO lv_msg SEPARATED BY space.
  MESSAGE lv_msg TYPE 'S'.


ENDMODULE.
