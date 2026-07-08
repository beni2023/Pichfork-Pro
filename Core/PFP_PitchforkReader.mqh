#ifndef PFP_PITCHFORKREADER_MQH
#define PFP_PITCHFORKREADER_MQH


#include "PFP_Pitchfork.mqh"



class CPFP_PitchforkReader
{


public:



//--------------------------------------------------
// Find Pitchfork
//--------------------------------------------------

bool FindPitchfork(CPFP_Pitchfork &pitchfork)
{


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



      if(name=="")
         continue;




      ENUM_OBJECT type=
         (ENUM_OBJECT)
         ObjectGetInteger(
                          0,
                          name,
                          OBJPROP_TYPE
                         );




      if(type!=OBJ_PITCHFORK)
         continue;




      Print(
            "Reader : Pitchfork Found ",
            name
           );




      if(!ReadPoints(name,pitchfork))
      {

         Print("Reader : Point Read Failed");

         return(false);

      }





      pitchfork.SetID(
                      "PFP_STD_001"
                     );



      DetectType(
                 pitchfork
                );



      pitchfork.SetActive(true);





      if(!pitchfork.Validate())
      {

         Print("Reader : Validation Failed");

         pitchfork.Reset();

         return(false);

      }




      return(true);



   }





   Print("Reader : No Pitchfork");

   return(false);


}





//--------------------------------------------------
// Read Anchor Points
//--------------------------------------------------

bool ReadPoints(
                string name,
                CPFP_Pitchfork &pitchfork
               )
{


   datetime t0=
      (datetime)
      ObjectGetInteger(
                       0,
                       name,
                       OBJPROP_TIME,
                       0
                      );



   datetime t1=
      (datetime)
      ObjectGetInteger(
                       0,
                       name,
                       OBJPROP_TIME,
                       1
                      );



   datetime t2=
      (datetime)
      ObjectGetInteger(
                       0,
                       name,
                       OBJPROP_TIME,
                       2
                      );





   double p0=
      ObjectGetDouble(
                      0,
                      name,
                      OBJPROP_PRICE,
                      0
                     );



   double p1=
      ObjectGetDouble(
                      0,
                      name,
                      OBJPROP_PRICE,
                      1
                     );



   double p2=
      ObjectGetDouble(
                      0,
                      name,
                      OBJPROP_PRICE,
                      2
                     );





   if(t0<=0 ||
      t1<=0 ||
      t2<=0)
   {

      return(false);

   }





   if(p0<=0 ||
      p1<=0 ||
      p2<=0)
   {

      return(false);

   }





   if(t0==t1 ||
      t0==t2 ||
      t1==t2)
   {

      Print("Reader : Duplicate Time");

      return(false);

   }







   pitchfork.SetPointA(
                       t0,
                       p0
                      );



   pitchfork.SetPointB(
                       t1,
                       p1
                      );



   pitchfork.SetPointC(
                       t2,
                       p2
                      );





   Print("-----------------------");

   Print(
         "A ",
         TimeToString(t0),
         " ",
         DoubleToString(p0,_Digits)
        );


   Print(
         "B ",
         TimeToString(t1),
         " ",
         DoubleToString(p1,_Digits)
        );


   Print(
         "C ",
         TimeToString(t2),
         " ",
         DoubleToString(p2,_Digits)
        );


   Print("-----------------------");





   return(true);

}





//--------------------------------------------------
// Detect Type
//--------------------------------------------------

void DetectType(CPFP_Pitchfork &pitchfork)
{


   /*
      مرحله اول:
      پیش فرض Standard

      در نسخه بعد:
      الگوریتم تشخیص Schiff
      با زاویه و Offset اضافه خواهد شد.
   */


   pitchfork.SetType(
                     PFP_STANDARD
                    );



}




};



#endif