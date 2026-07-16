//+------------------------------------------------------------------+
//|                                  PitchforkPro GUI System         |
//|                        Copyright 2024, PitchforkPro Team         |
//|                                     https://pitchforkpro.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro Team"
#property link      "https://pitchforkpro.com"
#property version   "1.0.1"
#property description "Advanced Slide Panel GUI - Opens from left with smooth animation"

#include "PFP_Constants.mqh"
#include "PFP_Logger.mqh"

#define ANIMATION_STEP 50
#define PANEL_WIDTH 280
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
   
private:
   bool CreateMainButton();
   bool CreatePanel();
   bool CreateButtons();
   void SetPanelPosition(int x);
   void AnimatePanel();
   void DeleteAllObjects();
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
   m_is_expanded = !m_is_expanded;
   
   if(m_is_expanded) {
      if(!CreatePanel()) {
         if(m_logger) m_logger.Log("Failed to create panel", LOG_LEVEL_ERROR);
         m_is_expanded = false;
         return;
      }
      if(!CreateButtons()) {
         if(m_logger) m_logger.Log("Failed to create buttons", LOG_LEVEL_ERROR);
         m_is_expanded = false;
         return;
      }
      ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_HIDDEN, true);
      if(m_logger) m_logger.Log("Panel expanded", LOG_LEVEL_INFO);
   } else {
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
      ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_HIDDEN, false);
      if(m_logger) m_logger.Log("Panel collapsed", LOG_LEVEL_INFO);
   }
   
   ChartRedraw(m_chart_id);
}

//+------------------------------------------------------------------+
//| Handle chart events                                               |
//+------------------------------------------------------------------+
void CPFP_GUI::OnChartEvent(const int id, const long &lparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == m_main_btn_name || sparam == m_close_btn_name) {
         TogglePanel();
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
   int height = 220;
   int x = 0;
   int y = MARGIN_BOTTOM + BUTTON_SIZE_Y + 10;
   
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
   int startY = MARGIN_BOTTOM + 10;
   
   string btnNames[] = {m_scan_btn_name, m_replace_btn_name, m_clear_btn_name};
   string btnTexts[] = {"🔍 Scan Pitchforks", "🔄 Replace All", "🗑 Clear All"};
   
   for(int i = 0; i < 3; i++) {
      if(!ObjectCreate(m_chart_id, btnNames[i], OBJ_BUTTON, 0, 0, 0)) {
         return false;
      }
      
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_XDISTANCE, startX);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_YDISTANCE, startY + (i * (btnHeight + 8)));
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_XSIZE, btnWidth);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_YSIZE, btnHeight);
      ObjectSetString(m_chart_id, btnNames[i], OBJPROP_TEXT, btnTexts[i]);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_COLOR, PFP_COLOR_TEXT);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_BGCOLOR, PFP_COLOR_PRIMARY);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_FONTSIZE, 9);
      ObjectSetString(m_chart_id, btnNames[i], OBJPROP_FONT, "Arial");
      ObjectSetInteger(m_chart_id, btnNames[i], OBJPROP_SELECTABLE, false);
   }
   
   // Color Toggle Button
   if(!ObjectCreate(m_chart_id, m_color_toggle_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_YDISTANCE, startY + (3 * (btnHeight + 8)) + 5);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_color_toggle_btn_name, OBJPROP_TEXT, "🎨 Toggle Bull/Bear Color");
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_BGCOLOR, clrDarkGreen);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_color_toggle_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_color_toggle_btn_name, OBJPROP_SELECTABLE, false);
   
   // Warning Lines Toggle Button
   if(!ObjectCreate(m_chart_id, m_warning_lines_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_YDISTANCE, startY + (4 * (btnHeight + 8)) + 5);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_warning_lines_btn_name, OBJPROP_TEXT, "⚠️ Show/Hide Warning Lines");
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_BGCOLOR, clrOrangeRed);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_warning_lines_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_warning_lines_btn_name, OBJPROP_SELECTABLE, false);
   
   // Quarter Lines Toggle Button
   if(!ObjectCreate(m_chart_id, m_quarter_lines_btn_name, OBJ_BUTTON, 0, 0, 0)) {
      return false;
   }
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_YDISTANCE, startY + (5 * (btnHeight + 8)) + 5);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_XSIZE, btnWidth);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_YSIZE, btnHeight);
   ObjectSetString(m_chart_id, m_quarter_lines_btn_name, OBJPROP_TEXT, "📏 Show/Hide Quarter Lines");
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_COLOR, PFP_COLOR_TEXT);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_BGCOLOR, clrPurple);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_BORDER_COLOR, PFP_COLOR_BORDER);
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(m_chart_id, m_quarter_lines_btn_name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(m_chart_id, m_quarter_lines_btn_name, OBJPROP_SELECTABLE, false);
   
   if(!ObjectCreate(m_chart_id, m_status_label_name, OBJ_LABEL, 0, 0, 0)) {
      return false;
   }
   
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_YDISTANCE, startY + (6 * (btnHeight + 8)) + 15);
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
}
