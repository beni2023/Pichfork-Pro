#ifndef PFP_MANAGER_MQH
#define PFP_MANAGER_MQH


#include "PFP_Pitchfork.mqh"



class CPFP_Manager
{


private:


   CPFP_Pitchfork m_active;

   bool m_exists;



public:



//--------------------------------------------------
// Constructor
//--------------------------------------------------

CPFP_Manager()
{

   m_exists=false;

   m_active.Reset();

}




//--------------------------------------------------
// Set Pitchfork
//--------------------------------------------------

bool Set(CPFP_Pitchfork &pf)
{


   if(!pf.Validate())
   {

      Print("Manager : Invalid Pitchfork");

      return(false);

   }



   m_active=pf;


   m_exists=true;



   return(true);

}





//--------------------------------------------------
// Get Pitchfork
//--------------------------------------------------

bool Get(CPFP_Pitchfork &pf)
{


   if(!m_exists)
   {

      return(false);

   }



   pf=m_active;



   return(true);

}





//--------------------------------------------------
// Clear
//--------------------------------------------------

void Clear()
{


   m_active.Reset();


   m_exists=false;


}







//--------------------------------------------------
// Exists
//--------------------------------------------------

bool Exists()
{

   return(m_exists);

}





//--------------------------------------------------
// Update
//--------------------------------------------------

bool Update(CPFP_Pitchfork &pf)
{


   if(!pf.Validate())
   {

      return(false);

   }



   m_active=pf;


   m_exists=true;



   return(true);

}





//--------------------------------------------------
// Get ID
//--------------------------------------------------

string ID()
{

   if(!m_exists)
      return "";



   return m_active.ID();

}





//--------------------------------------------------
// Direction
//--------------------------------------------------

ENUM_PFP_DIRECTION Direction()
{

   return m_active.Direction();

}





//--------------------------------------------------
// Type
//--------------------------------------------------

ENUM_PFP_TYPE Type()
{

   return m_active.Type();

}





};



#endif