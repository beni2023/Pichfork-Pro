#ifndef PFP_MULTIMANAGER_MQH
#define PFP_MULTIMANAGER_MQH

#include "PFP_Pitchfork.mqh"
#include "PFP_Renderer.mqh"
#include "PFP_GeometryEngine.mqh"
#include "PFP_MultiStorage.mqh"
#include "../Utils/PFP_Logger.mqh"

#define PFP_MAX_PITCHFORKS 100

class CPFP_MultiManager
{
private:

   CPFP_Pitchfork m_pitchforks[PFP_MAX_PITCHFORKS];
   int m_count;
   
   CPFP_Logger *m_logger;
   CPFP_TypeDetector *m_typeDetector;
   CPFP_Renderer *m_renderer;
   CPFP_GeometryEngine *m_geometry;
   CPFP_MultiStorage *m_storage;

public:

   //--------------------------------------------------

   CPFP_MultiManager(CPFP_Logger *logger, CPFP_TypeDetector *typeDetector)
   {
      m_logger = logger;
      m_typeDetector = typeDetector;
      m_renderer = NULL;
      m_geometry = NULL;
      m_storage = new CPFP_MultiStorage();
      Clear();
   }
   
   //--------------------------------------------------
   
   ~CPFP_MultiManager()
   {
      delete m_storage;
   }

   //--------------------------------------------------
   
   void SetEngines(CPFP_Renderer *renderer, CPFP_GeometryEngine *geometry)
   {
      m_renderer = renderer;
      m_geometry = geometry;
   }

   //--------------------------------------------------

   void Clear()
   {
      m_count=0;

      for(int i=0;i<PFP_MAX_PITCHFORKS;i++)
         m_pitchforks[i].Reset();
   }

   //--------------------------------------------------

   int Count() const
   {
      return m_count;
   }

   //--------------------------------------------------

   bool Add(CPFP_Pitchfork &pf)
   {
      if(!pf.Validate())
      {
         if(m_logger != NULL)
            m_logger.Error("MultiManager : Invalid Pitchfork");
         return false;
      }

      if(m_count>=PFP_MAX_PITCHFORKS)
      {
         if(m_logger != NULL)
            m_logger.Error("MultiManager : Maximum pitchforks reached");
         return false;
      }

      m_pitchforks[m_count]=pf;
      m_count++;
      
      if(m_logger != NULL)
         m_logger.Info("MultiManager : Added pitchfork " + pf.ID());

      return true;
   }

   //--------------------------------------------------

   bool Remove(string id)
   {
      for(int i=0;i<m_count;i++)
      {
         if(m_pitchforks[i].ID()==id)
         {
            for(int j=i;j<m_count-1;j++)
               m_pitchforks[j]=m_pitchforks[j+1];

            m_pitchforks[m_count-1].Reset();
            m_count--;
            
            if(m_logger != NULL)
               m_logger.Info("MultiManager : Removed pitchfork " + id);

            return true;
         }
      }

      if(m_logger != NULL)
         m_logger.Warning("MultiManager : Pitchfork not found " + id);
      return false;
   }

   //--------------------------------------------------

   bool Find(string id,CPFP_Pitchfork &pf)
   {
      for(int i=0;i<m_count;i++)
      {
         if(m_pitchforks[i].ID()==id)
         {
            pf=m_pitchforks[i];
            return true;
         }
      }

      return false;
   }

   //--------------------------------------------------

   bool Get(int index,CPFP_Pitchfork &pf)
   {
      if(index<0 || index>=m_count)
         return false;

      pf=m_pitchforks[index];

      return true;
   }
   
   //--------------------------------------------------
   // Save all pitchforks to storage
   //--------------------------------------------------
   
   bool SaveAll()
   {
      if(m_storage == NULL)
         return false;
         
      if(m_count == 0)
      {
         if(m_logger != NULL)
            m_logger.Info("MultiManager : Nothing to save");
         return true;
      }
      
      bool result = m_storage.Save(*this);
      
      if(result && m_logger != NULL)
         m_logger.Info("MultiManager : Saved " + IntegerToString(m_count) + " pitchforks");
         
      return result;
   }
   
   //--------------------------------------------------
   // Load all pitchforks from storage
   //--------------------------------------------------
   
   bool LoadAll()
   {
      if(m_storage == NULL)
         return false;
         
      Clear();
      bool result = m_storage.Load(*this);
      
      if(result && m_logger != NULL)
         m_logger.Info("MultiManager : Loaded " + IntegerToString(m_count) + " pitchforks");
         
      return result;
   }
   
   //--------------------------------------------------
   // Render all active pitchforks
   //--------------------------------------------------
   
   void RenderAllActive()
   {
      if(m_renderer == NULL || m_geometry == NULL)
      {
         if(m_logger != NULL)
            m_logger.Error("MultiManager : Renderer or Geometry not set");
         return;
      }
      
      int rendered = 0;
      for(int i=0; i<m_count; i++)
      {
         if(m_pitchforks[i].Active())
         {
            CPFP_GeometryData geo;
            if(m_geometry.Build(m_pitchforks[i], geo))
            {
               m_renderer.Draw(m_pitchforks[i], geo);
               rendered++;
            }
         }
      }
      
      if(m_logger != NULL && rendered > 0)
         m_logger.Info("MultiManager : Rendered " + IntegerToString(rendered) + " active pitchforks");
   }
   
   //--------------------------------------------------
   // Force replace all standard pitchforks
   //--------------------------------------------------
   
   int ForceReplaceAllStandard()
   {
      // This would need integration with ReplaceEngine
      // For now, return 0 as placeholder
      return 0;
   }

};

#endif
