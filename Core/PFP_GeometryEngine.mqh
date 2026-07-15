#ifndef PFP_GEOMETRYENGINE_MQH
#define PFP_GEOMETRYENGINE_MQH


#include "PFP_Pitchfork.mqh"
#include "PFP_GeometryData.mqh"



class CPFP_GeometryEngine
{


public:



bool Build(
           CPFP_Pitchfork &pf,
           S_PFP_Geometry &geo
          )
{


   if(!pf.Validate())
   {

      Print("Geometry : Invalid Pitchfork");

      return(false);

   }



   geo.Reset();



   datetime medianTime;
   double medianPrice;



   //--------------------------------------------------
   // Select Geometry Mode
   //--------------------------------------------------

   switch(pf.Type())
   {


      //================================================
      // STANDARD PITCHFORK
      //================================================

      case PFP_STANDARD:
      {

         medianTime=
            (datetime)
            (
             (long)pf.TimeB()
             +
             ((long)pf.TimeC()-
              (long)pf.TimeB())/2
            );


         medianPrice=
            (
             pf.PriceB()+
             pf.PriceC()
            )
            /
            2.0;


         break;

      }





      //================================================
      // SCHIFF
      //================================================

      case PFP_SCHIFF:
      {


         medianTime=pf.TimeA();


         medianPrice=
            (
             pf.PriceA()
             +
             (
              (
               pf.PriceB()
               +
               pf.PriceC()
              )
              /
              2.0
             )
            )
            /
            2.0;



         break;

      }





      //================================================
      // MODIFIED SCHIFF
      //================================================

      case PFP_MODIFIED_SCHIFF:
      {


         medianTime=
            (datetime)
            (
             (
              (long)pf.TimeA()
              +
              (long)pf.TimeB()
             )
             /
             2
            );



         medianPrice=
            (
             (
              pf.PriceA()
              +
              pf.PriceB()
             )
             /
             2.0
             +
             pf.PriceC()
            )
            /
            2.0;



         break;

      }



      default:
      {


         Print("Geometry : Unknown Type");

         return(false);

      }



   }





   //--------------------------------------------------
   // Median Line
   //--------------------------------------------------

   geo.MedianTimeStart = pf.TimeA();
   geo.MedianPriceStart = pf.PriceA();
   geo.MedianTimeEnd = medianTime;
   geo.MedianPriceEnd = medianPrice;


   //--------------------------------------------------
   // Vector
   //--------------------------------------------------

   long dx = (long)geo.MedianTimeEnd - (long)geo.MedianTimeStart;
   double dy = geo.MedianPriceEnd - geo.MedianPriceStart;




   if(dx==0)
   {
      Print("Geometry : Zero Time Vector");
      return(false);
   }
   
   if(dx==0 && dy==0)
   {
      Print("Geometry : Zero Vector");
      return(false);
   }






   //--------------------------------------------------
   // Upper Parallel
   //--------------------------------------------------

   geo.UpperTimeStart=
      pf.TimeB();


   geo.UpperPriceStart=
      pf.PriceB();



   geo.UpperTimeEnd=
      (datetime)
      (
       (long)pf.TimeB()+dx
      );


   geo.UpperPriceEnd=
      pf.PriceB()+dy;






   //--------------------------------------------------
   // Lower Parallel
   //--------------------------------------------------

   geo.LowerTimeStart=
      pf.TimeC();


   geo.LowerPriceStart=
      pf.PriceC();



   geo.LowerTimeEnd=
      (datetime)
      (
       (long)pf.TimeC()+dx
      );


   geo.LowerPriceEnd=
      pf.PriceC()+dy;







   //--------------------------------------------------
   // Middle Lines
   //--------------------------------------------------

   geo.MidUpperTimeStart=
      (datetime)
      (
       ((long)geo.MedianTimeStart+
        (long)geo.UpperTimeStart)/2
      );


   geo.MidUpperPriceStart=
      (
       geo.MedianPriceStart+
       geo.UpperPriceStart
      )
      /
      2.0;



   geo.MidUpperTimeEnd=
      (datetime)
      (
       ((long)geo.MedianTimeEnd+
        (long)geo.UpperTimeEnd)/2
      );


   geo.MidUpperPriceEnd=
      (
       geo.MedianPriceEnd+
       geo.UpperPriceEnd
      )
      /
      2.0;





   geo.MidLowerTimeStart=
      (datetime)
      (
       ((long)geo.MedianTimeStart+
        (long)geo.LowerTimeStart)/2
      );


   geo.MidLowerPriceStart=
      (
       geo.MedianPriceStart+
       geo.LowerPriceStart
      )
      /
      2.0;




   geo.MidLowerTimeEnd=
      (datetime)
      (
       ((long)geo.MedianTimeEnd+
        (long)geo.LowerTimeEnd)/2
      );


   geo.MidLowerPriceEnd=
      (
       geo.MedianPriceEnd+
       geo.LowerPriceEnd
      )
      /
      2.0;




   Print(
         "Geometry : Build OK Type=",
         EnumToString(pf.Type())
        );



   return(true);

}



};



#endif