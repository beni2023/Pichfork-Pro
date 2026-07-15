//+------------------------------------------------------------------+
//|                                              PFP_Dashboard.mqh   |
//|                                  Copyright 2024, PitchforkPro    |
//|                                             https://example.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro"
#property link      "https://example.com"
#property version   "1.00"
#property strict

#include "../Utils/PFP_Logger.mqh"

//--- Dashboard Constants
#define DASHBOARD_WIDTH     260
#define DASHBOARD_HEIGHT    280
#define DASHBOARD_X         10
#define DASHBOARD_Y         50
#define BTN_HEIGHT          30
#define BTN_WIDTH           115
#define GAP                 5
#define FONT_NAME           "Segoe UI"
#define FONT_SIZE           9

//--- Colors
color COLOR_BG_LIGHT      = clrWhite;
color COLOR_BG_DARK       = clrBlack;
color COLOR_PANEL_BG      = clrDimGray;
color COLOR_TEXT_MAIN     = clrWhite;
color COLOR_TEXT_SUB      = clrLightGray;
color COLOR_BTN_NORMAL    = clrRoyalBlue;
color COLOR_BTN_HOVER     = clrDodgerBlue;
color COLOR_BTN_ACTIVE    = clrGreen;
color COLOR_BTN_DELETE    = clrBrown;

//+------------------------------------------------------------------+
//| Class CPFP_Dashboard                                             |
//+------------------------------------------------------------------+
class CPFP_Dashboard
{
private:
   string            m_prefix;
   long              m_chart_id;
   int               m_subwin;
   
   // Objects
   string            m_bg_name;
   string            m_title_name;
   string            m_status_label;
   string            m_count_label;
   string            m_storage_label;
   
   // Buttons
   string            m_btn_scan;
   string            m_btn_clear;
   string            m_btn_toggle_mode;
   string            m_btn_help;
   
   bool              m_is_dark_mode;
   bool              m_is_mouse_over;
   
   CPFP_Logger       *m_logger;
   
   // State
   bool              m_scan_enabled;
   bool              m_replace_mode;

public:
   CPFP_Dashboard(long chart_id, CPFP_Logger *logger)
   {
      m_logger = logger;
      m_prefix = "PFP_Dash_";
      m_chart_id = chart_id;
      m_subwin = 0;
      m_is_dark_mode = true;
      m_scan_enabled = true;
      m_replace_mode = false;
      
      InitNames();
   }
   
   ~CPFP_Dashboard()
   {
      DeleteAll();
   }
   
   //--- Initialize object names
   void InitNames()
   {
      m_bg_name = m_prefix + "BG";
      m_title_name = m_prefix + "Title";
      m_status_label = m_prefix + "Status";
      m_count_label = m_prefix + "Count";
      m_storage_label = m_prefix + "Storage";
      
      m_btn_scan = m_prefix + "BtnScan";
      m_btn_clear = m_prefix + "BtnClear";
      m_btn_toggle_mode = m_prefix + "BtnMode";
      m_btn_help = m_prefix + "BtnHelp";
   }
   
   //--- Create Dashboard
   bool Create()
   {
      DeleteAll(); // Clean old
      
      // Background Panel
      if(!CreateRectLabel(m_bg_name, DASHBOARD_X, DASHBOARD_Y, DASHBOARD_WIDTH, DASHBOARD_HEIGHT, 
                          m_is_dark_mode ? clrBlack : clrWhite, 0, clrGray, 1)) return false;
      
      // Title
      if(!CreateLabel(m_title_name, DASHBOARD_X + 10, DASHBOARD_Y + 5, "PitchforkPro v2.0", 
                      clrGold, 10, true)) return false;
      
      // Status Info
      UpdateInfo(0, true);
      
      // Buttons Row 1
      int btnY = DASHBOARD_Y + DASHBOARD_HEIGHT - (BTN_HEIGHT * 2) - (GAP * 3) - 40;
      if(!CreateButton(m_btn_scan, DASHBOARD_X + GAP, btnY, BTN_WIDTH, BTN_HEIGHT, "اسکن مجدد", clrWhite, COLOR_BTN_NORMAL)) return false;
      if(!CreateButton(m_btn_clear, DASHBOARD_X + GAP + BTN_WIDTH + GAP, btnY, BTN_WIDTH, BTN_HEIGHT, "حذف همه", clrWhite, COLOR_BTN_DELETE)) return false;
      
      // Buttons Row 2
      btnY += BTN_HEIGHT + GAP;
      string modeText = m_replace_mode ? "حالت: جایگزینی" : "حالت: عادی";
      clr modeColor = m_replace_mode ? COLOR_BTN_ACTIVE : COLOR_BTN_NORMAL;
      if(!CreateButton(m_btn_toggle_mode, DASHBOARD_X + GAP, btnY, BTN_WIDTH * 2 + GAP, BTN_HEIGHT, modeText, clrWhite, modeColor)) return false;
      
      // Help Text
      if(!CreateLabel(m_prefix + "Help", DASHBOARD_X + 10, DASHBOARD_Y + DASHBOARD_HEIGHT - 20, 
                      "کلیدها: S=اسکن, R=ریست, Del=حذف", clrSilver, 8, false)) return false;
      
      m_logger->Info("Dashboard created successfully");
      return true;
   }
   
   //--- Update Info Labels
   void Update(int count, bool storage_ok)
   {
      CreateLabel(m_status_label, DASHBOARD_X + 10, DASHBOARD_Y + 25, "وضعیت: " + (storage_ok ? "فعال" : "خطا"), storage_ok ? clrLime : clrRed, 9, false);
      CreateLabel(m_count_label, DASHBOARD_X + 10, DASHBOARD_Y + 45, "پیچ‌فورک‌ها: " + IntegerToString(count), clrWhite, 9, false);
      CreateLabel(m_storage_label, DASHBOARD_X + 10, DASHBOARD_Y + 65, "ذخیره‌سازی: " + (storage_ok ? "متصل" : "قطع"), clrLightGray, 8, false);
   }
   
   //--- Handle Mouse Move for Hover Effects
   bool CheckHover(int x, int y)
   {
      bool redraw = false;
      
      // Check bounds
      bool inside = (x >= DASHBOARD_X && x <= DASHBOARD_X + DASHBOARD_WIDTH &&
                     y >= DASHBOARD_Y && y <= DASHBOARD_Y + DASHBOARD_HEIGHT);
      
      if(inside != m_is_mouse_over)
      {
         m_is_mouse_over = inside;
         redraw = true;
      }
      
      // Button Hover Logic
      CheckButtonHover(m_btn_scan, x, y, redraw);
      CheckButtonHover(m_btn_clear, x, y, redraw);
      CheckButtonHover(m_btn_toggle_mode, x, y, redraw);
      
      return redraw;
   }
   
   //--- Handle Clicks
   bool ProcessClick(string clicked_obj)
   {
      if(clicked_obj == m_btn_scan) 
      {
         g_Logger->Info("Dashboard: Scan button clicked");
         return true;
      }
      if(clicked_obj == m_btn_clear) 
      {
         g_Logger->Info("Dashboard: Clear button clicked");
         return true;
      }
      if(clicked_obj == m_btn_toggle_mode) 
      {
         m_replace_mode = !m_replace_mode;
         SetReplaceMode(m_replace_mode);
         return true;
      }
      return false;
   }
   
   //--- Toggle Replace Mode Visuals
   void SetReplaceMode(bool active)
   {
      m_replace_mode = active;
      string text = active ? "حالت: جایگزینی" : "حالت: عادی";
      clr color = active ? COLOR_BTN_ACTIVE : COLOR_BTN_NORMAL;
      
      ObjectSetString(m_chart_id, m_btn_toggle_mode, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chart_id, m_btn_toggle_mode, OBJPROP_BGCOLOR, color);
   }
   
private:
   //--- Helper: Create Label
   bool CreateLabel(string name, int x, int y, string text, color clr, int font_size, bool bold)
   {
      if(ObjectFind(m_chart_id, name) < 0)
      {
         if(!ObjectCreate(m_chart_id, name, OBJ_TEXT, m_subwin, 0, 0)) return false;
         ObjectSetInteger(m_chart_id, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chart_id, name, OBJPROP_HIDDEN, true);
      }
      ObjectSetString(m_chart_id, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chart_id, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chart_id, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(m_chart_id, name, OBJPROP_FONT, FONT_NAME);
      ObjectSetInteger(m_chart_id, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(m_chart_id, name, OBJPROP_COLOR, color);
      if(bold) ObjectSetInteger(m_chart_id, name, OBJPROP_STYLE, STYLE_BOLD);
      else ObjectSetInteger(m_chart_id, name, OBJPROP_STYLE, STYLE_NORMAL);
      
      return true;
   }
   
   //--- Helper: Create Rectangle Background
   bool CreateRectLabel(string name, int x, int y, int w, int h, color bg_color, int corner, color border_color, int border_width)
   {
      if(ObjectFind(m_chart_id, name) < 0)
      {
         if(!ObjectCreate(m_chart_id, name, OBJ_RECTANGLE_LABEL, m_subwin, 0, 0)) return false;
         ObjectSetInteger(m_chart_id, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chart_id, name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(m_chart_id, name, OBJPROP_BACK, true); // Send to back
      }
      ObjectSetInteger(m_chart_id, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chart_id, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chart_id, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(m_chart_id, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(m_chart_id, name, OBJPROP_BGCOLOR, bg_color);
      ObjectSetInteger(m_chart_id, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(m_chart_id, name, OBJPROP_CORNER, corner);
      ObjectSetInteger(m_chart_id, name, OBJPROP_BORDER_COLOR, border_color);
      ObjectSetInteger(m_chart_id, name, OBJPROP_WIDTH, border_width);
      ObjectSetInteger(m_chart_id, name, OBJPROP_FILL, true);
      
      return true;
   }
   
   //--- Helper: Create Button
   bool CreateButton(string name, int x, int y, int w, int h, string text, color txt_color, color bg_color)
   {
      if(ObjectFind(m_chart_id, name) < 0)
      {
         if(!ObjectCreate(m_chart_id, name, OBJ_BUTTON, m_subwin, 0, 0)) return false;
         ObjectSetInteger(m_chart_id, name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(m_chart_id, name, OBJPROP_HIDDEN, true);
      }
      ObjectSetString(m_chart_id, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chart_id, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(m_chart_id, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(m_chart_id, name, OBJPROP_XSIZE, w);
      ObjectSetInteger(m_chart_id, name, OBJPROP_YSIZE, h);
      ObjectSetString(m_chart_id, name, OBJPROP_FONT, FONT_NAME);
      ObjectSetInteger(m_chart_id, name, OBJPROP_FONTSIZE, FONT_SIZE);
      ObjectSetInteger(m_chart_id, name, OBJPROP_COLOR, txt_color);
      ObjectSetInteger(m_chart_id, name, OBJPROP_BGCOLOR, bg_color);
      ObjectSetInteger(m_chart_id, name, OBJPROP_BORDER_COLOR, clrNONE);
      ObjectSetInteger(m_chart_id, name, OBJPROP_STATE, false);
      ObjectSetInteger(m_chart_id, name, OBJPROP_HIDDEN, true); // Hide from objects list
      
      return true;
   }
   
   //--- Check Hover for specific button
   void CheckButtonHover(string btn_name, int mx, int my, bool &redraw)
   {
      int x = (int)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_XDISTANCE);
      int y = (int)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_YDISTANCE);
      int w = (int)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_XSIZE);
      int h = (int)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_YSIZE);
      
      if(mx >= x && mx <= x + w && my >= y && my <= y + h)
      {
         // Hover state
         clr current = (clr)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_BGCOLOR);
         if(current != COLOR_BTN_HOVER && current != COLOR_BTN_ACTIVE) // Don't override active state
         {
            ObjectSetInteger(m_chart_id, btn_name, OBJPROP_BGCOLOR, COLOR_BTN_HOVER);
            redraw = true;
         }
      }
      else
      {
         // Normal state (restore based on type)
         clr original = COLOR_BTN_NORMAL;
         if(btn_name == m_btn_clear) original = COLOR_BTN_DELETE;
         if(btn_name == m_btn_toggle_mode) original = m_replace_mode ? COLOR_BTN_ACTIVE : COLOR_BTN_NORMAL;
         
         clr current = (clr)ObjectGetInteger(m_chart_id, btn_name, OBJPROP_BGCOLOR);
         if(current != original && current != COLOR_BTN_HOVER) // If not already active/hover
         {
             // Only revert if we aren't in active state logic (simplified here)
             if(btn_name != m_btn_toggle_mode || !m_replace_mode)
             {
                ObjectSetInteger(m_chart_id, btn_name, OBJPROP_BGCOLOR, original);
                redraw = true;
             }
         }
      }
   }
   
   //--- Delete All Objects
   void DeleteAll()
   {
      for(int i = ObjectsTotal(m_chart_id, m_subwin, -1) - 1; i >= 0; i--)
      {
         string name = ObjectName(m_chart_id, i, m_subwin, -1);
         if(StringFind(name, m_prefix) == 0)
         {
            ObjectDelete(m_chart_id, name);
         }
      }
   }
};
