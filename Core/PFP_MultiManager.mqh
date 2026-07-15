#ifndef PFP_MULTIMANAGER_MQH
#define PFP_MULTIMANAGER_MQH

#include "PFP_Pitchfork.mqh"
#include "PFP_Renderer.mqh"
#include "PFP_GeometryEngine.mqh"
#include "PFP_MultiStorage.mqh"
#include "PFP_ObjectManager.mqh"
#include "PFP_ReplaceEngine.mqh"
#include "PFP_TypeDetector.mqh"
#include "../Utils/PFP_Logger.mqh"
#include "../Utils/PFP_Constants.mqh"

class CPFP_MultiManager
{
private:

   CPFP_Pitchfork m_pitchforks[PFP_MAX_PITCHFORKS];
   int m_count;
   
   CPFP_Logger *m_logger;
   CPFP_Renderer *m_renderer;
   CPFP_GeometryEngine *m_geometry;
   CPFP_MultiStorage *m_storage;
   CPFP_ObjectManager *m_objManager;
   CPFP_TypeDetector *m_typeDetector;

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
   
   void SetObjectManager(CPFP_ObjectManager *objManager)
   {
      m_objManager = objManager;
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
   
   int GetCount() const
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
   // Alias for Remove() to match API expectations
   //--------------------------------------------------
   
   bool RemovePitchfork(string id)
   {
      return Remove(id);
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
      
      bool result = m_storage.Save(m_count);
      
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
      int loadedCount = 0;
      bool result = m_storage.Load(loadedCount);
      m_count = loadedCount;
      
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
               m_renderer.Draw(m_pitchforks[i], geo, RENDER_MODE_FULL);
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
      if(m_objManager == NULL || m_geometry == NULL)
         return 0;
         
      int replaced = 0;
      CPFP_ReplaceEngine replacer;
      replacer.SetEngines(m_geometry, m_renderer, m_objManager);
      
      // Keep trying to find and replace original pitchforks
      while(true)
      {
         CPFP_Pitchfork pf;
         if(replacer.Replace(pf))
         {
            Add(pf);
            replaced++;
         }
         else
            break;
      }
      
      return replaced;
   }

   //--------------------------------------------------
   // Scan and store all pitchforks on chart
   //--------------------------------------------------
   
   void ScanAndStoreAll()
   {
      if(m_objManager == NULL || m_typeDetector == NULL)
      {
         if(m_logger != NULL)
            m_logger.Error("MultiManager: Cannot scan - missing dependencies");
         return;
      }
      
      m_logger.Info("MultiManager: Starting full chart scan...");
      
      // Use ObjectScanner to find all pitchfork objects
      CPFP_ObjectScanner scanner;
      scanner.SetLogger(m_logger);
      
      string foundIDs[];
      int count = scanner.ScanAllPitchforks(foundIDs);
      
      if(count == 0)
      {
         m_logger.Info("MultiManager: No pitchforks found on chart");
         return;
      }
      
      m_logger.Info("MultiManager: Found " + IntegerToString(count) + " pitchfork candidates");
      
      // Process each found pitchfork
      for(int i = 0; i < count && m_count < PFP_MAX_PITCHFORKS; i++)
      {
         string pfID = foundIDs[i];
         
         // Check if already exists
         bool exists = false;
         for(int j = 0; j < m_count; j++)
         {
            if(m_pitchforks[j].ID() == pfID)
            {
               exists = true;
               break;
            }
         }
         
         if(exists) continue;
         
         // Read pitchfork data from chart objects
         CPFP_PitchforkReader reader;
         CPFP_Pitchfork pf;
         
         if(reader.ReadFromChart(pfID, pf))
         {
            // Detect type if not already set
            if(pf.Type() == ENUM_PFP_TYPE_UNKNOWN)
            {
               ENUM_PFP_TYPE detectedType = m_typeDetector.Detect(pf);
               pf.SetType(detectedType);
            }
            
            // Set as active and add to list
            pf.SetActive(true);
            Add(pf);
            
            m_logger.Debug("MultiManager: Stored pitchfork " + pfID);
         }
      }
      
      m_logger.Info("MultiManager: Scan complete. Total stored: " + IntegerToString(m_count));
   }

   //--------------------------------------------------
   // Replace all standard MT5 pitchforks
   //--------------------------------------------------
   
   void ReplaceAllPitchforks()
   {
      m_logger.Info("MultiManager: Starting replacement of all standard pitchforks...");
      
      int replaced = ForceReplaceAllStandard();
      
      m_logger.Info("MultiManager: Replaced " + IntegerToString(replaced) + " standard pitchforks");
   }

   //--------------------------------------------------
   // Get total pitchforks count (alias for Count)
   //--------------------------------------------------
   
   int TotalPitchforks() const
   {
      return m_count;
   }
   
   //--------------------------------------------------
   // Remove all pitchforks
   //--------------------------------------------------
   
   void RemoveAll()
   {
      m_logger.Info("MultiManager: Removing all " + IntegerToString(m_count) + " pitchforks");
      
      // Delete all chart objects
      if(m_objManager != NULL)
      {
         for(int i = 0; i < m_count; i++)
         {
            m_objManager.DeletePitchforkObjects(m_pitchforks[i].GetID());
         }
      }
      
      // Clear storage
      if(m_storage != NULL)
      {
         m_storage->ClearAll();
      }
      
      // Reset count
      Clear();
      
      m_logger.Info("MultiManager: All pitchforks removed");
   }

};

#endif
