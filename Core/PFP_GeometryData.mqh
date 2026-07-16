//+------------------------------------------------------------------+
//|                                              PFP_GeometryData.mqh |
//|                                  Copyright 2024, PitchforkPro Dev |
//|                                             https://pitchforkpro.io |
//+------------------------------------------------------------------+
#property copyright "2024, PitchforkPro Dev"
#property link      "https://pitchforkpro.io"
#property version   "1.000"
#property strict

#ifndef PFP_GEOMETRY_DATA_MQH
#define PFP_GEOMETRY_DATA_MQH

#include "../Utils/PFP_Constants.mqh"

//+------------------------------------------------------------------+
//| ساختار داده‌های یک نقطه (Anchor)                                   |
//+------------------------------------------------------------------+
struct S_PFP_Point
{
   datetime Time;
   double   Price;
   
   S_PFP_Point() : Time(0), Price(0.0) {}
   S_PFP_Point(datetime t, double p) : Time(t), Price(p) {}
};

//+------------------------------------------------------------------+
//| ساختار داده‌های هندسی کامل یک Pitchfork                           |
//+------------------------------------------------------------------+
struct S_PFP_Geometry
{
   ulong      ID;              // شناسه یکتا
   int        Type;            // نوع پیچ‌فورک (Standard, Schiff, ...)
   int        Direction;       // جهت (Bullish/Bearish)
   S_PFP_Point P1;             // نقطه شروع (پیوت اصلی)
   S_PFP_Point P2;             // نقطه میانی اول
   S_PFP_Point P3;             // نقطه میانی دوم
   
   // نقاط محاسبه شده (میانه‌ها و خطوط موازی)
   datetime   MedianTimeStart;
   double     MedianPriceStart;
   datetime   MedianTimeEnd;
   double     MedianPriceEnd;
   
   datetime   UpperTimeStart;
   double     UpperPriceStart;
   datetime   UpperTimeEnd;
   double     UpperPriceEnd;
   
   datetime   LowerTimeStart;
   double     LowerPriceStart;
   datetime   LowerTimeEnd;
   double     LowerPriceEnd;
   
   // خطوط میانی اضافی
   datetime   MidUpperTimeStart;
   double     MidUpperPriceStart;
   datetime   MidUpperTimeEnd;
   double     MidUpperPriceEnd;
   
   datetime   MidLowerTimeStart;
   double     MidLowerPriceStart;
   datetime   MidLowerTimeEnd;
   double     MidLowerPriceEnd;

   S_PFP_Geometry() 
   {
      ID = 0;
      Type = PFP_STANDARD;
      Direction = PFP_BULLISH;
      Reset();
   }
   
   void Reset()
   {
      P1.Time = 0; P1.Price = 0;
      P2.Time = 0; P2.Price = 0;
      P3.Time = 0; P3.Price = 0;
      
      MedianTimeStart = 0; MedianPriceStart = 0;
      MedianTimeEnd = 0; MedianPriceEnd = 0;
      UpperTimeStart = 0; UpperPriceStart = 0;
      UpperTimeEnd = 0; UpperPriceEnd = 0;
      LowerTimeStart = 0; LowerPriceStart = 0;
      LowerTimeEnd = 0; LowerPriceEnd = 0;
      MidUpperTimeStart = 0; MidUpperPriceStart = 0;
      MidUpperTimeEnd = 0; MidUpperPriceEnd = 0;
      MidLowerTimeStart = 0; MidLowerPriceStart = 0;
      MidLowerTimeEnd = 0; MidLowerPriceEnd = 0;
   }
   
   bool IsValid() const
   {
      return (P1.Time != 0 && P2.Time != 0 && P3.Time != 0 &&
              P1.Price != 0 && P2.Price != 0 && P3.Price != 0);
   }
};

#endif // PFP_GEOMETRY_DATA_MQH
