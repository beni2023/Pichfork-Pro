#ifndef PFP_RENDERER_MQH
#define PFP_RENDERER_MQH


#include "../Utils/PFP_Constants.mqh"

#include "PFP_Pitchfork.mqh"
#include "PFP_GeometryData.mqh"





class CPFP_Renderer
{


public:




//==================================================
// Draw
//==================================================

void Draw(
          CPFP_Pitchfork &pf,
          CPFP_GeometryData &geo
         )
{


   if(!pf.Validate())
   {

      Print("Renderer : Invalid Pitchfork");

      return;

   }



   string id=
      ObjectID(
               pf
              );




   Clear(
         pf
        );





   color mainColor=
      pf.GetColor();






   // Median

   DrawLine(
            id+"_MEDIAN",
            geo.MedianTime1,
            geo.MedianPrice1,
            geo.MedianTime2,
            geo.MedianPrice2,
            PFP_COLOR_MEDIAN
           );






   // Upper

   DrawLine(
            id+"_UPPER",
            geo.UpperTime1,
            geo.UpperPrice1,
            geo.UpperTime2,
            geo.UpperPrice2,
            mainColor
           );






   // Lower

   DrawLine(
            id+"_LOWER",
            geo.LowerTime1,
            geo.LowerPrice1,
            geo.LowerTime2,
            geo.LowerPrice2,
            mainColor
           );







   // Mid Upper

   DrawLine(
            id+"_MID_UPPER",
            geo.MidUpperTime1,
            geo.MidUpperPrice1,
            geo.MidUpperTime2,
            geo.MidUpperPrice2,
            clrSilver
           );







   // Mid Lower

   DrawLine(
            id+"_MID_LOWER",
            geo.MidLowerTime1,
            geo.MidLowerPrice1,
            geo.MidLowerTime2,
            geo.MidLowerPrice2,
            clrSilver
           );






   Print(
         "Renderer : Draw ",
         id
        );



}








//==================================================
// Clear Pitchfork Objects
//==================================================

void Clear(
           CPFP_Pitchfork &pf
          )
{


   string id=
      ObjectID(
               pf
              );



   Delete(id+"_MEDIAN");

   Delete(id+"_UPPER");

   Delete(id+"_LOWER");

   Delete(id+"_MID_UPPER");

   Delete(id+"_MID_LOWER");



}







//==================================================
// Private
//==================================================

private:





string ObjectID(
                CPFP_Pitchfork &pf
               )
{


   return(
          PFP_PREFIX+
          pf.ID()
         );


}







void DrawLine(
              string name,
              datetime t1,
              double p1,
              datetime t2,
              double p2,
              color clr
             )
{


   Delete(name);





   if(!ObjectCreate(
                    0,
                    name,
                    OBJ_TREND,
                    0,
                    t1,
                    p1,
                    t2,
                    p2
                   ))
   {


      Print(
            "Renderer Create Failed ",
            name
           );


      return;

   }







   ObjectSetInteger(
                    0,
                    name,
                    OBJPROP_COLOR,
                    clr
                   );



   ObjectSetInteger(
                    0,
                    name,
                    OBJPROP_WIDTH,
                    PFP_DEFAULT_WIDTH
                   );



   ObjectSetInteger(
                    0,
                    name,
                    OBJPROP_RAY_RIGHT,
                    true
                   );



   ObjectSetInteger(
                    0,
                    name,
                    OBJPROP_SELECTABLE,
                    false
                   );



}







void Delete(string name)
{


   if(ObjectFind(0,name)>=0)
   {

      ObjectDelete(
                   0,
                   name
                  );

   }


}





};



#endif