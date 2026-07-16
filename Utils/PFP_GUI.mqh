//+------------------------------------------------------------------+
//|                                  PitchforkPro GUI System         |
//|                        Copyright 2024, PitchforkPro Team         |
//|                                     https://pitchforkpro.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro Team"
#property link      "https://pitchforkpro.com"
#property version   "1.0.1"
#property description "Advanced Slide Panel GUI - Opens from left with smooth animation"

#include <PFP_Constants.mqh>
#include <PFP_Logger.mqh>

#define ANIMATION_STEP 50
#define PANEL_WIDTH 280
#define BUTTON_SIZE_X 40
#define BUTTON_SIZE_Y 40
#define MARGIN_LEFT 10
#define MARGIN_BOTTOM 10

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
   void ExpandPanel();
   void CollapsePanel();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   void OnTimer();
   bool IsExpanded() const { return m_is_expanded; }
   bool IsInitialized() const { return m_is_initialized; }

private:
   bool CreateMainButton();
   bool CreatePanelBackground();
   bool CreateTitleLabel();
   bool CreateActionButtons();
   bool CreateStatusLabel();
   void UpdatePanelPosition(int x);
   void AnimatePanel();
   string GetObjectName(const string &suffix) const;
   color GetThemeColor(PFP_COLOR_TYPE type) const;
   void Log(const string &message, PFP_LOG_LEVEL level = PFP_LOG_INFO);
};

CPFP_GUI::CPFP_GUI(long chart_id, CPFP_Logger *logger)
{
   m_chart_id = chart_id;
   m_logger = logger;
   m_is_initialized = false;
   m_is_expanded = false;
   m_is_animating = false;
   m_base_name = "PFP_GUI_";
   m_button_y = (int)ChartGetInteger(chart_id, CHART_HEIGHT_IN_PIXELS) - MARGIN_BOTTOM - BUTTON_SIZE_Y;
   m_button_x = MARGIN_LEFT;
   m_panel_open_x = MARGIN_LEFT + BUTTON_SIZE_X;
   m_panel_closed_x = -PANEL_WIDTH - 10;
   m_panel_current_x = m_panel_closed_x;
   m_panel_target_x = m_panel_closed_x;
}

CPFP_GUI::~CPFP_GUI() { Deinitialize(); }

bool CPFP_GUI::Initialize()
{
   if(m_is_initialized) return true;
   EventSetTimer(1);
   if(!CreateMainButton()) return false;
   if(!CreatePanelBackground()) return false;
   if(!CreateTitleLabel()) return false;
   if(!CreateActionButtons()) return false;
   if(!CreateStatusLabel()) return false;
   CollapsePanel();
   m_is_initialized = true;
   return true;
}

void CPFP_GUI::Deinitialize()
{
   if(!m_is_initialized) return;
   EventKillTimer();
   for(int i = ObjectsTotal(m_chart_id, 0, OBJ_RECTANGLE_LABEL) - 1; i >= 0; i--)
   { string n = ObjectName(m_chart_id, i, 0, OBJ_RECTANGLE_LABEL); if(StringFind(n, m_base_name) == 0) ObjectDelete(m_chart_id, n); }
   for(int i = ObjectsTotal(m_chart_id, 0, OBJ_BUTTON) - 1; i >= 0; i--)
   { string n = ObjectName(m_chart_id, i, 0, OBJ_BUTTON); if(StringFind(n, m_base_name) == 0) ObjectDelete(m_chart_id, n); }
   for(int i = ObjectsTotal(m_chart_id, 0, OBJ_LABEL) - 1; i >= 0; i--)
   { string n = ObjectName(m_chart_id, i, 0, OBJ_LABEL); if(StringFind(n, m_base_name) == 0) ObjectDelete(m_chart_id, n); }
   m_is_initialized = false;
}

void CPFP_GUI::TogglePanel() { if(m_is_animating) return; if(m_is_expanded) CollapsePanel(); else ExpandPanel(); }

void CPFP_GUI::ExpandPanel()
{
   if(m_is_expanded || m_is_animating) return;
   m_is_expanded = true;
   m_panel_target_x = m_panel_open_x;
   m_is_animating = true;
   AnimatePanel();
}

void CPFP_GUI::CollapsePanel()
{
   if(!m_is_expanded || m_is_animating) return;
   m_is_expanded = false;
   m_panel_target_x = m_panel_closed_x;
   m_is_animating = true;
   AnimatePanel();
}

void CPFP_GUI::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == m_main_btn_name) { ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_STATE, false); TogglePanel(); }
      else if(sparam == m_close_btn_name) { ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_STATE, false); CollapsePanel(); }
      else if(sparam == m_scan_btn_name) { ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_STATE, false); EventChartCustom(m_chart_id, PFP_EVENT_SCAN, 0, 0, "GUI_SCAN"); }
      else if(sparam == m_replace_btn_name) { ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_STATE, false); EventChartCustom(m_chart_id, PFP_EVENT_REPLACE, 0, 0, "GUI_REPLACE"); }
      else if(sparam == m_clear_btn_name) { ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_STATE, false); EventChartCustom(m_chart_id, PFP_EVENT_CLEAR, 0, 0, "GUI_CLEAR"); }
   }
   else if(id == CHARTEVENT_CHART_CHANGE)
   {
      int new_y = (int)ChartGetInteger(m_chart_id, CHART_HEIGHT_IN_PIXELS) - MARGIN_BOTTOM - BUTTON_SIZE_Y;
      if(new_y != m_button_y)
      {
         m_button_y = new_y;
         ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_XDISTANCE, m_button_x);
         ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_YDISTANCE, m_button_y);
         if(m_is_expanded && !m_is_animating) UpdatePanelPosition(m_panel_open_x);
      }
   }
}

void CPFP_GUI::OnTimer() { if(m_is_animating) AnimatePanel(); }

bool CPFP_GUI::CreateMainButton()
{
   m_main_btn_name = GetObjectName("MAIN_BTN");
   if(!ObjectCreate(m_chart_id, m_main_btn_name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_XDISTANCE, m_button_x);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_YDISTANCE, m_button_y);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_XSIZE, BUTTON_SIZE_X);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_YSIZE, BUTTON_SIZE_Y);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_BGCOLOR, GetThemeColor(PFP_COLOR_PRIMARY));
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_BORDER_COLOR, GetThemeColor(PFP_COLOR_BORDER));
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_TEXT, ">");
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_ZORDER, 100);
   return true;
}

bool CPFP_GUI::CreatePanelBackground()
{
   m_panel_bg_name = GetObjectName("PANEL_BG");
   if(!ObjectCreate(m_chart_id, m_panel_bg_name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XDISTANCE, m_panel_closed_x);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_YDISTANCE, m_button_y);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XSIZE, PANEL_WIDTH);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_YSIZE, 160);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_BGCOLOR, GetThemeColor(PFP_COLOR_BG_PANEL));
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_BORDER_COLOR, GetThemeColor(PFP_COLOR_PRIMARY));
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_ZORDER, 90);
   return true;
}

bool CPFP_GUI::CreateTitleLabel()
{
   m_title_label_name = GetObjectName("TITLE");
   if(!ObjectCreate(m_chart_id, m_title_label_name, OBJ_LABEL, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_XDISTANCE, m_panel_closed_x + 10);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_YDISTANCE, m_button_y + 135);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_COLOR, GetThemeColor(PFP_COLOR_TEXT));
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_TEXT, "PitchforkPro v1.0.1");
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_HIDDEN, true);
   return true;
}

bool CPFP_GUI::CreateActionButtons()
{
   int btn_w = 80, btn_h = 30, sp = 5;
   int sx = m_panel_closed_x + 10, sy = m_button_y + 90;
   m_scan_btn_name = GetObjectName("BTN_SCAN");
   if(!ObjectCreate(m_chart_id, m_scan_btn_name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_XDISTANCE, sx);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_YDISTANCE, sy);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_XSIZE, btn_w);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_YSIZE, btn_h);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_TEXT, "Scan");
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_BGCOLOR, GetThemeColor(PFP_COLOR_ACCENT));
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_HIDDEN, true);
   
   m_replace_btn_name = GetObjectName("BTN_REPLACE");
   if(!ObjectCreate(m_chart_id, m_replace_btn_name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_XDISTANCE, sx + btn_w + sp);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_YDISTANCE, sy);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_XSIZE, btn_w);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_YSIZE, btn_h);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_TEXT, "Replace");
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_BGCOLOR, GetThemeColor(PFP_COLOR_PRIMARY));
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_HIDDEN, true);
   
   m_clear_btn_name = GetObjectName("BTN_CLEAR");
   if(!ObjectCreate(m_chart_id, m_clear_btn_name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_XDISTANCE, sx);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_YDISTANCE, sy - btn_h - sp);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_XSIZE, btn_w * 2 + sp);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_YSIZE, btn_h);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_TEXT, "Clear All");
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_BGCOLOR, clrDarkRed);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_HIDDEN, true);
   
   m_close_btn_name = GetObjectName("BTN_CLOSE");
   if(!ObjectCreate(m_chart_id, m_close_btn_name, OBJ_BUTTON, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XDISTANCE, m_panel_closed_x + PANEL_WIDTH - 30);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YDISTANCE, m_button_y + 130);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XSIZE, 25);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YSIZE, 25);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_TEXT, "X");
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_BGCOLOR, clrGray);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_FONTSIZE, 14);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_HIDDEN, true);
   return true;
}

bool CPFP_GUI::CreateStatusLabel()
{
   m_status_label_name = GetObjectName("STATUS");
   if(!ObjectCreate(m_chart_id, m_status_label_name, OBJ_LABEL, 0, 0, 0)) return false;
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_XDISTANCE, m_panel_closed_x + 10);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_YDISTANCE, m_button_y + 60);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_COLOR, GetThemeColor(PFP_COLOR_TEXT_SECONDARY));
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_TEXT, "Ready");
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_HIDDEN, true);
   return true;
}

void CPFP_GUI::AnimatePanel()
{
   if(!m_is_animating) return;
   int step = ANIMATION_STEP;
   bool finished = false;
   if(m_panel_current_x < m_panel_target_x) { m_panel_current_x += step; if(m_panel_current_x >= m_panel_target_x) { m_panel_current_x = m_panel_target_x; finished = true; } }
   else if(m_panel_current_x > m_panel_target_x) { m_panel_current_x -= step; if(m_panel_current_x <= m_panel_target_x) { m_panel_current_x = m_panel_target_x; finished = true; } }
   UpdatePanelPosition(m_panel_current_x);
   ObjectSetInteger(m_chart_id, m_main_btn_name, OBJPROP_TEXT, m_is_expanded ? "<" : ">");
   if(finished) m_is_animating = false;
}

void CPFP_GUI::UpdatePanelPosition(int x)
{
   ObjectSetInteger(m_chart_id, m_panel_bg_name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(m_chart_id, m_title_label_name, OBJPROP_XDISTANCE, x + 10);
   int btn_w = 80, sp = 5, sx = x + 10, sy = m_button_y + 90;
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_XDISTANCE, sx);
   ObjectSetInteger(m_chart_id, m_scan_btn_name, OBJPROP_YDISTANCE, sy);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_XDISTANCE, sx + btn_w + sp);
   ObjectSetInteger(m_chart_id, m_replace_btn_name, OBJPROP_YDISTANCE, sy);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_XDISTANCE, sx);
   ObjectSetInteger(m_chart_id, m_clear_btn_name, OBJPROP_YDISTANCE, sy - 35);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_XDISTANCE, x + PANEL_WIDTH - 30);
   ObjectSetInteger(m_chart_id, m_close_btn_name, OBJPROP_YDISTANCE, m_button_y + 130);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(m_chart_id, m_status_label_name, OBJPROP_YDISTANCE, m_button_y + 60);
}

string CPFP_GUI::GetObjectName(const string &suffix) const { return m_base_name + suffix; }

color CPFP_GUI::GetThemeColor(PFP_COLOR_TYPE type) const
{
   switch(type) { case PFP_COLOR_PRIMARY: return clrDodgerBlue; case PFP_COLOR_ACCENT: return clrGreen; case PFP_COLOR_BG_PANEL: return clrBlack; case PFP_COLOR_TEXT: return clrWhite; case PFP_COLOR_TEXT_SECONDARY: return clrLightGray; case PFP_COLOR_BORDER: return clrDarkGray; default: return clrWhite; }
}

void CPFP_GUI::Log(const string &message, PFP_LOG_LEVEL level) { if(m_logger) m_logger->Log(message, level); else Print("[GUI] ", message); }
