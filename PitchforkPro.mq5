//+------------------------------------------------------------------+
//|                     PitchforkPro.mq5                              |
//|                        نسخه 1.0.1 Fixed                           |
//+------------------------------------------------------------------+

#property indicator_chart_window
#property strict
#property indicator_plots 0
#property version   "1.000"
#property description "اندیکاتور پیشرفته چنگال اندروز با قابلیت ذخیره‌سازی، جایگزینی و تشخیص هوشمند - نسخه اصلاح شده 1.0.1"


#include "Utils/PFP_Constants.mqh"
#include "Utils/PFP_Logger.mqh"

#include "Core/PFP_Pitchfork.mqh"
#include "Core/PFP_ObjectManager.mqh"
#include "Core/PFP_GeometryData.mqh"
#include "Core/PFP_GeometryEngine.mqh"
#include "Core/PFP_ObjectScanner.mqh"
#include "Core/PFP_PitchforkReader.mqh"
#include "Core/PFP_Renderer.mqh"
#include "Core/PFP_MultiStorage.mqh"
#include "Core/PFP_ReplaceEngine.mqh"
#include "Core/PFP_MultiManager.mqh"
#include "Core/PFP_TypeDetector.mqh"
// #include "Core/PFP_Dashboard.mqh"  // حذف شد - فقط از GUI استفاده می‌کنیم

#include "Utils/PFP_GUI.mqh"


//--- ورودی‌های کاربر
input group "تنظیمات کلیدی"
input bool   Inp_EnableScanner    = true;           // فعال‌سازی اسکنر خودکار
input string Inp_ScanKey          = "S";            // کلید اسکن و ذخیره (پیش‌فرض: S)
input string Inp_ReplaceKey       = "R";            // کلید جایگزینی (پیش‌فرض: R)
input string Inp_GUIKey           = "G";            // کلید نمایش/مخفی کردن پنل GUI (پیش‌فرض: G)

input group "تنظیمات ظاهری"
input color  Inp_ColorMain        = clrDodgerBlue;  // رنگ خطوط اصلی
input color  Inp_ColorMedian      = clrYellow;      // رنگ خط میانی
input color  Inp_ColorWarning     = clrOrangeRed;   // رنگ خطوط اخطار/کمکی
input int    Inp_WidthMain        = 2;              // ضخامت خطوط اصلی
input int    Inp_WidthMedian      = 1;              // ضخامت خط میانی
input ENUM_PFP_THEME Inp_GUITheme = THEME_DARK;     // تم رابط کاربری گرافیکی

input group "تنظیمات سیستم"
input bool   Inp_ShowLogs         = true;           // نمایش لاگ‌ها در کنسول
input bool   Inp_DeepDebug        = false;          // حالت دیباگ عمیق (توصیه نمی‌شود)


//--- متغیرهای سراسری
CPFP_Logger        *g_Logger = NULL;
CPFP_MultiManager  *g_Manager = NULL;
CPFP_ObjectManager *g_ObjectMgr = NULL;
CPFP_TypeDetector  *g_TypeDetector = NULL;
CPFP_Renderer      *g_Renderer = NULL;
CPFP_GeometryEngine *g_Geometry = NULL;
CPFP_GUI           *g_GUI = NULL;          // مدیر رابط کاربری گرافیکی
// CPFP_Dashboard     *g_Dashboard = NULL;    // داشبورد حرفه‌ای - حذف شد، فقط از GUI استفاده می‌کنیم

// تعریف برای دسترسی در فایل‌های دیگر (extern) - حذف شد
// MultiManager دیگر به g_Dashboard نیاز ندارد

//--- وضعیت‌های سیستم
bool g_IsProcessing = false;          // قفل پردازش برای جلوگیری از تداخل
datetime g_LastBarTime = 0;           // زمان آخرین کندل پردازش شده
string g_SelectedPitchforkID = "";    // شناسه پیچ‌فورک انتخاب شده توسط کاربر

//--- Event Queue برای مدیریت رویدادها
struct SPFP_Event
{
   int type;
   long lparam;
   double dparam;
   string sparam;
   datetime timestamp;
};

SPFP_Event g_EventQueue[100];
int g_EventQueueSize = 0;


//+------------------------------------------------------------------+
//| INIT                                                              |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- ایجاد نمونه لاگر
   ENUM_PFP_LOG_LEVEL logLevel = Inp_DeepDebug ? LOG_LEVEL_DEBUG : LOG_LEVEL_INFO;
   g_Logger = new CPFP_Logger("PitchforkPro", Inp_ShowLogs, logLevel);
   
   if(g_Logger == NULL)
   {
      Print("خطای بحرانی: عدم امکان ایجاد Logger");
      return INIT_FAILED;
   }
   
   g_Logger.Info("شروع راه‌اندازی PitchforkPro v1.0.1 Fixed");

   //--- بررسی دسترسی به چارت
   if(!ChartGetInteger(0, CHART_MODE))
   {
      g_Logger.Error("خطا در دسترسی به چارت");
      delete g_Logger;
      return INIT_FAILED;
   }

   //--- ایجاد تشخیص‌دهنده نوع (TypeDetector)
   g_TypeDetector = new CPFP_TypeDetector();
   if(g_TypeDetector == NULL)
   {
      g_Logger.Error("خطا در ایجاد TypeDetector");
      delete g_Logger;
      return INIT_FAILED;
   }

   //--- ایجاد مدیر چندگانه (MultiManager)
   g_Manager = new CPFP_MultiManager(g_Logger, g_TypeDetector);
   if(g_Manager == NULL)
   {
      g_Logger.Error("خطا در ایجاد MultiManager");
      delete g_TypeDetector;
      delete g_Logger;
      return INIT_FAILED;
   }
   
   //--- ایجاد Renderer و Geometry
   g_Renderer = new CPFP_Renderer();
   g_Geometry = new CPFP_GeometryEngine();
   
   if(g_Renderer == NULL || g_Geometry == NULL)
   {
      g_Logger.Error("خطا در ایجاد Renderer یا Geometry");
      delete g_Manager;
      delete g_TypeDetector;
      delete g_Logger;
      return INIT_FAILED;
   }
   
   //--- تنظیم Engines در Manager و ObjectManager
   g_Manager.SetEngines(g_Renderer, g_Geometry);

   //--- ایجاد مدیر اشیاء (ObjectManager)
   g_ObjectMgr = new CPFP_ObjectManager(g_Logger, g_Manager);
   if(g_ObjectMgr == NULL)
   {
      g_Logger.Error("خطا در ایجاد ObjectManager");
      delete g_Manager;
      delete g_TypeDetector;
      delete g_Logger;
      return INIT_FAILED;
   }
   
   g_ObjectMgr.SetEngines(g_Renderer, g_Geometry);
   
   //--- تنظیم ObjectManager در MultiManager
   g_Manager.SetObjectManager(g_ObjectMgr);

   //--- ایجاد رابط کاربری گرافیکی (GUI)
   g_GUI = new CPFP_GUI(ChartID(), g_Logger);
   if(g_GUI == NULL)
   {
      g_Logger.Error("خطا در ایجاد GUI");
      delete g_Manager;
      delete g_ObjectMgr;
      delete g_Renderer;
      delete g_Geometry;
      delete g_TypeDetector;
      delete g_Logger;
      return INIT_FAILED;
   }
   
   //--- راه‌اندازی اولیه GUI
   if(!g_GUI.Initialize())
   {
      g_Logger.Error("خطا در راه‌اندازی GUI");
      delete g_GUI;
      delete g_Manager;
      delete g_ObjectMgr;
      delete g_Renderer;
      delete g_Geometry;
      delete g_TypeDetector;
      delete g_Logger;
      return INIT_FAILED;
   }
   else
   {
      g_Logger.Info("رابط کاربری گرافیکی با موفقیت راه‌اندازی شد.");
   }

   //--- ایجاد داشبورد حرفه‌ای - حذف شد چون از GUI استفاده می‌کنیم
   // تمام قابلیت‌ها در یک پنل GUI متمرکز شده‌اند
   // g_Dashboard = NULL;  // دیگر نیازی به داشبورد جداگانه نیست

   //--- بارگذاری داده‌های ذخیره شده
   if(!g_Manager.LoadAll())
   {
      g_Logger.Warning("بارگذاری داده‌های قبلی با مشکل مواجه شد یا فایلی وجود ندارد.");
   }
   else
   {
      g_Logger.Info("داده‌های ذخیره شده با موفقیت بارگذاری شدند.");
   }

   //--- تنظیم تایمر برای بررسی دوره‌ای
   EventSetTimer(1); // بررسی هر 1 ثانیه

   g_Logger.Info("راه‌اندازی با موفقیت انجام شد.");
   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//| DEINIT                                                            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_Logger != NULL)
      g_Logger.Info("خاموش کردن اندیکاتور. دلیل: " + IntegerToString(reason));
   
   //--- مخفی کردن و پاکسازی داشبورد - دیگر استفاده نمی‌شود
   // اگر در آینده نیاز بود، دوباره فعال شود
   // if(g_Dashboard != NULL)
   // {
   //    delete g_Dashboard;
   // }
   
   //--- مخفی کردن و پاکسازی GUI
   if(g_GUI != NULL)
   {
      g_GUI.Deinitialize();
      delete g_GUI;
   }
   
   //--- ذخیره داده‌ها قبل از خروج
   if(g_Manager != NULL)
   {
      g_Manager.SaveAll();
      delete g_Manager;
   }
   
   if(g_ObjectMgr != NULL)
      delete g_ObjectMgr;
      
   if(g_Renderer != NULL)
      delete g_Renderer;
      
   if(g_Geometry != NULL)
      delete g_Geometry;
      
   if(g_TypeDetector != NULL)
      delete g_TypeDetector;
      
   if(g_Logger != NULL)
      delete g_Logger;

   EventKillTimer();
   Comment(""); // پاک کردن متن روی چارت
}


//+------------------------------------------------------------------+
//| CALCULATE                                                         |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- اگر در حال پردازش هستیم، محاسبه جدید را نادیده بگیر
   if(g_IsProcessing) return prev_calculated;
   
   //--- اگر داده‌های کافی نداریم
   if(rates_total < 3) return 0;

   //--- بررسی تغییر کندل جدید
   datetime currentBarTime = time[rates_total - 1];
   if(currentBarTime == g_LastBarTime && prev_calculated > 0)
   {
      return prev_calculated;
   }
   
   g_LastBarTime = currentBarTime;
   g_IsProcessing = true;

   //--- رسم مجدد تمام پیچ‌فورک‌های فعال (فقط اگر Geometry تغییر کرده باشد)
   if(g_Manager != NULL)
   {
      g_Manager.RenderAllActive();
   }
   
   //--- بروزرسانی داشبورد - حذف شد (از GUI استفاده می‌کنیم)
   // if(g_Dashboard != NULL && g_Manager != NULL)
   // {
   //    int count = g_Manager.GetCount();
   //    bool storage_ok = true;
   //    g_Dashboard.Update(count, storage_ok);
   // }

   //--- پردازش رویدادهای صف
   ProcessEventQueue();
   
   g_IsProcessing = false;
   return rates_total;
}


//+------------------------------------------------------------------+
//| EVENTS                                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- پردازش رویدادهای داشبورد - حذف شد (از GUI استفاده می‌کنیم)
   // تمام رویدادها توسط GUI پردازش می‌شوند
   /*
   if(g_Dashboard != NULL && id == CHARTEVENT_MOUSE_MOVE)
   {
      int x = (int)lparam;
      int y = (int)dparam;
      if(g_Dashboard.CheckHover(x, y))
      {
         ChartRedraw();
      }
   }
   
   if(g_Dashboard != NULL && id == CHARTEVENT_OBJECT_CLICK)
   {
      string objName = sparam;
      if(StringFind(objName, "PFP_Dash_") >= 0)
      {
         if(g_Dashboard.ProcessClick(objName))
         {
            if(StringFind(objName, "BtnScan") >= 0)
            {
               g_Logger.Info("دستور اسکن از داشبورد دریافت شد");
               HandleScanCommand();
            }
            else if(StringFind(objName, "BtnClear") >= 0)
            {
               g_Logger.Info("دستور حذف همه از داشبورد دریافت شد");
               if(g_Manager != NULL)
               {
                  g_Manager.RemoveAll();
                  g_SelectedPitchforkID = "";
                  Comment("");
               }
            }
            ChartRedraw();
         }
      }
   }
   */
   
   //--- ارسال رویداد به GUI برای پردازش
   if(g_GUI != NULL)
   {
      g_GUI.OnChartEvent(id, lparam, sparam);
   }
   
   //--- افزودن رویداد به صف برای پردازش ناهمگام
   if(g_EventQueueSize < 100)
   {
      g_EventQueue[g_EventQueueSize].type = id;
      g_EventQueue[g_EventQueueSize].lparam = lparam;
      g_EventQueue[g_EventQueueSize].dparam = dparam;
      g_EventQueue[g_EventQueueSize].sparam = sparam;
      g_EventQueue[g_EventQueueSize].timestamp = TimeCurrent();
      g_EventQueueSize++;
   }
   
   //--- پردازش فوری برخی رویدادهای کلیدی
   if(id == CHARTEVENT_KEYDOWN)
   {
      string key = StringSubstr(sparam, 0, 1);
      
      //--- کلید نمایش/مخفی کردن GUI (G)
      string guiKey = Inp_GUIKey;
      StringToUpper(key);
      StringToUpper(guiKey);
      if(key == guiKey)
      {
         g_Logger.Info("دستور نمایش/مخفی کردن GUI دریافت شد (کلید: " + Inp_GUIKey + ")");
         if(g_GUI != NULL)
         {
            g_GUI.TogglePanel();
         }
      }
      
      //--- کلید اسکن (S)
      string scanKey = Inp_ScanKey;
      StringToUpper(key);
      StringToUpper(scanKey);
      if(key == scanKey)
      {
         g_Logger.Info("دستور اسکن دریافت شد (کلید: " + Inp_ScanKey + ")");
         HandleScanCommand();
      }
      
      //--- کلید جایگزینی (R)
      string replaceKey = Inp_ReplaceKey;
      StringToUpper(key);
      StringToUpper(replaceKey);
      if(key == replaceKey)
      {
         g_Logger.Info("دستور جایگزینی دریافت شد (کلید: " + Inp_ReplaceKey + ")");
         HandleReplaceCommand();
      }
      
      //--- کلید حذف (D یا Delete)
      if(key == "D" || key == "DELETE") 
      {
         if(StringLen(g_SelectedPitchforkID) > 0)
         {
            g_Logger.Info("حذف پیچ‌فورک انتخاب شده: " + g_SelectedPitchforkID);
            g_Manager.RemovePitchfork(g_SelectedPitchforkID);
            g_SelectedPitchforkID = "";
            Comment("");
         }
      }
   }
   
   //--- رویداد کلیک ماوس (برای انتخاب پیچ‌فورک)
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      string objName = sparam;
      if(StringFind(objName, "PFP_") >= 0)
      {
         if(ExtractIDFromObjectName(objName, g_SelectedPitchforkID))
         {
            g_Logger.Debug("پیچ‌فورک انتخاب شد: " + g_SelectedPitchforkID);
            Comment("پیچ‌فورک فعال: " + g_SelectedPitchforkID + "\nبرای حذف کلید D را بزنید.");
         }
      }
   }
   
   //--- رویداد تغییر شیء (جابجایی نقاط توسط کاربر)
   if(id == CHARTEVENT_OBJECT_CHANGE)
   {
      string objName = sparam;
      if(StringFind(objName, "PFP_") >= 0)
      {
         string pfID = "";
         if(ExtractIDFromObjectName(objName, pfID))
         {
            g_Logger.Debug("تغییر دستی detected در: " + pfID);
            // Update coordinates logic would go here
         }
      }
   }
}

//+------------------------------------------------------------------+
//| پردازش صف رویدادها                                               |
//+------------------------------------------------------------------+
void ProcessEventQueue()
{
   if(g_EventQueueSize == 0) return;
   
   for(int i = 0; i < g_EventQueueSize; i++)
   {
      //--- پردازش رویدادهای سفارشی از GUI
      if(g_EventQueue[i].type == CHARTEVENT_CUSTOM)
      {
         int eventType = (int)g_EventQueue[i].lparam;
         
         // Toggle Color Event
         if(eventType == PFP_EVENT_TOGGLE_COLOR)
         {
            g_Logger.Info("Toggle fork color requested");
            // Toggle logic: switch between bullish (dark green) and bearish (red)
            if(g_Manager != NULL && g_Manager.GetCount() > 0)
            {
               // Get the last pitchfork (most recently added)
               int lastIndex = g_Manager.GetCount() - 1;
               CPFP_Pitchfork pf;
               if(g_Manager.Get(lastIndex, pf))
               {
                  color currentColor = pf.GetColor();
                  // Toggle between bull (dark green) and bear (red)
                  if(currentColor == PFP_COLOR_BULL)
                  {
                     pf.SetColor(PFP_COLOR_BEAR);
                     g_Logger.Info("Fork color changed to BEARISH (Red)");
                  }
                  else
                  {
                     pf.SetColor(PFP_COLOR_BULL);
                     g_Logger.Info("Fork color changed to BULLISH (Dark Green)");
                  }
                  // Update the pitchfork in manager array directly and re-render
                  CPFP_Pitchfork tempPf;
                  for(int i = 0; i < g_Manager.GetCount(); i++)
                  {
                     if(g_Manager.Get(i, tempPf) && tempPf.ID() == pf.ID())
                     {
                        // Remove old and add updated
                        g_Manager.RemovePitchfork(pf.ID());
                        g_Manager.Add(pf);
                        break;
                     }
                  }
                  g_Manager.RenderAllActive();
               }
            }
         }
         // Toggle Warning Lines Event
         else if(eventType == PFP_EVENT_TOGGLE_WARNING)
         {
            g_Logger.Info("Toggle warning lines requested");
            if(g_Renderer != NULL)
            {
               bool current = g_Renderer.GetShowWarningLines();
               g_Renderer.SetShowWarningLines(!current);
               g_Logger.Info("Warning lines now: " + (!current ? "VISIBLE" : "HIDDEN"));
               // Re-render all pitchforks to apply changes
               if(g_Manager != NULL)
                  g_Manager.RenderAllActive();
            }
         }
         // Toggle Quarter Lines Event
         else if(eventType == PFP_EVENT_TOGGLE_QUARTER)
         {
            g_Logger.Info("Toggle quarter lines requested");
            if(g_Renderer != NULL)
            {
               bool current = g_Renderer.GetShowQuarterLines();
               g_Renderer.SetShowQuarterLines(!current);
               g_Logger.Info("Quarter lines now: " + (!current ? "VISIBLE" : "HIDDEN"));
               // Re-render all pitchforks to apply changes
               if(g_Manager != NULL)
                  g_Manager.RenderAllActive();
            }
         }
      }
      
      //--- پردازش رویدادهای ذخیره شده در صف
      //--- در حال حاضر فقط برای لاگ و آمار استفاده می‌شود
      if(g_Logger.IsEnabled(LOG_LEVEL_DEBUG))
      {
         g_Logger.Debug("پردازش رویداد از صف: " + IntegerToString(g_EventQueue[i].type));
      }
   }
   
   //--- پاکسازی صف
   g_EventQueueSize = 0;
}


//+------------------------------------------------------------------+
//| TIMER                                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
   // بررسی سلامت اشیاء و پاکسازی اشیاء یتیم
   if(g_ObjectMgr != NULL)
   {
      // Cleanup orphans logic would go here
   }
}


//+------------------------------------------------------------------+
//| هندلر دستور اسکن (کلید S)                                        |
//+------------------------------------------------------------------+
void HandleScanCommand()
{
   if(!Inp_EnableScanner)
   {
      g_Logger.Warning("اسکنر غیرفعال است.");
      return;
   }

   g_IsProcessing = true;
   
   // اسکن و ذخیره تمام پیچ‌فورک‌های موجود در چارت
   if(g_Manager != NULL)
   {
      g_Manager.ScanAndStoreAll();
      g_Manager.RenderAllActive();
      
      // بروزرسانی GUI اگر فعال است - اکنون فقط از GUI استفاده می‌کنیم
      // داشبورد حذف شده است
      
      // بروزرسانی داشبورد - حذف شد (از GUI استفاده می‌کنیم)
      // if(g_Dashboard != NULL)
      // {
      //    int count = g_Manager.GetCount();
      //    g_Dashboard.Update(count, true);
      // }
   }
   
   g_Logger.Info("اسکن انجام شد.");
   
   g_IsProcessing = false;
}


//+------------------------------------------------------------------+
//| هندلر دستور جایگزینی (کلید R)                                    |
//+------------------------------------------------------------------+
void HandleReplaceCommand()
{
   g_IsProcessing = true;
   
   // جایگزینی تمام پیچ‌فورک‌های استاندارد با نسخه پیشرفته
   if(g_Manager != NULL)
   {
      // بررسی حالت جایگزینی - فعلاً همیشه از حالت اسکن کامل استفاده می‌کنیم
      // داشبورد حذف شده است، بنابراین useReplaceMode همیشه false است
      bool useReplaceMode = false;
      
      if(useReplaceMode)
      {
         // حالت جدید: اسکن و تبدیل با پشتیبانی از انواع Schiff
         g_Logger.Info("حالت جایگزینی فعال است - اسکن با پشتیبانی از انواع چنگال");
         g_Manager.ScanAndStoreAll();
      }
      else
      {
         // حالت قدیمی: فقط جایگزینی استاندارد
         g_Manager.ReplaceAllPitchforks();
      }
      
      g_Manager.RenderAllActive();
      
      // بروزرسانی داشبورد - حذف شد (از GUI استفاده می‌کنیم)
      // if(g_Dashboard != NULL)
      // {
      //    int count = g_Manager.GetCount();
      //    g_Dashboard.Update(count, true);
      // }
   }
   
   g_Logger.Info("جایگزینی انجام شد.");
   
   g_IsProcessing = false;
}


//+------------------------------------------------------------------+
//| استخراج ID از نام شیء                                            |
//+------------------------------------------------------------------+
bool ExtractIDFromObjectName(const string objName, string &outID)
{
   // فرمت نام: PFP_{ID}_L{LineIndex}
   int start = StringFind(objName, "_");
   if(start == -1) return false;
   
   int end = StringFind(objName, "_", start + 1);
   if(end == -1) return false;
   
   outID = StringSubstr(objName, start + 1, end - start - 1);
   return (StringLen(outID) > 0);
}

//+------------------------------------------------------------------+
