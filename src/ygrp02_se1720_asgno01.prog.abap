*&---------------------------------------------------------------------*
*& Include          YGRP02_SE1720_ASGNO01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S100'.
  SET TITLEBAR 'T100'.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

*  " Move giá trị từ global structure sang screen fields
*  gs_po_header-gv_lifnr = gv_lifnr.
*  gs_po_header-gv_ekorg = gv_ekorg.
*  gs_po_item-gv_matnr = gv_matnr.
*  gs_po_item-gv_werks = gv_werks.

  SET PF-STATUS 'S200'.
  SET TITLEBAR 'T200'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0400 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.
  SET PF-STATUS 'S400'.
  SET TITLEBAR 'T400'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0410 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0410 OUTPUT.
  SET PF-STATUS 'S410'.
  SET TITLEBAR 'T410'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_0410 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_0410 OUTPUT.
  IF go_grid_01 IS NOT BOUND.
    PERFORM create_alv_object USING 'GO_GRID_01' CHANGING go_grid_01.
    PERFORM alv_grid_display  USING 'GO_GRID_01'.
  ELSE.
    go_grid_01->refresh_table_display( is_stable = VALUE lvc_s_stbl( row = 'X' col = 'X' ) ).
  ENDIF.

  IF go_grid_02 IS NOT BOUND.
    PERFORM create_alv_object USING 'GO_GRID_02' CHANGING go_grid_02.
    PERFORM alv_grid_display  USING 'GO_GRID_02'.
  ELSE.
    go_grid_02->refresh_table_display( is_stable = VALUE lvc_s_stbl( row = 'X' col = 'X' ) ).
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0420 OUTPUT
*&---------------------------------------------------------------------*

MODULE status_0420 OUTPUT.
  SET PF-STATUS 'S420'.
  SET TITLEBAR 'T420'.

***" Load giá trị PO hiện tại vào screen fields
**  IF gv_ebeln IS NOT INITIAL.
**    " Get PO data nếu chưa có
**    IF gt_poheader IS INITIAL.
*      PERFORM get_po_bapi USING gv_ebeln.
**    ENDIF.
**  ENDIF.
**
*  " Map từ gs_poheader sang gs_poheader để hiển thị trên màn hình
*  READ TABLE gt_poheader INTO gs_poheader INDEX 1.
*  IF sy-subrc = 0.
*    gs_po_header-gv_bukrs = gs_poheader-comp_code.
*    gs_po_header-gv_bsart = gs_poheader-doc_type.
*    gs_po_header-gv_lifnr = gs_poheader-vendor.
*    gs_po_header-gv_ekorg = gs_poheader-purch_org.
*    gs_po_header-gv_ekgrp = gs_poheader-pur_group.
*
*  ENDIF.
*
*  READ TABLE gt_poitem INTO gs_poitem INDEX 1.
*  IF sy-subrc = 0.
*    gs_po_item-gv_ebelp = gs_poitem-po_item.
*    gs_po_item-gv_matnr = gs_poitem-material.
*    gs_po_item-gv_werks = gs_poitem-plant.
*    gs_po_item-gv_lgort = gs_poitem-stge_loc.
*    gs_po_item-gv_menge = gs_poitem-quantity.
*    gs_po_item-gv_meins = gs_poitem-po_unit.
*    gs_po_item-gv_netpr = gs_poitem-net_price.
*  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'S300'.
  SET TITLEBAR 'T300'.
ENDMODULE.
