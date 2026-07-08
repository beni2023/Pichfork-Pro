#ifndef PFP_REPLACEENGINE_MQH
#define PFP_REPLACEENGINE_MQH


#include "PFP_Pitchfork.mqh"
#include "PFP_PitchforkReader.mqh"
#include "PFP_GeometryEngine.mqh"
#include "PFP_GeometryData.mqh"
#include "PFP_Renderer.mqh"



class CPFP_ReplaceEngine
{


private:


   CPFP_PitchforkReader m_reader;


   CPFP_GeometryEngine *m_geometry;

   CPFP_Renderer *m_renderer;



public:



//--------------------------------------------------

CPFP_ReplaceEngine()
{

   m_geometry=NULL;

   m_renderer=NULL;

}





//--------------------------------------------------

void SetEngines(
                CPFP_GeometryEngine &geo,
                CPFP_Renderer &renderer
               )
{

   m_geometry=&geo;

   m_renderer=&renderer;

}





//--------------------------------------------------
// Find Original MT5 Pitchfork
//--------------------------------------------------

bool FindOriginal(string &name)
{


   int total=
      ObjectsTotal(
                   0,
                   -1,
                   -1
                  );



   for(int i=0;i<total;i++)
   {


      string obj=
         ObjectName(
                    0,
                    i,
                    -1,
                    -1
                   );



      ENUM_OBJECT type=
         (ENUM_OBJECT)
         ObjectGetInteger(
                          0,
                          obj,
                          OBJPROP_TYPE
                         );



      if(type==OBJ_PITCHFORK)
      {

         name=obj;

         return(true);

      }


   }


   return(false);

}





//--------------------------------------------------
// Replace
//--------------------------------------------------

bool Replace(CPFP_Pitchfork &pf)
{


   if(m_geometry==NULL ||
      m_renderer==NULL)
   {

      Print("ReplaceEngine : Engines Not Connected");

      return(false);

   }





   string name;



   if(!FindOriginal(name))
   {

      Print("ReplaceEngine : No Original Found");

      return(false);

   }





   CPFP_Pitchfork temp;



   if(!m_reader.ReadPoints(
                           name,
                           temp
                          ))
   {

      Print("ReplaceEngine : Read Failed");

      return(false);

   }





   temp.SetID("PFP_REPLACED_001");

   temp.SetActive(true);

   temp.SetDirection(
                    PFP_BULLISH
                   );





   if(!ObjectDelete(
                    0,
                    name
                   ))
   {

      Print("ReplaceEngine : Delete Failed");

      return(false);

   }





   CPFP_GeometryData geo;



   if(!m_geometry.Build(
                       temp,
                       geo
                      ))
   {

      Print("ReplaceEngine : Geometry Failed");

      return(false);

   }




   m_renderer.Draw(
                   temp,
                   geo
                  );




   pf=temp;



   Print("ReplaceEngine : Completed");



   return(true);

}



};



#endif