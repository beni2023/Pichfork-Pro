#ifndef PFP_CONSTANTS_MQH
#define PFP_CONSTANTS_MQH

// CORNER constants are built-in MQL5, no need to include stdlib.mqh
// #include <stdlib.mqh>  // Removed - causes compilation error

//==================================================
// Pitchfork Types
//==================================================

#define PFP_MAX_PITCHFORKS 100

enum ENUM_PFP_TYPE
{
   PFP_STANDARD = 0,
   PFP_SCHIFF = 1,
   PFP_MODIFIED_SCHIFF = 2,
   PFP_UNKNOWN = 3,
   ENUM_PFP_TYPE_UNKNOWN = 3
};

//==================================================
// Pitchfork Direction
//==================================================

enum ENUM_PFP_DIRECTION
{
   PFP_NEUTRAL = 0,
   PFP_BULLISH = 1,
   PFP_BEARISH = 2
};

//==================================================
// Object Prefix
//==================================================

#define PFP_PREFIX "PFP_"

//==================================================
// Storage File
//==================================================

#define PFP_STORAGE_FILE "PFP_Data.bin"

//==================================================
// Renderer Settings
//==================================================

#define PFP_DEFAULT_WIDTH 2

//==================================================
// Colors
//==================================================

#define PFP_COLOR_BULL clrDarkGreen
#define PFP_COLOR_BEAR clrRed
#define PFP_COLOR_NEUTRAL clrGray
#define PFP_COLOR_MEDIAN clrGold

// GUI Theme Colors
#define PFP_COLOR_PRIMARY clrDodgerBlue
#define PFP_COLOR_ACCENT clrOrange
#define PFP_COLOR_BG_PANEL clrBlack
#define PFP_COLOR_TEXT clrWhite
#define PFP_COLOR_TEXT_SECONDARY clrLightGray
#define PFP_COLOR_BORDER clrDarkSlateGray

//==================================================
// Event Types
//==================================================

#define PFP_EVENT_SCAN 1001
#define PFP_EVENT_REPLACE 1002
#define PFP_EVENT_CLEAR 1003
#define PFP_EVENT_TOGGLE 1004
#define PFP_EVENT_TOGGLE_COLOR 1005
#define PFP_EVENT_TOGGLE_WARNING 1006
#define PFP_EVENT_TOGGLE_QUARTER 1007

//==================================================
// GUI Theme
//==================================================

enum ENUM_PFP_THEME
{
   THEME_LIGHT = 0,
   THEME_DARK = 1
};

//==================================================
// Build Version
//==================================================

#define PFP_VERSION "1.0.1"

#endif
