#ifndef PFP_MULTISTORAGE_MQH
#define PFP_MULTISTORAGE_MQH

#include "PFP_MultiManager.mqh"

#define PFP_MULTI_STORAGE_FILE "PFP_MultiData.bin"

class CPFP_MultiStorage
{
public:

//--------------------------------------------------
bool Save(CPFP_MultiManager &manager)
{
   int file=FileOpen(PFP_MULTI_STORAGE_FILE,FILE_WRITE|FILE_BIN);

   if(file==INVALID_HANDLE)
      return(false);

   FileWriteInteger(file,manager.Count(),INT_VALUE);

   for(int i=0;i<manager.Count();i++)
   {
      CPFP_Pitchfork pf;

      if(!manager.Get(i,pf))
         continue;

      FileWriteString(file,pf.ID());

      FileWriteInteger(file,(int)pf.Type(),INT_VALUE);
      FileWriteInteger(file,(int)pf.Direction(),INT_VALUE);
      FileWriteInteger(file,pf.Active(),INT_VALUE);

      FileWriteLong(file,(long)pf.TimeA());
      FileWriteDouble(file,pf.PriceA());

      FileWriteLong(file,(long)pf.TimeB());
      FileWriteDouble(file,pf.PriceB());

      FileWriteLong(file,(long)pf.TimeC());
      FileWriteDouble(file,pf.PriceC());
   }

   FileClose(file);

   return(true);
}

//--------------------------------------------------
bool Load(CPFP_MultiManager &manager)
{
   int file=FileOpen(PFP_MULTI_STORAGE_FILE,FILE_READ|FILE_BIN);

   if(file==INVALID_HANDLE)
      return(false);

   manager.Clear();

   int total=FileReadInteger(file,INT_VALUE);

   for(int i=0;i<total;i++)
   {
      CPFP_Pitchfork pf;

      pf.SetID(FileReadString(file));

      pf.SetType((ENUM_PFP_TYPE)FileReadInteger(file,INT_VALUE));

      pf.SetDirection((ENUM_PFP_DIRECTION)FileReadInteger(file,INT_VALUE));

      pf.SetActive((bool)FileReadInteger(file,INT_VALUE));

      datetime ta=(datetime)FileReadLong(file);
      double pa=FileReadDouble(file);

      datetime tb=(datetime)FileReadLong(file);
      double pb=FileReadDouble(file);

      datetime tc=(datetime)FileReadLong(file);
      double pc=FileReadDouble(file);

      pf.SetPointA(ta,pa);
      pf.SetPointB(tb,pb);
      pf.SetPointC(tc,pc);

      if(pf.Validate())
         manager.Add(pf);
   }

   FileClose(file);

   return(true);
}

};

#endif