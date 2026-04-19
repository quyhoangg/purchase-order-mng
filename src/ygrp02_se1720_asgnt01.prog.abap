*&---------------------------------------------------------------------*
*& Include          YGRP02_SE1720_ASGNT01
*&---------------------------------------------------------------------*
TABLES: ekko, ekpo, lfa1, lfm1, eina, eine, mard, t001k.

DATA: gv_okcode TYPE sy-ucomm.


DATA: gv_ebeln TYPE char10, "Khai bao bien cho Search Help
      gv_ebelp TYPE numc5.
" Biến global cho các field
DATA: gv_lifnr TYPE lifnr,
      gv_matnr TYPE matnr,
      gv_ekorg TYPE ekorg,
      gv_werks TYPE werks_d,
      gv_bukrs TYPE bukrs,
      gv_ekgrp TYPE ekgrp,
      gv_lgort TYPE lgort_d.

" Structure cho Search Help
TYPES: BEGIN OF ty_supplier_help,
         lifnr TYPE lifnr,
         name1 TYPE name1_gp,
         bukrs TYPE bukrs,
         ekorg TYPE ekorg,
         ekgrp TYPE ekgrp,
         werks TYPE werks_d,
         matnr TYPE matnr,
         lgort TYPE lgort_d,
       END OF ty_supplier_help.

DATA: gt_supplier_help TYPE TABLE OF ty_supplier_help,
      gt_return_tab    TYPE TABLE OF ddshretval.

DATA: gv_mode TYPE char1.

DATA: r_create TYPE c,     " Main Screen
      r_upload TYPE c,
      r_disp   TYPE c.

DATA: r_display TYPE c,  "Sub Screen for Display
      r_upd     TYPE c,
      r_del     TYPE c.

*DATA: GV_EBELN TYPE EKKO-EBELN.
*     GV_LOEKZ TYPE EKKO-LOEKZ,    " Deletion flag

TYPES: BEGIN OF gty_po_header,
*         GV_EBELN TYPE EKKO-EBELN,    " PO Number
         gv_bukrs TYPE ekko-bukrs,    " Company Code
         gv_bsart TYPE ekko-bsart,    " Document Type
         gv_lifnr TYPE ekko-lifnr,    " Vendor
         gv_ekorg TYPE ekko-ekorg,    " Purchasing Org
         gv_ekgrp TYPE ekko-ekgrp,    " Purchasing Group
*         GV_WAERS TYPE EKKO-WAERS,    " Currency
*         GV_ZTERM TYPE  EKKO-ZTERM,   " Payment Terms
       END OF gty_po_header.

TYPES: BEGIN OF gty_po_item,
         gv_ebelp TYPE ekpo-ebelp, " Item Number
         gv_matnr TYPE ekpo-matnr, " Material
         gv_werks TYPE ekpo-werks, " Plant
         gv_lgort TYPE ekpo-lgort, " Storage Location
         gv_menge TYPE ekpo-menge, " Quantity
         gv_meins TYPE ekpo-meins, " Unit
         gv_netpr TYPE ekpo-netpr, " Net Price
*         GV_MWSKZ TYPE EKPO-MWSKZ, " Tax Code
*         GV_FISTL TYPE EKPO-FISTL, " Funds Center
       END OF gty_po_item.

* DECLARE BAPI DATA
DATA: gs_poheader    TYPE bapimepoheader, "Purchase Order Header Data
      gs_poheaderx   TYPE bapimepoheaderx, "Purchase Order Header Data (Change Parameter)
      gt_poitem      TYPE TABLE OF bapimepoitem, "Purchase Order Item
      gt_poitemx     TYPE TABLE OF bapimepoitemx, "Purchase Order Item (Change Parameter)
      gs_pocond      TYPE bapimepocondx, "Conditions in Purchase Order ( Change ToolBar )
      gt_pocond      TYPE TABLE OF bapimepocond,
      gt_poschedule  TYPE TABLE OF bapimeposchedule, " Purchase Order Delivery Schedule Lines
      gt_poschedulex TYPE TABLE OF bapimeposchedulx, " Fields for Schedule Lines in Purchase Order (Change Toolbar)
      gt_return      TYPE TABLE OF bapiret2. "Return - Notify messages

DATA:  gt_poheader TYPE TABLE OF bapimepoheader.

DATA: gs_poitem       TYPE bapimepoitem,
      gs_poitemx      TYPE bapimepoitemx,
      gs_po_schedule  TYPE bapimeposchedule,
      gs_po_schedulex TYPE bapimeposchedulx,
      gs_return       TYPE bapiret2,
      gv_po_number    TYPE ebeln,
      gv_message      TYPE string.

DATA: gs_po_header TYPE gty_po_header,
      gs_po_item   TYPE gty_po_item.

" Dùng ALV OOP Container
DATA: gv_grid_title TYPE lvc_title,
      gs_layout     TYPE lvc_s_layo,
      gs_variant    TYPE disvariant,
      gt_exclude    TYPE ui_functions,
      gt_sort       TYPE lvc_t_sort,
      gt_filter     TYPE lvc_t_filt,
      gt_fieldcat   TYPE lvc_t_fcat,
      gt_fieldcat02 TYPE lvc_t_fcat.

DATA: go_custom_cont_01 TYPE REF TO cl_gui_custom_container,
      go_custom_cont_02 TYPE REF TO cl_gui_custom_container,
      go_grid_01        TYPE REF TO cl_gui_alv_grid,
      go_grid_02        TYPE REF TO cl_gui_alv_grid.

*=====================================================================*
* Type Declarations for Mass Upload (Screen 300)
*=====================================================================*
TYPES: BEGIN OF ty_upload_item,
         supplier  TYPE lifnr,
         comp_code TYPE bukrs,
         doc_type  TYPE bsart,
         purch_org TYPE ekorg,
         pur_group TYPE ekgrp,
         item_no   TYPE ebelp,
         material  TYPE char18,
         plant     TYPE werks_d,
         storage   TYPE lgort_d,
         quantity  TYPE menge_d,
         unit      TYPE meins,
         net_price TYPE bprei,
       END OF ty_upload_item.

TYPES: BEGIN OF ty_po_group,
         supplier  TYPE lifnr,
         comp_code TYPE bukrs,
         doc_type  TYPE bsart,
         purch_org TYPE ekorg,
         pur_group TYPE ekgrp,
       END OF ty_po_group.

TYPES: BEGIN OF ty_po_result,
         supplier  TYPE lifnr,
         po_number TYPE ebeln,
         status    TYPE char1,    " S=Success, E=Error
         message   TYPE bapi_msg,
       END OF ty_po_result.

*=====================================================================*
* Global Data for Screen 300
*=====================================================================*
DATA: gt_upload_raw   TYPE TABLE OF string,
      gt_upload_items TYPE TABLE OF ty_upload_item,
      gs_upload_item  TYPE ty_upload_item,
      gt_po_groups    TYPE SORTED TABLE OF ty_po_group WITH UNIQUE KEY supplier,
      gs_po_group     TYPE ty_po_group,
      gt_po_results   TYPE TABLE OF ty_po_result,
      gs_po_result    TYPE ty_po_result,
      p_file          TYPE rlgrap-filename,
      gv_lines_read   TYPE i,
      gv_po_created   TYPE i,
      gv_po_failed    TYPE i.
