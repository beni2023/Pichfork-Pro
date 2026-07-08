#ifndef PFP_OBJECTSCANNER_MQH
#define PFP_OBJECTSCANNER_MQH

#include "../Utils/PFP_Constants.mqh"

class CPFP_ObjectScanner
{
public:

   int Scan()
   {
      int found = 0;

      int total = ObjectsTotal(0,-1,-1);

      Print("========== OBJECT SCAN ==========");

      for(int i=0;i<total;i++)
      {
         string name = ObjectName(0,i,-1,-1);

         if(name=="")
            continue;

         // Ignore PitchforkPro objects
         if(StringFind(name,PFP_PREFIX)==0)
            continue;

         ENUM_OBJECT type=(ENUM_OBJECT)ObjectGetInteger(
                           0,
                           name,
                           OBJPROP_TYPE
                           );

         if(type!=OBJ_PITCHFORK)
            continue;

         found++;

         Print("--------------------------------");
         Print("Original Pitchfork");
         Print("Name : ",name);
         Print("Type : ",EnumToString(type));

         datetime t0=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,0);
         datetime t1=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,1);
         datetime t2=(datetime)ObjectGetInteger(0,name,OBJPROP_TIME,2);

         double p0=ObjectGetDouble(0,name,OBJPROP_PRICE,0);
         double p1=ObjectGetDouble(0,name,OBJPROP_PRICE,1);
         double p2=ObjectGetDouble(0,name,OBJPROP_PRICE,2);

         Print("A : ",TimeToString(t0)," ",DoubleToString(p0,_Digits));
         Print("B : ",TimeToString(t1)," ",DoubleToString(p1,_Digits));
         Print("C : ",TimeToString(t2)," ",DoubleToString(p2,_Digits));
      }

      Print("--------------------------------");
      Print("Pitchfork Found : ",found);
      Print("========== END SCAN ==========");

      return(found);
   }

};

#endif