#ifndef PFP_CONSTANTS_MQH
#define PFP_CONSTANTS_MQH



//==================================================
// Pitchfork Types
//==================================================

enum ENUM_PFP_TYPE
{

   PFP_STANDARD = 0,

   PFP_SCHIFF = 1,

   PFP_MODIFIED_SCHIFF = 2

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





//==================================================
// Build Version
//==================================================

#define PFP_VERSION "0.5.0"




#endif