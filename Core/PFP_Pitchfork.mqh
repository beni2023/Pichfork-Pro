#ifndef PFP_PITCHFORK_MQH
#define PFP_PITCHFORK_MQH


#include "../Utils/PFP_Constants.mqh"





class CPFP_Pitchfork
{


private:


   string m_id;



   datetime m_timeA;
   datetime m_timeB;
   datetime m_timeC;



   double m_priceA;
   double m_priceB;
   double m_priceC;



   ENUM_PFP_TYPE m_type;


   ENUM_PFP_DIRECTION m_direction;



   bool m_active;



   color m_color;





public:




//--------------------------------------------------
// Constructor
//--------------------------------------------------

CPFP_Pitchfork()
{

   Reset();

}





//--------------------------------------------------
// Reset
//--------------------------------------------------

void Reset()
{


   m_id="";



   m_timeA=0;
   m_timeB=0;
   m_timeC=0;



   m_priceA=0;
   m_priceB=0;
   m_priceC=0;



   m_type=PFP_STANDARD;



   m_direction=PFP_NEUTRAL;



   m_active=false;



   m_color=PFP_COLOR_NEUTRAL;



}







//--------------------------------------------------
// ID
//--------------------------------------------------

void SetID(string id)
{

   m_id=id;

}



string ID()
{

   return m_id;

}







//--------------------------------------------------
// Points
//--------------------------------------------------

void SetPointA(datetime t,double p)
{

   m_timeA=t;

   m_priceA=p;

}



void SetPointB(datetime t,double p)
{

   m_timeB=t;

   m_priceB=p;

}



void SetPointC(datetime t,double p)
{

   m_timeC=t;

   m_priceC=p;

}







datetime TimeA()
{

   return m_timeA;

}


datetime TimeB()
{

   return m_timeB;

}


datetime TimeC()
{

   return m_timeC;

}







double PriceA()
{

   return m_priceA;

}


double PriceB()
{

   return m_priceB;

}


double PriceC()
{

   return m_priceC;

}







//--------------------------------------------------
// Type
//--------------------------------------------------

void SetType(ENUM_PFP_TYPE type)
{

   m_type=type;

}



ENUM_PFP_TYPE Type()
{

   return m_type;

}







//--------------------------------------------------
// Direction
//--------------------------------------------------

void SetDirection(ENUM_PFP_DIRECTION dir)
{


   m_direction=dir;



   switch(dir)
   {


      case PFP_BULLISH:

         m_color=PFP_COLOR_BULL;

         break;



      case PFP_BEARISH:

         m_color=PFP_COLOR_BEAR;

         break;



      default:

         m_color=PFP_COLOR_NEUTRAL;

         break;


   }



}






ENUM_PFP_DIRECTION Direction()
{

   return m_direction;

}







//--------------------------------------------------
// Active
//--------------------------------------------------

void SetActive(bool value)
{

   m_active=value;

}



bool Active()
{

   return m_active;

}







//--------------------------------------------------
// Color
//--------------------------------------------------

color GetColor()
{

   return m_color;

}








//--------------------------------------------------
// Validation
//--------------------------------------------------

bool Validate()
{


   if(m_id=="")
      return(false);




   if(m_timeA<=0 ||
      m_timeB<=0 ||
      m_timeC<=0)
      return(false);




   if(m_priceA<=0 ||
      m_priceB<=0 ||
      m_priceC<=0)
      return(false);





   if(m_timeA==m_timeB ||
      m_timeA==m_timeC ||
      m_timeB==m_timeC)
      return(false);





   if(m_type<PFP_STANDARD ||
      m_type>PFP_MODIFIED_SCHIFF)
      return(false);




   return(true);

}





};



#endif