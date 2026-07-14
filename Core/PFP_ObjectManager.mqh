#ifndef PFP_OBJECTMANAGER_MQH
#define PFP_OBJECTMANAGER_MQH

#include "../Utils/PFP_Constants.mqh"
#include "../Utils/PFP_Logger.mqh"
#include "PFP_MultiManager.mqh"
#include "PFP_Renderer.mqh"
#include "PFP_GeometryEngine.mqh"

class CPFP_ObjectManager
{

private:

   CPFP_Logger        *m_logger;
   CPFP_MultiManager  *m_manager;
   CPFP_Renderer      *m_renderer;
   CPFP_GeometryEngine *m_geometry;

public:

//==================================================
// Constructor
//==================================================

CPFP_ObjectManager(CPFP_Logger *logger, CPFP_MultiManager *manager)
{
   m_logger = logger;
   m_manager = manager;
   m_renderer = NULL;
   m_geometry = NULL;
   
   if(m_logger != NULL)
      m_logger.Info("ObjectManager Initialized");
}

//==================================================
// Set Engines
//==================================================

void SetEngines(CPFP_Renderer *renderer, CPFP_GeometryEngine *geometry)
{
   m_renderer = renderer;
   m_geometry = geometry;
}

//==================================================
// Clear All PFP Objects
//==================================================

void Clear()
{

   int total=
      ObjectsTotal(
                   0,
                   -1,
                   -1
                  );


   for(int i=total-1;i>=0;i--)
   {


      string name=
         ObjectName(
                    0,
                    i,
                    -1,
                    -1
                   );


      if(name=="")
         continue;




      if(StringFind(
                     name,
                     PFP_PREFIX
                    )==0)
      {


         ObjectDelete(
                      0,
                      name
                     );


      }


   }



   if(m_logger != NULL)
      m_logger.Info("ObjectManager : PFP Objects Cleared");
   else
      Print("ObjectManager : PFP Objects Cleared");

}





//==================================================
// Remove One Object
//==================================================

bool Remove(string name)
{


   if(ObjectFind(0,name)<0)
      return(false);




   return(
          ObjectDelete(
                       0,
                       name
                      )
         );


}





//==================================================
// Delete Original MT5 Pitchfork
//==================================================

bool DeleteOriginalPitchfork()
{


   int total=
      ObjectsTotal(
                   0,
                   -1,
                   -1
                  );





   for(int i=total-1;i>=0;i--)
   {


      string name=
         ObjectName(
                    0,
                    i,
                    -1,
                    -1
                   );


      if(name=="")
         continue;





      ENUM_OBJECT type=
         (ENUM_OBJECT)
         ObjectGetInteger(
                          0,
                          name,
                          OBJPROP_TYPE
                         );





      if(type==OBJ_PITCHFORK)
      {


         if(ObjectDelete(
                         0,
                         name
                        ))
         {


            if(m_logger != NULL)
               m_logger.Info("Original Pitchfork Deleted : " + name);
            else
               Print("Original Pitchfork Deleted : ", name);

            return(true);

         }



      }



   }




   if(m_logger != NULL)
      m_logger.Info("No Original Pitchfork Found");
   else
      Print("No Original Pitchfork Found");

   return(false);


}





//==================================================
// Count PFP Objects
//==================================================

int Count()
{


   int result=0;



   int total=
      ObjectsTotal(
                   0,
                   -1,
                   -1
                  );



   for(int i=0;i<total;i++)
   {


      string name=
         ObjectName(
                    0,
                    i,
                    -1,
                    -1
                   );



      if(StringFind(
                    name,
                    PFP_PREFIX
                   )==0)
      {

         result++;

      }


   }





   return(result);


}

};

#endif
