//+------------------------------------------------------------------+
//|                                              PFP_GUI.mqh         |
//|                                  Copyright 2024, PitchforkPro    |
//|                                     https://github.com/pfp-pro   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, PitchforkPro"
#property link      "https://github.com/pfp-pro"
#property version   "1.0.0"
#property description "Professional GUI Manager for PitchforkPro"

#include "../Utils/PFP_Logger.mqh"
#include "../Utils/PFP_Constants.mqh"
#include "../Core/PFP_MultiManager.mqh"

//+------------------------------------------------------------------+
//| Enum: GUI Themes                                                 |
//+------------------------------------------------------------------+
enum ENUM_PFP_THEME
{
   THEME_DARK,    // تم تاریک (پیش‌فرض)
   THEME_LIGHT,   // تم روشن
   THEME_BLUE     // تم آبی حرفه‌ای
};

//+------------------------------------------------------------------+
//| Class: PFP_GUI                                                   |
//| Description: مدیریت کامل رابط کاربری گرافیکی                     |
//+------------------------------------------------------------------+
class PFP_GUI
{
private:
   // --- تنظیمات کلی ---
   string          m_prefix;           // پیشوند نام اشیاء گرافیکی
   int             m_panel_id;         // شناسه یکتا پنل
   bool            m_is_visible;       // وضعیت نمایش پنل
   int             m_pos_x;            // موقعیت افقی
   int             m_pos_y;            // موقعیت عمودی
   int             m_width;            // عرض پنل
   int             m_height;           // ارتفاع پنل
   ENUM_PFP_THEME  m_current_theme;    // تم فعلی
   
   // --- اشیاء گرافیکی ---
   color           m_bg_color;         // رنگ پس‌زمینه
   color           m_border_color;     // رنگ حاشیه
   color           m_text_color;       // رنگ متن
   color           m_header_color;     // رنگ هدر
   color           m_btn_normal;       // رنگ دکمه عادی
   color           m_btn_hover;        // رنگ دکمه هنگام موس
   color           m_btn_active;       // رنگ دکمه فعال
   
   // --- مدیریت لیست Pitchforkها ---
   int             m_list_start_y;     // شروع لیست آیتم‌ها
   int             m_item_height;      // ارتفاع هر آیتم
   int             m_max_visible_items;// حداکثر آیتم‌های قابل نمایش
   int             m_scroll_offset;    // اسکرول عمودی
   bool            m_is_scrolling;     // وضعیت اسکرول
   
   // --- ارجاع به مدیر اصلی ---
   CPFP_MultiManager *m_manager;       // اشاره‌گر به مدیر چندگانه
   
   // --- کش اشیاء ---
   string m_gui_objects[]; // ذخیره نام اشیاء برای مدیریت سریع

   // --- متدهای داخلی ترسیم ---
   bool CreateBackground();
   bool CreateHeader();
   bool CreateControls();
   bool CreateListContainer();
   bool UpdateItemList();
   
   // --- مدیریت رویدادهای موس ---
   bool HandleMouseClick(string object_name);
   bool HandleMouseMove(int x, int y);
   void OnScroll(int delta);
   
   // --- توابع کمکی ---
   void ApplyTheme(ENUM_PFP_THEME theme);
   string GetObjectName(string base);
   void DeleteAllObjects();
   string FormatTime(datetime time);
   color GetStatusColor(int status);
   void RegisterObject(string name);

public:
   // --- سازنده و ویرانگر ---
   PFP_GUI(CPFP_MultiManager *manager);
   ~PFP_GUI();
   
   // --- روش‌های عمومی ---
   bool Initialize();
   void Show();
   void Hide();
   void Toggle();
   bool IsVisible() const { return m_is_visible; }
   
   // --- به‌روزرسانی ---
   void Refresh();
   void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   
   // --- تنظیمات ---
   void SetPosition(int x, int y);
   void SetTheme(ENUM_PFP_THEME theme);
   void SetManager(CPFP_MultiManager *manager);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
PFP_GUI::PFP_GUI(CPFP_MultiManager *manager)
{
   m_manager = manager;
   m_prefix = "PFP_GUI_";
   m_panel_id = (int)TimeCurrent();
   m_is_visible = false;
   
   // موقعیت پیش‌فرض (گوشه بالا راست)
   m_pos_x = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS) - 320;
   m_pos_y = 50;
   m_width = 300;
   m_height = 400;
   
   m_current_theme = THEME_DARK;
   m_item_height = 30;
   m_max_visible_items = 10;
   m_scroll_offset = 0;
   m_is_scrolling = false;
   
   Print("GUI: Constructor initialized");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
PFP_GUI::~PFP_GUI()
{
   DeleteAllObjects();
   Print("GUI: Destructor called, objects cleaned up");
}

//+------------------------------------------------------------------+
//| Initialize GUI                                                   |
//+------------------------------------------------------------------+
bool PFP_GUI::Initialize()
{
   if(!IsStopped())
   {
      ApplyTheme(m_current_theme);
      
      if(!CreateBackground()) return false;
      if(!CreateHeader()) return false;
      if(!CreateControls()) return false;
      if(!CreateListContainer()) return false;
      
      m_is_visible = true;
      Print("GUI: Initialization successful");
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Apply Theme Colors                                               |
//+------------------------------------------------------------------+
void PFP_GUI::ApplyTheme(ENUM_PFP_THEME theme)
{
   switch(theme)
   {
      case THEME_DARK:
         m_bg_color = C'30,30,30';
         m_border_color = C'50,50,50';
         m_text_color = C'220,220,220';
         m_header_color = C'40,40,40';
         m_btn_normal = C'60,60,60';
         m_btn_hover = C'80,80,80';
         m_btn_active = C'0,120,215';
         break;
         
      case THEME_LIGHT:
         m_bg_color = C'240,240,240';
         m_border_color = C'200,200,200';
         m_text_color = C'30,30,30';
         m_header_color = C'220,220,220';
         m_btn_normal = C'200,200,200';
         m_btn_hover = C'220,220,220';
         m_btn_active = C'0,100,200';
         break;
         
      case THEME_BLUE:
         m_bg_color = C'15,25,45';
         m_border_color = C'30,50,80';
         m_text_color = C'200,220,255';
         m_header_color = C'20,40,70';
         m_btn_normal = C'30,50,90';
         m_btn_hover = C'40,60,100';
         m_btn_active = C'0,150,255';
         break;
   }
   
   m_current_theme = theme;
   Print("GUI: Theme applied: " + EnumToString(theme));
}

//+------------------------------------------------------------------+
//| Create Background Panel                                          |
//+------------------------------------------------------------------+
bool PFP_GUI::CreateBackground()
{
   string name = GetObjectName("BG");
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_pos_x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_pos_y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, m_width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, m_height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_bg_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_COLOR, m_border_color);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      
      RegisterObject(name);
      return true;
   }
   Print("GUI: Failed to create background: " + name);
   return false;
}

//+------------------------------------------------------------------+
//| Create Header Section                                            |
//+------------------------------------------------------------------+
bool PFP_GUI::CreateHeader()
{
   string name = GetObjectName("HEADER_BG");
   if(ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_pos_x + 1);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_pos_y + 1);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, m_width - 2);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, 35);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_header_color);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      RegisterObject(name);
   }
   
   // عنوان
   string titleName = GetObjectName("TITLE");
   if(ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, m_pos_x + 10);
      ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, m_pos_y + 10);
      ObjectSetInteger(0, titleName, OBJPROP_COLOR, m_text_color);
      ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, titleName, OBJPROP_TEXT, "PitchforkPro Manager");
      ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, titleName, OBJPROP_HIDDEN, true);
      RegisterObject(titleName);
   }
   
   // دکمه بستن
   string closeBtn = GetObjectName("BTN_CLOSE");
   if(ObjectCreate(0, closeBtn, OBJ_BUTTON, 0, 0, 0))
   {
      ObjectSetInteger(0, closeBtn, OBJPROP_XDISTANCE, m_pos_x + m_width - 30);
      ObjectSetInteger(0, closeBtn, OBJPROP_YDISTANCE, m_pos_y + 5);
      ObjectSetInteger(0, closeBtn, OBJPROP_XSIZE, 20);
      ObjectSetInteger(0, closeBtn, OBJPROP_YSIZE, 20);
      ObjectSetInteger(0, closeBtn, OBJPROP_BGCOLOR, m_btn_normal);
      ObjectSetInteger(0, closeBtn, OBJPROP_COLOR, m_text_color);
      ObjectSetString(0, closeBtn, OBJPROP_TEXT, "X");
      ObjectSetString(0, closeBtn, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, closeBtn, OBJPROP_FONTSIZE, 8);
      RegisterObject(closeBtn);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create Control Buttons                                           |
//+------------------------------------------------------------------+
bool PFP_GUI::CreateControls()
{
   int btnY = m_pos_y + 45;
   int btnW = (m_width - 20) / 2;
   
   // دکمه اسکن مجدد
   string scanBtn = GetObjectName("BTN_SCAN");
   if(ObjectCreate(0, scanBtn, OBJ_BUTTON, 0, 0, 0))
   {
      ObjectSetInteger(0, scanBtn, OBJPROP_XDISTANCE, m_pos_x + 10);
      ObjectSetInteger(0, scanBtn, OBJPROP_YDISTANCE, btnY);
      ObjectSetInteger(0, scanBtn, OBJPROP_XSIZE, btnW);
      ObjectSetInteger(0, scanBtn, OBJPROP_YSIZE, 25);
      ObjectSetInteger(0, scanBtn, OBJPROP_BGCOLOR, m_btn_normal);
      ObjectSetInteger(0, scanBtn, OBJPROP_COLOR, m_text_color);
      ObjectSetString(0, scanBtn, OBJPROP_TEXT, "Scan Chart");
      ObjectSetString(0, scanBtn, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, scanBtn, OBJPROP_FONTSIZE, 8);
      RegisterObject(scanBtn);
   }
   
   // دکمه جایگزینی
   string replaceBtn = GetObjectName("BTN_REPLACE");
   if(ObjectCreate(0, replaceBtn, OBJ_BUTTON, 0, 0, 0))
   {
      ObjectSetInteger(0, replaceBtn, OBJPROP_XDISTANCE, m_pos_x + 15 + btnW);
      ObjectSetInteger(0, replaceBtn, OBJPROP_YDISTANCE, btnY);
      ObjectSetInteger(0, replaceBtn, OBJPROP_XSIZE, btnW);
      ObjectSetInteger(0, replaceBtn, OBJPROP_YSIZE, 25);
      ObjectSetInteger(0, replaceBtn, OBJPROP_BGCOLOR, m_btn_active);
      ObjectSetInteger(0, replaceBtn, OBJPROP_COLOR, clrWhite);
      ObjectSetString(0, replaceBtn, OBJPROP_TEXT, "Replace All");
      ObjectSetString(0, replaceBtn, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, replaceBtn, OBJPROP_FONTSIZE, 8);
      RegisterObject(replaceBtn);
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create List Container                                            |
//+------------------------------------------------------------------+
bool PFP_GUI::CreateListContainer()
{
   m_list_start_y = m_pos_y + 80;
   int listHeight = m_height - 90;
   
   string listBg = GetObjectName("LIST_BG");
   if(ObjectCreate(0, listBg, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, listBg, OBJPROP_XDISTANCE, m_pos_x + 5);
      ObjectSetInteger(0, listBg, OBJPROP_YDISTANCE, m_list_start_y);
      ObjectSetInteger(0, listBg, OBJPROP_XSIZE, m_width - 10);
      ObjectSetInteger(0, listBg, OBJPROP_YSIZE, listHeight);
      ObjectSetInteger(0, listBg, OBJPROP_BGCOLOR, C'20,20,20');
      ObjectSetInteger(0, listBg, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
      ObjectSetInteger(0, listBg, OBJPROP_COLOR, m_border_color);
      ObjectSetInteger(0, listBg, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, listBg, OBJPROP_BACK, true);
      ObjectSetInteger(0, listBg, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, listBg, OBJPROP_HIDDEN, true);
      RegisterObject(listBg);
   }
   
   // اسکرول بار ساده
   string scrollBar = GetObjectName("SCROLLBAR");
   if(ObjectCreate(0, scrollBar, OBJ_RECTANGLE_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, scrollBar, OBJPROP_XDISTANCE, m_pos_x + m_width - 10);
      ObjectSetInteger(0, scrollBar, OBJPROP_YDISTANCE, m_list_start_y);
      ObjectSetInteger(0, scrollBar, OBJPROP_XSIZE, 5);
      ObjectSetInteger(0, scrollBar, OBJPROP_YSIZE, listHeight);
      ObjectSetInteger(0, scrollBar, OBJPROP_BGCOLOR, C'40,40,40');
      ObjectSetInteger(0, scrollBar, OBJPROP_BACK, true);
      ObjectSetInteger(0, scrollBar, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, scrollBar, OBJPROP_HIDDEN, true);
      RegisterObject(scrollBar);
   }
   
   UpdateItemList();
   return true;
}

//+------------------------------------------------------------------+
//| Update Item List (Dynamic)                                       |
//+------------------------------------------------------------------+
bool PFP_GUI::UpdateItemList()
{
   // پاک کردن آیتم‌های قبلی لیست
   for(int i = 0; i < 100; i++) // فرض بر حداکثر 100 آیتم
   {
      string itemName = GetObjectName("ITEM_" + IntegerToString(i));
      string labelName = GetObjectName("LABEL_" + IntegerToString(i));
      if(ObjectFind(0, itemName) >= 0) ObjectDelete(0, itemName);
      if(ObjectFind(0, labelName) >= 0) ObjectDelete(0, labelName);
   }
   
   if(m_manager == NULL) return false;
   
   int count = m_manager.TotalPitchforks();
   if(count == 0)
   {
      // نمایش پیام خالی بودن
      string emptyLabel = GetObjectName("EMPTY_MSG");
      if(ObjectCreate(0, emptyLabel, OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, emptyLabel, OBJPROP_XDISTANCE, m_pos_x + m_width/2 - 50);
         ObjectSetInteger(0, emptyLabel, OBJPROP_YDISTANCE, m_list_start_y + 20);
         ObjectSetInteger(0, emptyLabel, OBJPROP_COLOR, C'100,100,100');
         ObjectSetString(0, emptyLabel, OBJPROP_TEXT, "No Pitchforks Found");
         ObjectSetString(0, emptyLabel, OBJPROP_FONT, "Arial Italic");
         ObjectSetInteger(0, emptyLabel, OBJPROP_FONTSIZE, 9);
         RegisterObject(emptyLabel);
      }
      return true;
   }
   
   // رسم آیتم‌ها
   for(int i = 0; i < MathMin(count, m_max_visible_items); i++)
   {
      // TODO: دریافت اطلاعات از Manager
      // اینجا باید از Manager اطلاعات Pitchfork شماره i را بگیریم
      
      int yPos = m_list_start_y + (i * m_item_height) + 5;
      
      // پس‌زمینه آیتم
      string itemRect = GetObjectName("ITEM_" + IntegerToString(i));
      if(ObjectCreate(0, itemRect, OBJ_RECTANGLE_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, itemRect, OBJPROP_XDISTANCE, m_pos_x + 7);
         ObjectSetInteger(0, itemRect, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, itemRect, OBJPROP_XSIZE, m_width - 22);
         ObjectSetInteger(0, itemRect, OBJPROP_YSIZE, m_item_height - 2);
         ObjectSetInteger(0, itemRect, OBJPROP_BGCOLOR, (i % 2 == 0) ? C'35,35,35' : C'30,30,30');
         ObjectSetInteger(0, itemRect, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(0, itemRect, OBJPROP_COLOR, C'60,60,60');
         ObjectSetInteger(0, itemRect, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, itemRect, OBJPROP_BACK, true);
         ObjectSetInteger(0, itemRect, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, itemRect, OBJPROP_HIDDEN, true);
         RegisterObject(itemRect);
      }
      
      // متن آیتم (شماره و نوع)
      string itemLabel = GetObjectName("LABEL_" + IntegerToString(i));
      if(ObjectCreate(0, itemLabel, OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, itemLabel, OBJPROP_XDISTANCE, m_pos_x + 15);
         ObjectSetInteger(0, itemLabel, OBJPROP_YDISTANCE, yPos + 8);
         ObjectSetInteger(0, itemLabel, OBJPROP_COLOR, m_text_color);
         ObjectSetString(0, itemLabel, OBJPROP_TEXT, "PF #" + IntegerToString(i+1) + " - Standard");
         ObjectSetString(0, itemLabel, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, itemLabel, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, itemLabel, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, itemLabel, OBJPROP_HIDDEN, true);
         RegisterObject(itemLabel);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Show GUI                                                         |
//+------------------------------------------------------------------+
void PFP_GUI::Show()
{
   if(!m_is_visible)
   {
      Initialize();
      m_is_visible = true;
      Print("GUI: Panel shown");
   }
}

//+------------------------------------------------------------------+
//| Hide GUI                                                         |
//+------------------------------------------------------------------+
void PFP_GUI::Hide()
{
   if(m_is_visible)
   {
      DeleteAllObjects();
      m_is_visible = false;
      Print("GUI: Panel hidden");
   }
}

//+------------------------------------------------------------------+
//| Toggle Visibility                                                |
//+------------------------------------------------------------------+
void PFP_GUI::Toggle()
{
   if(m_is_visible) Hide();
   else Show();
}

//+------------------------------------------------------------------+
//| Handle Chart Events                                              |
//+------------------------------------------------------------------+
void PFP_GUI::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam, m_prefix) == 0)
      {
         if(sparam == GetObjectName("BTN_CLOSE"))
         {
            Hide();
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         }
         else if(sparam == GetObjectName("BTN_SCAN"))
         {
            if(m_manager != NULL) m_manager.ScanAndStoreAll();
            Refresh();
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         }
         else if(sparam == GetObjectName("BTN_REPLACE"))
         {
            if(m_manager != NULL) m_manager.ReplaceAllPitchforks();
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         }
         // مدیریت کلیک روی آیتم‌های لیست
         else if(StringFind(sparam, GetObjectName("ITEM_")) == 0)
         {
            // استخراج ایندکس و انتخاب Pitchfork مربوطه
            // TODO: پیاده‌سازی منطق انتخاب
            Print("GUI: Item clicked: " + sparam);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         }
      }
   }
   else if(id == CHARTEVENT_MOUSE_MOVE)
   {
      // مدیریت درگ کردن پنل یا اسکرول
      // TODO: پیاده‌سازی درگ و دراپ
   }
}

//+------------------------------------------------------------------+
//| Refresh GUI Data                                                 |
//+------------------------------------------------------------------+
void PFP_GUI::Refresh()
{
   if(m_is_visible)
   {
      UpdateItemList();
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| Helper: Generate Object Name                                     |
//+------------------------------------------------------------------+
string PFP_GUI::GetObjectName(string base)
{
   return m_prefix + IntegerToString(m_panel_id) + "_" + base;
}

//+------------------------------------------------------------------+
//| Helper: Register Object Name                                     |
//+------------------------------------------------------------------+
void PFP_GUI::RegisterObject(string name)
{
   int size = ArraySize(m_gui_objects);
   ArrayResize(m_gui_objects, size + 1);
   m_gui_objects[size] = name;
}

//+------------------------------------------------------------------+
//| Helper: Delete All Objects                                       |
//+------------------------------------------------------------------+
void PFP_GUI::DeleteAllObjects()
{
   for(int i = ArraySize(m_gui_objects) - 1; i >= 0; i--)
   {
      if(m_gui_objects[i] != "")
         ObjectDelete(0, m_gui_objects[i]);
   }
   ArrayResize(m_gui_objects, 0);
}

//+------------------------------------------------------------------+
//| Internal Mouse Click Handler                                     |
//+------------------------------------------------------------------+
bool PFP_GUI::HandleMouseClick(string object_name)
{
   return (StringFind(object_name, m_prefix) == 0);
}

//+------------------------------------------------------------------+
//| Internal Mouse Move Handler                                      |
//+------------------------------------------------------------------+
bool PFP_GUI::HandleMouseMove(int x, int y)
{
   return false;
}

//+------------------------------------------------------------------+
//| Internal Scroll Handler                                          |
//+------------------------------------------------------------------+
void PFP_GUI::OnScroll(int delta)
{
   m_scroll_offset += delta;
   if(m_scroll_offset < 0)
      m_scroll_offset = 0;
}

//+------------------------------------------------------------------+
//| Helper: Format Time                                              |
//+------------------------------------------------------------------+
string PFP_GUI::FormatTime(datetime time)
{
   return TimeToString(time, TIME_DATE | TIME_MINUTES);
}

//+------------------------------------------------------------------+
//| Helper: Status Color                                             |
//+------------------------------------------------------------------+
color PFP_GUI::GetStatusColor(int status)
{
   if(status > 0)
      return clrLime;
   if(status < 0)
      return clrRed;
   return clrGray;
}

//+------------------------------------------------------------------+
//| Set Position                                                     |
//+------------------------------------------------------------------+
void PFP_GUI::SetPosition(int x, int y)
{
   m_pos_x = x;
   m_pos_y = y;
   if(m_is_visible)
   {
      Hide();
      Show();
   }
}

//+------------------------------------------------------------------+
//| Set Theme                                                        |
//+------------------------------------------------------------------+
void PFP_GUI::SetTheme(ENUM_PFP_THEME theme)
{
   m_current_theme = theme;
   if(m_is_visible)
   {
      Hide();
      Show();
   }
}

//+------------------------------------------------------------------+
//| Set Manager Reference                                            |
//+------------------------------------------------------------------+
void PFP_GUI::SetManager(CPFP_MultiManager *manager)
{
   m_manager = manager;
   if(m_is_visible) Refresh();
}
//+------------------------------------------------------------------+
