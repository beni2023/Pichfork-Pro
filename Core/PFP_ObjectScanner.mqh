#ifndef PFP_OBJECTSCANNER_MQH
#define PFP_OBJECTSCANNER_MQH

#include "../Utils/PFP_Constants.mqh"
#include "../Utils/PFP_Logger.mqh"

class CPFP_ObjectScanner
{
private:
   CPFP_Logger *m_logger;
   
public:

   void SetLogger(CPFP_Logger *logger)
   {
      m_logger = logger;
   }

   int Scan()
   {
      int found = 0;

      int total = ObjectsTotal(0,-1,OBJ_PITCHFORK);

      if(m_logger != NULL)
         m_logger.Info("========== OBJECT SCAN ==========");
      else
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

         if(m_logger != NULL)
         {
            m_logger.Debug("Original Pitchfork Found: " + name);
         }
         else
         {
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
      }

      if(m_logger != NULL)
         m_logger.Info("Pitchforks Found: " + IntegerToString(found));
      else
      {
         Print("--------------------------------");
         Print("Pitchfork Found : ",found);
      }
      
      if(m_logger != NULL)
         m_logger.Info("========== END SCAN ==========");
      else
         Print("========== END SCAN ==========");

      return(found);
   }
   
   //--------------------------------------------------
   // Scan all pitchforks and return IDs in array
   //--------------------------------------------------
   
   int ScanAllPitchforks(string &outIDs[])
   {
      int found = 0;
      int total = ObjectsTotal(0,-1,OBJ_PITCHFORK);
      
      // Clear output array
      ArrayResize(outIDs, 0);
      
      for(int i = 0; i < total; i++)
      {
         string name = ObjectName(0,i,-1,-1);
         
         if(name == "")
            continue;
            
         // Skip PitchforkPro objects (already converted)
         if(StringFind(name, PFP_PREFIX) == 0)
            continue;
            
         ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(0, name, OBJPROP_TYPE);
         
         if(type != OBJ_PITCHFORK)
            continue;
            
         // Extract ID from name or generate one
         string pfID = name;
         
         // Add to array
         int idx = ArraySize(outIDs);
         ArrayResize(outIDs, idx + 1);
         outIDs[idx] = pfID;
         found++;
         
         if(m_logger != NULL)
            m_logger.Debug("Scanner: Found pitchfork '" + pfID + "'");
      }
      
      if(m_logger != NULL)
         m_logger.Info("Scanner: Total original pitchforks found: " + IntegerToString(found));
      
      return found;
   }

};

#endif