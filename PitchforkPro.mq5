//+------------------------------------------------------------------+
//|                     PitchforkPro.mq5                              |
//|                        نسخه 1.0.0 Stable                          |
//+------------------------------------------------------------------+

#property indicator_chart_window
#property strict
#property indicator_plots 0
#property version   "1.0.0"
#property description "اندیکاتور پیشرفته چنگال اندروز با قابلیت ذخیره‌سازی، جایگزینی و تشخیص هوشمند - نسخه پایدار 1.0"


#include "Utils/PFP_Constants.mqh"
#include "Utils/PFP_Logger.mqh"

#include "Core/PFP_Pitchfork.mqh"
#include "Core/PFP_ObjectManager.mqh"
#include "Core/PFP_GeometryData.mqh"
#include "Core/PFP_GeometryEngine.mqh"
#include "Core/PFP_ObjectScanner.mqh"
#include "Core/PFP_PitchforkReader.mqh"
#include "Core/PFP_Renderer.mqh"
#include "Core/PFP_Storage.mqh"
#include "Core/PFP_ReplaceEngine.mqh"
#include "Core/PFP_Manager.mqh"
#include "Core/PFP_MultiManager.mqh"
#include "Core/PFP_TypeDetector.mqh"


//--- ورودی‌های کاربر
input group "تنظیمات کلیدی"
input bool   Inp_EnableScanner    = true;           // فعال‌سازی اسکنر خودکار
input string Inp_ScanKey          = "S";            // کلید اسکن و ذخیره (پیش‌فرض: S)
input string Inp_ReplaceKey       = "R";            // کلید جایگزینی (پیش‌فرض: R)

input group "تنظیمات ظاهری"
input color  Inp_ColorMain        = clrDodgerBlue;  // رنگ خطوط اصلی
input color  Inp_ColorMedian      = clrYellow;      // رنگ خط میانی
input color  Inp_ColorWarning     = clrOrangeRed;   // رنگ خطوط اخطار/کمکی
input int    Inp_WidthMain        = 2;              // ضخامت خطوط اصلی
input int    Inp_WidthMedian      = 1;              // ضخامت خط میانی

input group "تنظیمات سیستم"
input bool   Inp_ShowLogs         = true;           // نمایش لاگ‌ها در کنسول
input bool   Inp_DeepDebug        = false;          // حالت دیباگ عمیق (توصیه نمی‌شود)


//--- متغیرهای سراسری
CPFP_Logger        *g_Logger = NULL;
CPFP_MultiManager  *g_Manager = NULL;
CPFP_ObjectManager *g_ObjectMgr = NULL;
CPFP_TypeDetector  *g_TypeDetector = NULL;

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
   
   g_Logger.Info("شروع راه‌اندازی PitchforkPro v1.0.0 Stable");

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
   
   //--- ذخیره داده‌ها قبل از خروج
   if(g_Manager != NULL)
   {
      g_Manager.SaveAll();
      delete g_Manager;
   }
   
   if(g_ObjectMgr != NULL)
      delete g_ObjectMgr;
      
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

   //--- همگام‌سازی وضعیت اشیاء با داده‌های حافظه
   if(g_ObjectMgr != NULL)
   {
      g_ObjectMgr.SyncWithChart();
   }

   //--- رسم مجدد تمام پیچ‌فورک‌های فعال (فقط اگر Geometry تغییر کرده باشد)
   if(g_Manager != NULL)
   {
      g_Manager.RenderAllActive();
   }

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
      
      //--- کلید اسکن (S)
      if(StringToUpper(key) == StringToUpper(Inp_ScanKey))
      {
         g_Logger.Info("دستور اسکن دریافت شد (کلید: " + Inp_ScanKey + ")");
         HandleScanCommand();
      }
      
      //--- کلید جایگزینی (R)
      if(StringToUpper(key) == StringToUpper(Inp_ReplaceKey))
      {
         g_Logger.Info("دستور جایگزینی دریافت شد (کلید: " + Inp_ReplaceKey + ")");
         HandleReplaceCommand();
      }
      
      //--- کلید حذف (D یا Delete)
      if(key == "D" || key == "DELETE") 
      {
         if(!StringIsEmpty(g_SelectedPitchforkID))
         {
            g_Logger.Info("حذف پیچ‌فورک انتخاب شده: " + g_SelectedPitchforkID);
            g_Manager.RemovePitchfork(g_SelectedPitchforkID);
            g_SelectedPitchforkID = "";
            g_ObjectMgr.ClearSelection();
            Comment("");
         }
      }
   }
   
   //--- رویداد کلیک ماوس (برای انتخاب پیچ‌فورک)
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      string objName = sparam;
      if(StringFind(objName, "PFP_") == 0)
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
      if(StringFind(objName, "PFP_") == 0)
      {
         string pfID = "";
         if(ExtractIDFromObjectName(objName, pfID))
         {
            g_Logger.Debug("تغییر دستی detected در: " + pfID);
            g_ObjectMgr.UpdateCoordinatesFromChart(pfID);
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
      g_ObjectMgr.CleanupOrphans();
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
   
   int count = g_ObjectMgr.ScanAndSaveStandardPitchforks();
   
   if(count > 0)
   {
      g_Logger.Info("تعداد " + IntegerToString(count) + " پیچ‌فورک جدید شناسایی و ذخیره شد.");
      g_Manager.RenderAllActive();
   }
   else
   {
      g_Logger.Info("هیچ پیچ‌فورک استانداردی برای تبدیل یافت نشد.");
   }
   
   g_IsProcessing = false;
}


//+------------------------------------------------------------------+
//| هندلر دستور جایگزینی (کلید R)                                    |
//+------------------------------------------------------------------+
void HandleReplaceCommand()
{
   g_IsProcessing = true;
   
   int replacedCount = g_Manager.ForceReplaceAllStandard();
   
   if(replacedCount > 0)
   {
      g_Logger.Info("تعداد " + IntegerToString(replacedCount) + " پیچ‌فورک جایگزین شد.");
      g_Manager.RenderAllActive();
   }
   else
   {
      g_Logger.Info("هیچ پیچ‌فورکی برای جایگزینی فوری یافت نشد.");
   }
   
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
   return !StringIsEmpty(outID);
}

//+------------------------------------------------------------------+
