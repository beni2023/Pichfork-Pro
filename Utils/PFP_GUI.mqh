//+------------------------------------------------------------------+
//|                                  PitchforkPro GUI System         |
//|                        Copyright 2024, PitchforkPro Team         |
//|                                     https://pitchforkpro.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro Team"
#property link      "https://pitchforkpro.com"
#property version   "1.0.1"
#property description "Advanced Slide Panel GUI - Bottom-left sidebar with smooth animation"

#include "PFP_Constants.mqh"
#include "PFP_Logger.mqh"

#define ANIMATION_STEP 30
#define PANEL_WIDTH 300
#define PANEL_HEIGHT 380
#define BUTTON_SIZE_X 40
#define BUTTON_SIZE_Y 40
#define MARGIN_LEFT 10
#define MARGIN_BOTTOM 10

// Define corner constants if not available
#ifndef CORNER_LEFT_BOTTOM
#define CORNER_LEFT_BOTTOM 1
#endif
#ifndef CORNER_RIGHT_BOTTOM
#define CORNER_RIGHT_BOTTOM 2
#endif
#ifndef CORNER_LEFT_TOP
#define CORNER_LEFT_TOP 0
#endif
#ifndef CORNER_RIGHT_TOP
#define CORNER_RIGHT_TOP 3
#endif

class CPFP_GUI
{
private:
   CPFP_Logger *m_logger;
   long m_chart_id;
   bool m_is_initialized;
   bool m_is_expanded;
   bool m_is_animating;
   string m_base_name;
   string m_main_btn_name;
   string m_panel_bg_name;
   string m_title_label_name;
   string m_scan_btn_name;
   string m_replace_btn_name;
   string m_clear_btn_name;
   string m_close_btn_name;
   string m_status_label_name;
   string m_color_toggle_btn_name;
   string m_warning_lines_btn_name;
   string m_quarter_lines_btn_name;
   int m_panel_current_x;
   int m_panel_target_x;
   int m_panel_closed_x;
   int m_panel_open_x;
   int m_button_x;
   int m_button_y;

public:
   CPFP_GUI(long chart_id, CPFP_Logger *logger);
   ~CPFP_GUI();
   bool Initialize();
   void Deinitialize();
   void TogglePanel();
   void OnChartEvent(const int id, const long &lparam, const string &sparam);
   void UpdateStatus(const string &status);
   void ShowPanel();
   void HidePanel();
   
private:
   bool CreateMainButton();
   bool CreatePanel();
   bool CreateButtons();
   void SetPanelPosition(int x);
   void AnimatePanel();
   void DeleteAllObjects();
   bool m_panel_visible;
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CPFP_GUI::CPFP_GUI(long chart_id, CPFP_Logger *logger)
{
   m_chart_id = chart_id;
   m_logger = logger;
   m_is_initialized = false;
   m_is_expanded = false;
   m_is_animating = false;
   m_panel_visible = false;
   m_base_name = "PFP_GUI_";
   m_main_btn_name = m_base_name + "MainBtn";
   m_panel_bg_name = m_base_name + "PanelBG";
   m_title_label_name = m_base_name + "Title";
   m_scan_btn_name = m_base_name + "ScanBtn";
   m_replace_btn_name = m_base_name + "ReplaceBtn";
   m_clear_btn_name = m_base_name + "ClearBtn";
   m_close_btn_name = m_base_name + "CloseBtn";
   m_status_label_name = m_base_name + "Status";
   m_color_toggle_btn_name = m_base_name + "ColorToggleBtn";
   m_warning_lines_btn_name = m_base_name + "WarningLinesBtn";
   m_quarter_lines_btn_name = m_base_name + "QuarterLinesBtn";
   m_panel_current_x = -PANEL_WIDTH;
   m_panel_closed_x = -PANEL_WIDTH;
   m_panel_open_x = 0;
   m_button_x = MARGIN_LEFT;
   m_button_y = MARGIN_BOTTOM;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CPFP_GUI::~CPFP_GUI()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize GUI                                                    |
//+------------------------------------------------------------------+
bool CPFP_GUI::Initialize()
{
   if(m_is_initialized) return true;
   
   if(!CreateMainButton()) {
      if(m_logger) m_logger.Log("Failed to create main button", LOG_LEVEL_ERROR);
      return false;
   }
   
   m_is_initialized = true;
   if(m_logger) m_logger.Log("GUI initialized (collapsed mode)", LOG_LEVEL_INFO);
   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize GUI                                                  |
//+------------------------------------------------------------------+
void CPFP_GUI::Deinitialize()
{
   if(!m_is_initialized) return;
   DeleteAllObjects();
   m_is_initialized = false;
   if(m_logger) m_logger.Log("GUI deinitialized", LOG_LEVEL_INFO);
}

//+------------------------------------------------------------------+
//| Toggle panel open/closed                                          |
//+------------------------------------------------------------------+
void CPFP_GUI::TogglePanel()
{
   if(m_panel_visible) {
      HidePanel();
   } else {
      ShowPanel();
   }
}

//+------------------------------------------------------------------+
//| Show panel with slide animation                                   |
//+------------------------------------------------------------------+
void CPFP_GUI::ShowPanel()
{
   if(m_panel_visible) return;
   
   // Create panel if not exists
   if(ObjectFind(m_chart_id, m_panel_bg_name) < 0) {
      if(!CreatePanel()) {
         if(m_logger) m_logger.Log("Failed to create panel", LOG_LEVEL_ERROR);
         return;
      }
      if(!CreateButtons()) {
         if(m_logger) m_logger.Log("Failed to create buttons", LOG_LEVEL_ERROR);
         return;
      }
   }
   
   // Hide main button
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_HIDDEN, true);
   
   // Set initial position (off-screen left)
   m_panel_current_x = -PANEL_WIDTH;
   m_panel_target_x = 0;
   m_panel_visible = true;
   
   // Start animation
   AnimatePanel();
   
   if(m_logger) m_logger.Log("Panel shown with slide animation", LOG_LEVEL_INFO);
}

//+------------------------------------------------------------------+
//| Hide panel with slide animation                                   |
//+------------------------------------------------------------------+
void CPFP_GUI::HidePanel()
{
   if(!m_panel_visible) return;
   
   // Set target position (off-screen left)
   m_panel_target_x = -PANEL_WIDTH;
   m_panel_visible = false;
   
   // Start animation
   AnimatePanel();
   
   if(m_logger) m_logger.Log("Panel hidden with slide animation", LOG_LEVEL_INFO);
}

//+------------------------------------------------------------------+
//| Handle chart events                                               |
//+------------------------------------------------------------------+
void CPFP_GUI::OnChartEvent(const int id, const long &lparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_main_btn_name) {
         TogglePanel();
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
      }
      else if(sparam == m_close_btn_name) {
         HidePanel();
         ObjectSetInteger(m_chart_id, sparam, OBJPROP_STATE, false);
      }
      else if(sparam == m_scan_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_SCAN, 0, 0, "SCAN");
         ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Scan requested", LOG_LEVEL_INFO);
      }
      else if(sparam == m_replace_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_REPLACE, 0, 0, "REPLACE");
         ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Replace requested", LOG_LEVEL_INFO);
      }
      else if(sparam == m_clear_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_CLEAR, 0, 0, "CLEAR");
         ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Clear all requested", LOG_LEVEL_INFO);
      }
      else if(sparam == m_color_toggle_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_TOGGLE_COLOR, 0, 0, "TOGGLE_COLOR");
         ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Toggle fork color requested", LOG_LEVEL_INFO);
      }
      else if(sparam == m_warning_lines_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_TOGGLE_WARNING, 0, 0, "TOGGLE_WARNING");
         ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Toggle warning lines requested", LOG_LEVEL_INFO);
      }
      else if(sparam == m_quarter_lines_btn_name) {
         EventChartCustom(m_chart_id, PFP_EVENT_TOGGLE_QUARTER, 0, 0, "TOGGLE_QUARTER");
         ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_STATE, false);
         if(m_logger) m_logger.Log("Toggle quarter lines requested", LOG_LEVEL_INFO);
      }
   }
}

//+------------------------------------------------------------------+
//| Update status label                                               |
//+------------------------------------------------------------------+
void CPFP_GUI::UpdateStatus(const string &status)
{
   if(ObjectFind(m_chart_id, m_status_label_name) >= 0) {
      ObjectSetString(m_chart_id, m_status_label_name, OBJPROP_TEXT, status);
   }
}

//+------------------------------------------------------------------+
//| Create main toggle button                                         |
//+------------------------------------------------------------------+
bool CPFP_GUI::CreateMainButton()
{
   if(!ObjectCreate(m_chart_id, m_main_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_XDISTANCE, MARGIN_LEFT);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_YDISTANCE, MARGIN_BOTTOM);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_XSIZE, BUTTON_SIZE_X);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_YSIZE, BUTTON_SIZE_Y);
   ObjectSetString(m_chart_id, m_main_btn_name, OBJPROP_TEXT, "▶");
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_COLOR, PFP_COLOR_PRIMARY);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_BGCOLOR, PFP_COLOR_BG_PANEL);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_FONTSIZE, 16);
   ObjectSetString(m_chart_id, m_main_btn_name, OBJPROP_FONT, "Segoe UI Symbol");
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_CORNER, CORNER_LEFT_BOTTOM);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create panel background                                           |
//+------------------------------------------------------------------+
bool CPFP_GUI::CreatePanel()
{
   int width = PANEL_WIDTH;
   int height = PANEL_HEIGHT;
   int x = 0;
   int y = MARGIN_BOTTOM + BUTTON_SIZE_Y + 10;
   
   // Panel background rectangle
   if(!ObjectCreate(m_chart_id, m_panel_bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XSIZE, width);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_YSIZE, height);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_BGCOLOR, PFP_COLOR_BG_PANEL);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_CORNER, CORNER_LEFT_BOTTOM);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_SELECTABLE, false);
   
   // Title label
   if(!ObjectCreate(m_chart_id, m_title_label_name, OBJ_LABEL, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_YDISTANCE, y + height - 35);
   ObjectSetString(m_chart_id, m_title_label_name, OBJPROP_TEXT, "PitchforkPro v1.0.1");
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_FONTSIZE, 11);
   ObjectSetString(m_chart_id, m_title_label_name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_SELECTABLE, false);
   
   // Close button (X icon at top-right of panel)
   if(!ObjectCreate(m_chart_id, m_close_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XDISTANCE, x + width - 35);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YDISTANCE, y + height - 38);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XSIZE, 25);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YSIZE, 25);
   ObjectSetString(m_chart_id, m_close_btn_name, OBJPROP_TEXT, "✕");
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_BGCOLOR, clrDarkRed);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_FONTSIZE, 14);
   ObjectSetString(m_chart_id, m_close_btn_name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_CORNER, CORNER_LEFT_BOTTOM);
   
   return true;
}

//+------------------------------------------------------------------+
//| Create action buttons                                             |
//+------------------------------------------------------------------+
bool CPFP_GUI::CreateButtons()
{
   int btnWidth = PANEL_WIDTH - 20;
   int btnHeight = 35;
   int startX = 10;
   int startY = 50; // Start from top of panel (below title)
   
   // Button 1: Scan Pitchforks
   if(!ObjectCreate(m_chart_id, m_scan_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_YDISTANCE, startY);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_scan_btn_name, OBJPROP_TEXT, "🔍 Scan Pitchforks");
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_BGCOLOR, PFP_COLOR_PRIMARY);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_scan_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_SELECTABLE, false);
   
   // Button 2: Replace All
   if(!ObjectCreate(m_chart_id, m_replace_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_YDISTANCE, startY + (btnHeight + 8));
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_replace_btn_name, OBJPROP_TEXT, "🔄 Replace All");
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_BGCOLOR, clrDarkOrange);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_replace_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_SELECTABLE, false);
   
   // Button 3: Clear All
   if(!ObjectCreate(m_chart_id, m_clear_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_YDISTANCE, startY + (2 * (btnHeight + 8)));
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_clear_btn_name, OBJPROP_TEXT, "🗑 Clear All");
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_BGCOLOR, clrDarkRed);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_clear_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_SELECTABLE, false);
   
   // Separator line
   int sepY = startY + (3 * (btnHeight + 8)) - 5;
   if(!ObjectCreate(m_chart_id, m_base_name + "Sep1", OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_YDISTANCE, sepY);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_YSIZE, 2);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_BGCOLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_CORNER, CORNER_LEFT_BOTTOM);
   
   // Button 4: Color Toggle
   if(!ObjectCreate(m_chart_id, m_color_toggle_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_YDISTANCE, sepY + 10);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_color_toggle_btn_name, OBJPROP_TEXT, "🎨 Toggle Bull/Bear Color");
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_BGCOLOR, clrDarkGreen);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_color_toggle_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_SELECTABLE, false);
   
   // Button 5: Warning Lines Toggle
   if(!ObjectCreate(m_chart_id, m_warning_lines_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_YDISTANCE, sepY + 10 + (btnHeight + 8));
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_warning_lines_btn_name, OBJPROP_TEXT, "⚠️ Show/Hide Warning Lines");
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_BGCOLOR, clrOrangeRed);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_warning_lines_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_SELECTABLE, false);
   
   // Button 6: Quarter Lines Toggle
   if(!ObjectCreate(m_chart_id, m_quarter_lines_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_YDISTANCE, sepY + 10 + (2 * (btnHeight + 8)));
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_quarter_lines_btn_name, OBJPROP_TEXT, "📏 Show/Hide Quarter Lines");
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_BGCOLOR, clrPurple);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_quarter_lines_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_SELECTABLE, false);
   
   // Status label at bottom
   if(!ObjectCreate(m_chart_id, m_status_label_name, OBJ_LABEL, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_YDISTANCE, sepY + 10 + (3 * (btnHeight + 8)) + 10);
   ObjectSetString(m_chart_id, m_status_label_name, OBJPROP_TEXT, "Ready");
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_COLOR, PFP_COLOR_TEXT_SECONDARY);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_FONTSIZE, 8);
   ObjectSetString(m_chart_id, m_status_label_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_SELECTABLE, false);
   
   return true;
}

//+------------------------------------------------------------------+
//| Delete all GUI objects                                            |
//+------------------------------------------------------------------+
void CPFP_GUI::DeleteAllObjects()
{
   ObjectDelete(m_chart_id, m_main_btn_name);
   ObjectDelete(m_chart_id, m_panel_bg_name);
   ObjectDelete(m_chart_id, m_title_label_name);
   ObjectDelete(m_chart_id, m_scan_btn_name);
   ObjectDelete(m_chart_id, m_replace_btn_name);
   ObjectDelete(m_chart_id, m_clear_btn_name);
   ObjectDelete(m_chart_id, m_close_btn_name);
   ObjectDelete(m_chart_id, m_status_label_name);
   ObjectDelete(m_chart_id, m_color_toggle_btn_name);
   ObjectDelete(m_chart_id, m_warning_lines_btn_name);
   ObjectDelete(m_chart_id, m_quarter_lines_btn_name);
   ObjectDelete(m_chart_id, m_base_name + "Sep1");
}

//+------------------------------------------------------------------+
//| Set panel position                                                |
//+------------------------------------------------------------------+
void CPFP_GUI::SetPanelPosition(int x)
{
   int y = MARGIN_BOTTOM + BUTTON_SIZE_Y + 10;
   
   // Move panel background
   if(ObjectFind(m_chart_id, m_panel_bg_name) >= 0) {
      ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_YDISTANCE, y);
   }
   
   // Move title
   if(ObjectFind(m_chart_id, m_title_label_name) >= 0) {
      ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_YDISTANCE, y + PANEL_HEIGHT - 35);
   }
   
   // Move close button
   if(ObjectFind(m_chart_id, m_close_btn_name) >= 0) {
      ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XDISTANCE, x + PANEL_WIDTH - 35);
      ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YDISTANCE, y + PANEL_HEIGHT - 38);
   }
   
   // Move all buttons
   int btnWidth = PANEL_WIDTH - 20;
   int btnHeight = 35;
   int startX = 10;
   int startY = 50;
   int sepY = startY + (3 * (btnHeight + 8)) - 5;
   
   string btnNames[] = {m_scan_btn_name, m_replace_btn_name, m_clear_btn_name, 
                        m_color_toggle_btn_name, m_warning_lines_btn_name, m_quarter_lines_btn_name};
   int btnYOffsets[] = {startY, startY + (btnHeight + 8), startY + (2 * (btnHeight + 8)),
                        sepY + 10, sepY + 10 + (btnHeight + 8), sepY + 10 + (2 * (btnHeight + 8))};
   
   for(int i = 0; i < 6; i++) {
      if(ObjectFind(m_chart_id, btnNames[i]) >= 0) {
         ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_XDISTANCE, x + startX);
         ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_YDISTANCE, y + btnYOffsets[i]);
      }
   }
   
   // Move separator
   if(ObjectFind(m_chart_id, m_base_name + "Sep1") >= 0) {
      ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_XDISTANCE, x + startX);
      ObjectSetInteger(m_chart_id, m_base_name + "Sep1", OBJPROP_YDISTANCE, y + sepY);
   }
   
   // Move status label
   if(ObjectFind(m_chart_id, m_status_label_name) >= 0) {
      ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_XDISTANCE, x + startX);
      ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_YDISTANCE, y + sepY + 10 + (3 * (btnHeight + 8)) + 10);
   }
}

//+------------------------------------------------------------------+
//| Animate panel sliding                                             |
//+------------------------------------------------------------------+
void CPFP_GUI::AnimatePanel()
{
   if(m_is_animating) return;
   
   m_is_animating = true;
   
   // Simple slide animation loop
   while(m_panel_current_x != m_panel_target_x) {
      if(m_panel_current_x < m_panel_target_x) {
         m_panel_current_x += ANIMATION_STEP;
         if(m_panel_current_x > m_panel_target_x) m_panel_current_x = m_panel_target_x;
      } else {
         m_panel_current_x -= ANIMATION_STEP;
         if(m_panel_current_x < m_panel_target_x) m_panel_current_x = m_panel_target_x;
      }
      
      SetPanelPosition(m_panel_current_x);
      ChartRedraw(m_chart_id);
      Sleep(10); // Small delay for smooth animation
   }
   
   // Show/hide main button based on panel state
   if(!m_panel_visible) {
      ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_HIDDEN, false);
   }
   
   m_is_animating = false;
}
