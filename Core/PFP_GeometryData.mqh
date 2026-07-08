#ifndef PFP_GEOMETRYDATA_MQH
#define PFP_GEOMETRYDATA_MQH



class CPFP_GeometryData
{


public:



   //----------------------------------
   // Median Line
   //----------------------------------

   datetime MedianTime1;
   datetime MedianTime2;

   double MedianPrice1;
   double MedianPrice2;





   //----------------------------------
   // Upper Parallel
   //----------------------------------

   datetime UpperTime1;
   datetime UpperTime2;

   double UpperPrice1;
   double UpperPrice2;





   //----------------------------------
   // Lower Parallel
   //----------------------------------

   datetime LowerTime1;
   datetime LowerTime2;

   double LowerPrice1;
   double LowerPrice2;





   //----------------------------------
   // Mid Upper
   //----------------------------------

   datetime MidUpperTime1;
   datetime MidUpperTime2;

   double MidUpperPrice1;
   double MidUpperPrice2;





   //----------------------------------
   // Mid Lower
   //----------------------------------

   datetime MidLowerTime1;
   datetime MidLowerTime2;

   double MidLowerPrice1;
   double MidLowerPrice2;






//==================================================
// Constructor
//==================================================

CPFP_GeometryData()
{

   Reset();

}






//==================================================
// Reset
//==================================================

void Reset()
{


   MedianTime1=0;
   MedianTime2=0;


   MedianPrice1=0;
   MedianPrice2=0;





   UpperTime1=0;
   UpperTime2=0;


   UpperPrice1=0;
   UpperPrice2=0;






   LowerTime1=0;
   LowerTime2=0;


   LowerPrice1=0;
   LowerPrice2=0;







   MidUpperTime1=0;
   MidUpperTime2=0;


   MidUpperPrice1=0;
   MidUpperPrice2=0;







   MidLowerTime1=0;
   MidLowerTime2=0;


   MidLowerPrice1=0;
   MidLowerPrice2=0;



}






//==================================================
// Validation
//==================================================

bool Valid()
{


   if(MedianTime1<=0 ||
      MedianTime2<=0)
      return(false);




   if(UpperTime1<=0 ||
      UpperTime2<=0)
      return(false);




   if(LowerTime1<=0 ||
      LowerTime2<=0)
      return(false);




   return(true);

}




};



#endif