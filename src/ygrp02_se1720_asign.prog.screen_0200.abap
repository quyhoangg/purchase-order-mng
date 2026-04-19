PROCESS BEFORE OUTPUT.
  MODULE status_0200.

PROCESS AFTER INPUT.

  MODULE exit AT EXIT-COMMAND.

  MODULE user_command_0200.

PROCESS ON VALUE-REQUEST.

  FIELD gs_po_header-gv_lifnr MODULE value_request_lifnr.
