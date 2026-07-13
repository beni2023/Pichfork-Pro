#ifndef PFP_GEOMETRYENGINE_MQH
#define PFP_GEOMETRYENGINE_MQH


#include "PFP_Pitchfork.mqh"
#include "PFP_GeometryData.mqh"



class CPFP_GeometryEngine
{


public:



bool Build(
           CPFP_Pitchfork &pf,
           CPFP_GeometryData &geo
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

   geo.MedianTime1=
      pf.TimeA();


   geo.MedianPrice1=
      pf.PriceA();



   geo.MedianTime2=
      medianTime;


   geo.MedianPrice2=
      medianPrice;





   //--------------------------------------------------
   // Vector
   //--------------------------------------------------

   long dx=
      (long)geo.MedianTime2 -
      (long)geo.MedianTime1;



   double dy=
      geo.MedianPrice2 -
      geo.MedianPrice1;




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

   geo.UpperTime1=
      pf.TimeB();


   geo.UpperPrice1=
      pf.PriceB();



   geo.UpperTime2=
      (datetime)
      (
       (long)pf.TimeB()+dx
      );


   geo.UpperPrice2=
      pf.PriceB()+dy;






   //--------------------------------------------------
   // Lower Parallel
   //--------------------------------------------------

   geo.LowerTime1=
      pf.TimeC();


   geo.LowerPrice1=
      pf.PriceC();



   geo.LowerTime2=
      (datetime)
      (
       (long)pf.TimeC()+dx
      );


   geo.LowerPrice2=
      pf.PriceC()+dy;







   //--------------------------------------------------
   // Middle Lines
   //--------------------------------------------------

   geo.MidUpperTime1=
      (datetime)
      (
       ((long)geo.MedianTime1+
        (long)geo.UpperTime1)/2
      );


   geo.MidUpperPrice1=
      (
       geo.MedianPrice1+
       geo.UpperPrice1
      )
      /
      2.0;



   geo.MidUpperTime2=
      (datetime)
      (
       ((long)geo.MedianTime2+
        (long)geo.UpperTime2)/2
      );


   geo.MidUpperPrice2=
      (
       geo.MedianPrice2+
       geo.UpperPrice2
      )
      /
      2.0;





   geo.MidLowerTime1=
      (datetime)
      (
       ((long)geo.MedianTime1+
        (long)geo.LowerTime1)/2
      );


   geo.MidLowerPrice1=
      (
       geo.MedianPrice1+
       geo.LowerPrice1
      )
      /
      2.0;




   geo.MidLowerTime2=
      (datetime)
      (
       ((long)geo.MedianTime2+
        (long)geo.LowerTime2)/2
      );


   geo.MidLowerPrice2=
      (
       geo.MedianPrice2+
       geo.LowerPrice2
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