//+------------------------------------------------------------------+
//|                                                 PFP_Logger.mqh   |
//|                                   Copyright 2024, PitchforkPro  |
//+------------------------------------------------------------------+
#property strict

//--- سطوح لاگ
enum ENUM_PFP_LOG_LEVEL
{
   LOG_LEVEL_DEBUG = 0,      // تمام پیام‌ها (توسعه)
   LOG_LEVEL_INFO  = 1,      // اطلاعات عمومی
   LOG_LEVEL_WARN  = 2,      // هشدارها
   LOG_LEVEL_ERROR = 3,      // خطاها فقط
   LOG_LEVEL_NONE  = 4       // غیرفعال کردن کامل لاگ
};

//--- ثابت جهانی برای حالت Debug/Release
#ifndef PFP_DEBUG
#define PFP_DEBUG true
#endif

//+------------------------------------------------------------------+
//| کلاس مدیریت لاگ متمرکز                                           |
//+------------------------------------------------------------------+
class CPFP_Logger
{
private:
   string           m_Prefix;              // پیشوند پیام‌ها
   ENUM_PFP_LOG_LEVEL m_LogLevel;         // سطح فعلی لاگ
   bool             m_ShowLogs;            // نمایش در کنسول
   int              m_MessageCount;        // تعداد پیام‌ها
   datetime         m_StartTime;           // زمان شروع

public:
   //--- سازنده
   CPFP_Logger(const string prefix = "PFP", 
               const bool showLogs = true, 
               const ENUM_PFP_LOG_LEVEL level = LOG_LEVEL_INFO)
   {
      m_Prefix = prefix;
      
      // در حالت Release (PFP_DEBUG=false)، لاگ‌ها غیرفعال می‌شوند
      #ifndef PFP_DEBUG
         m_ShowLogs = false;
         m_LogLevel = LOG_LEVEL_NONE;
      #else
         m_ShowLogs = showLogs;
         m_LogLevel = level;
      #endif
      
      m_MessageCount = 0;
      m_StartTime = TimeCurrent();
   }
   
   //--- ویرانگر
   ~CPFP_Logger()
   {
      if(m_ShowLogs && m_LogLevel != LOG_LEVEL_NONE)
      {
         PrintFormat("[%s] پایان جلسه لاگ - تعداد پیام‌ها: %d", m_Prefix, m_MessageCount);
      }
   }
   
   //--- تنظیم سطح لاگ
   void SetLogLevel(ENUM_PFP_LOG_LEVEL level)
   {
      m_LogLevel = level;
   }
   
   //--- دریافت سطح لاگ
   ENUM_PFP_LOG_LEVEL GetLogLevel() const
   {
      return m_LogLevel;
   }
   
   //--- فعال/غیرفعال کردن نمایش
   void EnableLogging(bool enable)
   {
      m_ShowLogs = enable;
   }
   
   //--- بررسی فعال بودن لاگ
   bool IsEnabled(ENUM_PFP_LOG_LEVEL level = LOG_LEVEL_DEBUG) const
   {
      return m_ShowLogs && m_LogLevel <= level;
   }
   
   //--- لاگ سطح DEBUG
   void Debug(const string msg)
   {
      if(m_LogLevel <= LOG_LEVEL_DEBUG)
         LogMessage("DEBUG", msg);
   }
   
   //--- لاگ سطح INFO
   void Info(const string msg)
   {
      if(m_LogLevel <= LOG_LEVEL_INFO)
         LogMessage("INFO", msg);
   }
   
   //--- لاگ سطح WARNING
   void Warning(const string msg)
   {
      if(m_LogLevel <= LOG_LEVEL_WARN)
         LogMessage("WARN", msg);
   }
   
   //--- لاگ سطح ERROR
   void Error(const string msg)
   {
      if(m_LogLevel <= LOG_LEVEL_ERROR)
         LogMessage("ERROR", msg);
   }
   
   //--- لاگ عمومی با سطح سفارشی
   void Log(const string msg, ENUM_PFP_LOG_LEVEL level = LOG_LEVEL_INFO)
   {
      if(level >= m_LogLevel)
         LogMessage(EnumToString(level), msg);
   }
   
   //--- لاگ با فرمت سفارشی
   string Format(ENUM_PFP_LOG_LEVEL level, const string format)
   {
      if(level < m_LogLevel || !m_ShowLogs)
         return "";
      
      string msg = StringSubstr(format, 0); // کپی ساده
      
      // برای سادگی، فعلاً از فرمت‌بندی پیچیده صرف نظر می‌کنیم
      // در صورت نیاز می‌توان StringFormat اضافه کرد
      LogMessage(EnumToString(level), msg);
      return msg;
   }
   
private:
   //--- تابع داخلی ثبت پیام
   void LogMessage(const string level, const string msg)
   {
      if(!m_ShowLogs)
         return;
      
      m_MessageCount++;
      string timestamp = TimeToString(TimeCurrent(), TIME_SECONDS);
      PrintFormat("[%s][%s][%s] %s", m_Prefix, timestamp, level, msg);
   }
   
   //--- محاسبه زمان اجرا
   string GetUptime() const
   {
      datetime now = TimeCurrent();
      int seconds = (int)(now - m_StartTime);
      
      int hours = seconds / 3600;
      int minutes = (seconds % 3600) / 60;
      int secs = seconds % 60;
      
      return StringFormat("%02d:%02d:%02d", hours, minutes, secs);
   }
};

//+------------------------------------------------------------------+
