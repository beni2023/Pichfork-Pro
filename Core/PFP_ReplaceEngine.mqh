#ifndef PFP_REPLACEENGINE_MQH
#define PFP_REPLACEENGINE_MQH

#include "PFP_Pitchfork.mqh"
#include "PFP_PitchforkReader.mqh"
#include "PFP_GeometryEngine.mqh"
#include "PFP_GeometryData.mqh"
#include "PFP_Renderer.mqh"
#include "PFP_ObjectManager.mqh"
#include "../Utils/PFP_Constants.mqh"

class CPFP_ReplaceEngine
{
private:
   CPFP_PitchforkReader m_reader;
   CPFP_GeometryEngine *m_geometry;
   CPFP_Renderer *m_renderer;
   CPFP_ObjectManager *m_objManager;

public:
   //--------------------------------------------------
   CPFP_ReplaceEngine()
   {
      m_geometry = NULL;
      m_renderer = NULL;
      m_objManager = NULL;
   }

   //--------------------------------------------------
   void SetEngines(CPFP_GeometryEngine *geo, CPFP_Renderer *renderer, CPFP_ObjectManager *objManager)
   {
      m_geometry = geo;
      m_renderer = renderer;
      m_objManager = objManager;
   }

   //--------------------------------------------------
   bool FindOriginal(string &name)
   {
      int total = ObjectsTotal(0, -1, OBJ_PITCHFORK);
      
      for(int i = 0; i < total; i++)
      {
         string obj = ObjectName(0, i, -1, -1);
         if(obj == "") continue;
         
         // Ignore PFP objects
         if(StringFind(obj, PFP_PREFIX) == 0) continue;
         
         ENUM_OBJECT type = (ENUM_OBJECT)ObjectGetInteger(0, obj, OBJPROP_TYPE);
         if(type == OBJ_PITCHFORK)
         {
            name = obj;
            return true;
         }
      }
      return false;
   }

   //--------------------------------------------------
   bool Replace(CPFP_Pitchfork &pf)
   {
      if(m_geometry == NULL || m_renderer == NULL || m_objManager == NULL)
      {
         Print("ReplaceEngine : Engines Not Connected");
         return false;
      }

      string name;
      if(!FindOriginal(name))
      {
         Print("ReplaceEngine : No Original Found");
         return false;
      }

      CPFP_Pitchfork temp;
      if(!m_reader.ReadPoints(name, temp))
      {
         Print("ReplaceEngine : Read Failed");
         return false;
      }

      // Generate unique ID
      string id = "PFP_REPL_" + TimeToString(TimeCurrent(), TIME_SECONDS);
      id = StringReplace(id, ":", "_");
      temp.SetID(id);
      temp.SetActive(true);

      // Detect direction based on price movement
      if(temp.PriceC() > temp.PriceA())
         temp.SetDirection(PFP_BULLISH);
      else if(temp.PriceC() < temp.PriceA())
         temp.SetDirection(PFP_BEARISH);
      else
         temp.SetDirection(PFP_NEUTRAL);

      if(!ObjectDelete(0, name))
      {
         Print("ReplaceEngine : Delete Failed");
         return false;
      }

      CPFP_GeometryData geo;
      if(!m_geometry.Build(temp, geo))
      {
         Print("ReplaceEngine : Geometry Failed");
         return false;
      }

      m_renderer.Draw(temp, geo, RENDER_MODE_FULL);
      pf = temp;

      Print("ReplaceEngine : Completed, ID=", temp.ID());
      return true;
   }
};

#endif
