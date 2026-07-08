#ifndef PFP_OBJECTMANAGER_MQH
#define PFP_OBJECTMANAGER_MQH


#include "../Utils/PFP_Constants.mqh"





class CPFP_ObjectManager
{


public:




//==================================================
// Init
//==================================================

void Init()
{


   Print("ObjectManager Initialized");


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


            Print(
                  "Original Pitchfork Deleted : ",
                  name
                 );


            return(true);

         }



      }



   }




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