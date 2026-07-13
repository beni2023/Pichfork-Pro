#ifndef PFP_STORAGE_MQH
#define PFP_STORAGE_MQH


#include "PFP_Pitchfork.mqh"



class CPFP_Storage
{


public:



//--------------------------------------------------
// Save
//--------------------------------------------------

bool Save(CPFP_Pitchfork &pf)
{


   if(!pf.Validate())
   {

      Print("Storage : Invalid Pitchfork");

      return(false);

   }





   int file=
      FileOpen(
               PFP_STORAGE_FILE,
               FILE_WRITE|FILE_BIN
              );



   if(file==INVALID_HANDLE)
   {

      Print("Storage : Open Failed");

      return(false);

   }





   //----------------------------------
   // ID
   //----------------------------------

   FileWriteString(
                   file,
                   pf.ID()
                  );





   //----------------------------------
   // Type
   //----------------------------------

   FileWriteInteger(
                    file,
                    (int)pf.Type(),
                    INT_VALUE
                   );





   //----------------------------------
   // Direction
   //----------------------------------

   FileWriteInteger(
                    file,
                    (int)pf.Direction(),
                    INT_VALUE
                   );





   //----------------------------------
   // Active
   //----------------------------------

   FileWriteInteger(
                    file,
                    pf.Active(),
                    INT_VALUE
                   );






   //----------------------------------
   // Point A
   //----------------------------------

   FileWriteLong(
                 file,
                 (long)pf.TimeA()
                );


   FileWriteDouble(
                   file,
                   pf.PriceA()
                  );






   //----------------------------------
   // Point B
   //----------------------------------

   FileWriteLong(
                 file,
                 (long)pf.TimeB()
                );


   FileWriteDouble(
                   file,
                   pf.PriceB()
                  );







   //----------------------------------
   // Point C
   //----------------------------------

   FileWriteLong(
                 file,
                 (long)pf.TimeC()
                );


   FileWriteDouble(
                   file,
                   pf.PriceC()
                  );






   FileClose(file);



   Print(
         "Storage : Saved ",
         pf.ID()
        );



   return(true);

}







//--------------------------------------------------
// Load
//--------------------------------------------------

bool Load(CPFP_Pitchfork &pf)
{


   int file=
      FileOpen(
               PFP_STORAGE_FILE,
               FILE_READ|FILE_BIN
              );



   if(file==INVALID_HANDLE)
   {

      Print("Storage : No File");

      return(false);

   }






   pf.Reset();






   //----------------------------------
   // ID
   //----------------------------------

   string id=
      FileReadString(file);



   pf.SetID(id);







   //----------------------------------
   // Type
   //----------------------------------

   ENUM_PFP_TYPE type=
      (ENUM_PFP_TYPE)
      FileReadInteger(
                      file,
                      INT_VALUE
                     );



   pf.SetType(type);






   //----------------------------------
   // Direction
   //----------------------------------

   ENUM_PFP_DIRECTION dir=
      (ENUM_PFP_DIRECTION)
      FileReadInteger(
                      file,
                      INT_VALUE
                     );


   pf.SetDirection(dir);






   //----------------------------------
   // Active
   //----------------------------------

   bool active=
      (bool)
      FileReadInteger(
                      file,
                      INT_VALUE
                     );


   //----------------------------------
   // Points
   //----------------------------------

   datetime ta=
      (datetime)
      FileReadLong(file);


   double pa=
      FileReadDouble(file);


   datetime tb=
      (datetime)
      FileReadLong(file);


   double pb=
      FileReadDouble(file);


   datetime tc=
      (datetime)
      FileReadLong(file);


   double pc=
      FileReadDouble(file);


   FileClose(file);


   pf.SetPointA(
                ta,
                pa
               );


   pf.SetPointB(
                tb,
                pb
               );


   pf.SetPointC(
                tc,
                pc
               );



   pf.SetActive(active);






   if(!pf.Validate())
   {

      Print("Storage : Loaded Data Invalid");

      pf.Reset();

      return(false);

   }





   Print(
         "Storage : Loaded ",
         pf.ID()
        );



   return(true);


}



};



#endif