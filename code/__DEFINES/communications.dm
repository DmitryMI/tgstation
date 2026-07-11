/// The time an admin has to cancel a cross-sector message
#define CROSS_SECTOR_CANCEL_TIME (10 SECONDS)

/// The extended time an admin has to cancel a cross-sector message if they pass the filter, for instance
#define EXTENDED_CROSS_SECTOR_CANCEL_TIME (30 SECONDS)

/// Message originated from a non-CentCom source.
#define COMM_MESSAGE_SOURCE_MISC "misc"
/// Message originated from CentCom.
#define COMM_MESSAGE_SOURCE_CENTCOM "centcom"

//Security levels affect the escape shuttle timer
/// Security level is green. (no threats)
#define SEC_LEVEL_GREEN 0
/// Security level is blue. (caution advised)
#define SEC_LEVEL_BLUE 1
/// Security level is red. (hostile threats)
#define SEC_LEVEL_RED 2
/// Security level is delta. (station destruction immiment)
#define SEC_LEVEL_DELTA 3
