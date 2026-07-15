//+------------------------------------------------------------------+
//| PFP_TypeDetector.mqh                                             |
//| Copyright 2024, PitchforkPro Team                                |
//| https://pitchforkpro.com                                         |
//+------------------------------------------------------------------+
#property copyright "2024, PitchforkPro Team"
#property link      "https://pitchforkpro.com"
#property version   "1.0.0"
//+------------------------------------------------------------------+
#include "../Utils/PFP_Logger.mqh"
#include "../Utils/PFP_Constants.mqh"
#include "PFP_GeometryData.mqh"
//+------------------------------------------------------------------+
//| انواع Pitchfork                                                   |
//+------------------------------------------------------------------+
// Use ENUM_PFP_TYPE from constants instead of redefining
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ساختار نتیجه تشخیص                                                |
//+------------------------------------------------------------------+
struct SPFP_TypeResult
{
   ENUM_PFP_TYPE type;           // Use ENUM_PFP_TYPE from constants
   double confidence;      // ضریب اطمینان (0.0 تا 1.0)
   string description;     // توضیحات
};

//+------------------------------------------------------------------+
//| کلاس تشخیص نوع Pitchfork بر اساس هندسه                           |
//| حذف Thresholdهای ثابت و استفاده از الگوریتم برداری              |
//+------------------------------------------------------------------+
class CPFP_TypeDetector
{
private:
   CPFP_Logger* m_logger;
   
   // محاسبه زاویه بین دو بردار
   double CalculateAngle(const datetime t1, const double p1,
                         const datetime t2, const double p2,
                         const datetime t3, const double p3)
   {
      // تبدیل به مختصات دکارتی (با نرمال‌سازی زمان)
      double x1 = (double)(t2 - t1);
      double y1 = p2 - p1;
      double x2 = (double)(t3 - t2);
      double y2 = p3 - p2;
      
      // محاسبه ضرب داخلی
      double dot = x1 * x2 + y1 * y2;
      
      // محاسبه اندازه بردارها
      double mag1 = MathSqrt(x1 * x1 + y1 * y1);
      double mag2 = MathSqrt(x2 * x2 + y2 * y2);
      
      if(mag1 < 0.0001 || mag2 < 0.0001)
         return 0.0;
      
      // محاسبه کسینوس زاویه
      double cosAngle = dot / (mag1 * mag2);
      
      // محدود کردن به بازه [-1, 1]
      if(cosAngle > 1.0) cosAngle = 1.0;
      if(cosAngle < -1.0) cosAngle = -1.0;
      
      // تبدیل به درجه - استفاده از MathAcos بجای MathAcosh
      return MathAcos(cosAngle) * (180.0 / M_PI);
   }
   
   // محاسبه نسبت طول‌ها
   double CalculateLengthRatio(const datetime t1, const double p1,
                               const datetime t2, const double p2,
                               const datetime t3, const double p3)
   {
      double len1 = MathSqrt(MathPow((double)(t2 - t1), 2) + MathPow(p2 - p1, 2));
      double len2 = MathSqrt(MathPow((double)(t3 - t2), 2) + MathPow(p3 - p2, 2));
      
      if(len2 < 0.0001)
         return 0.0;
      
      return len1 / len2;
   }
   
   // بررسی موازی بودن خطوط
   bool AreLinesParallel(const datetime t1, const double p1,
                         const datetime t2, const double p2,
                         const datetime t3, const double p3,
                         const datetime t4, const double p4)
   {
      // محاسبه شیب خطوط
      double dt1 = (double)(t2 - t1);
      double dp1 = p2 - p1;
      double dt2 = (double)(t4 - t3);
      double dp2 = p4 - p3;
      
      if(MathAbs(dt1) < 0.0001 || MathAbs(dt2) < 0.0001)
         return false;
      
      double slope1 = dp1 / dt1;
      double slope2 = dp2 / dt2;
      
      // بررسی نزدیکی شیب‌ها (با تولرانس نسبی)
      double diff = MathAbs(slope1 - slope2);
      double avgSlope = (MathAbs(slope1) + MathAbs(slope2)) / 2.0;
      
      if(avgSlope < 0.0001)
         return diff < 0.01;
      
      return (diff / avgSlope) < 0.15; // 15% تولرانس
   }

public:
   CPFP_TypeDetector()
   {
      m_logger = new CPFP_Logger("TypeDetector");
      m_logger.Info("تشخیص نوع Pitchfork راه‌اندازی شد");
   }
   
   ~CPFP_TypeDetector()
   {
      delete m_logger;
   }
   
   // -----------------------------------------------------------------
   // تشخیص نوع Pitchfork بر اساس نقاط سه‌گانه
   // -----------------------------------------------------------------
   SPFP_TypeResult Detect(const S_PFP_Geometry &geometry)
   {
      SPFP_TypeResult result;
      result.type = PFP_UNKNOWN;
      result.confidence = 0.0;
      result.description = "";
      
      // اعتبارسنجی داده‌ها
      if(geometry.P1.Time == 0 || geometry.P2.Time == 0 || geometry.P3.Time == 0)
      {
         m_logger.Error("داده‌های نامعتبر برای تشخیص نوع");
         result.description = "داده‌های نامعتبر";
         return result;
      }
      
      // استخراج نقاط
      datetime t1 = geometry.P1.Time;
      double p1 = geometry.P1.Price;
      datetime t2 = geometry.P2.Time;
      double p2 = geometry.P2.Price;
      datetime t3 = geometry.P3.Time;
      double p3 = geometry.P3.Price;
      
      // محاسبه ویژگی‌های هندسی
      double ratio = CalculateLengthRatio(t1, p1, t2, p2, t3, p3);
      double angle = CalculateAngle(t1, p1, t2, p2, t3, p3);
      
      m_logger.Debug("نسبت طول‌ها: " + DoubleToString(ratio, 3));
      m_logger.Debug("زاویه: " + DoubleToString(angle, 2) + " درجه");
      
      // الگوریتم تشخیص مبتنی بر قوانین هندسی
      
      // 1. تشخیص Schiff: نقطه میانی باید بسیار نزدیک به خط شروع-پایان باشد
      if(IsPointOnLine(t1, p1, t3, p3, t2, p2))
      {
         result.type = PFP_SCHIFF;
         result.confidence = 0.85;
         result.description = "شیف: نقطه میانی روی خط مستقیم شروع-پایان";
         m_logger.Info("نوع شناسایی شد: Schiff (اطمینان: " + DoubleToString(result.confidence * 100, 0) + "%)");
         return result;
      }
      
      // 2. تشخیص Modified Schiff: نقطه میانی کمی انحراف دارد
      if(IsPointNearLine(t1, p1, t3, p3, t2, p2))
      {
         result.type = PFP_MODIFIED_SCHIFF;
         result.confidence = 0.80;
         result.description = "شیف اصلاح‌شده: نقطه میانی نزدیک به خط مستقیم";
         m_logger.Info("نوع شناسایی شد: Modified Schiff (اطمینان: " + DoubleToString(result.confidence * 100, 0) + "%)");
         return result;
      }
      
      // 3. تشخیص Standard: حالت پیش‌فرض وقتی شرایط بالا برقرار نیست
      result.type = PFP_STANDARD;
      result.confidence = 0.75;
      result.description = "استاندارد: الگوی معمولی چنگال اندروز";
      m_logger.Info("نوع شناسایی شد: Standard (اطمینان: " + DoubleToString(result.confidence * 100, 0) + "%)");
      return result;
   }
   
   // -----------------------------------------------------------------
   // بررسی قرار گرفتن نقطه روی خط
   // -----------------------------------------------------------------
   bool IsPointOnLine(const datetime t1, const double p1,
                      const datetime t3, const double p3,
                      const datetime t2, const double p2)
   {
      // محاسبه فاصله عمودی نقطه از خط
      double expectedPrice = GetExpectedPriceOnLine(t1, p1, t3, p3, t2);
      double diff = MathAbs(p2 - expectedPrice);
      
      // محاسبه محدوده قیمت برای تولرانس
      double priceRange = MathAbs(p3 - p1);
      if(priceRange < 0.0001)
         return diff < 0.001;
      
      // نقطه روی خط است اگر فاصله کمتر از 2% محدوده قیمت باشد
      return (diff / priceRange) < 0.02;
   }
   
   // -----------------------------------------------------------------
   // بررسی نزدیکی نقطه به خط
   // -----------------------------------------------------------------
   bool IsPointNearLine(const datetime t1, const double p1,
                        const datetime t3, const double p3,
                        const datetime t2, const double p2)
   {
      double expectedPrice = GetExpectedPriceOnLine(t1, p1, t3, p3, t2);
      double diff = MathAbs(p2 - expectedPrice);
      
      double priceRange = MathAbs(p3 - p1);
      if(priceRange < 0.0001)
         return diff < 0.01;
      
      // نقطه نزدیک به خط است اگر فاصله کمتر از 5% محدوده قیمت باشد
      return (diff / priceRange) < 0.05;
   }
   
   // -----------------------------------------------------------------
   // محاسبه قیمت مورد انتظار روی خط در زمان مشخص
   // -----------------------------------------------------------------
   double GetExpectedPriceOnLine(const datetime t1, const double p1,
                                 const datetime t3, const double p3,
                                 const datetime t2)
   {
      double dt_total = (double)(t3 - t1);
      double dt_current = (double)(t2 - t1);
      
      if(MathAbs(dt_total) < 0.0001)
         return p1;
      
      double ratio = dt_current / dt_total;
      return p1 + (p3 - p1) * ratio;
   }
};
//+------------------------------------------------------------------+
