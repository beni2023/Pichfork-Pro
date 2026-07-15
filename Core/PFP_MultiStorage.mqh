#ifndef PFP_MULTISTORAGE_MQH
#define PFP_MULTISTORAGE_MQH

#include "PFP_MultiManager.mqh"

#define PFP_MULTI_STORAGE_FILE "PFP_MultiData.bin"

//+------------------------------------------------------------------+
//| Multi Storage with Error Handling                                |
//+------------------------------------------------------------------+
class CPFP_MultiStorage
{
private:
   
   // Get full file path
   string GetFilePath()
   {
      return TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\" + PFP_MULTI_STORAGE_FILE;
   }
   
public:

//--------------------------------------------------
bool Save(CPFP_MultiManager &manager)
{
   if(manager.Count() == 0)
   {
      Print("MultiStorage : Nothing to save");
      return true;
   }

   int file = FileOpen(PFP_MULTI_STORAGE_FILE, FILE_WRITE | FILE_BIN);

   if(file == INVALID_HANDLE)
   {
      Print("MultiStorage : File open failed, error = ", GetLastError());
      return false;
   }

   // Write version for future compatibility
   FileWriteInteger(file, 1, INT_VALUE); // Version 1
   
   int count = manager.Count();
   FileWriteInteger(file, count, INT_VALUE);

   int saved = 0;
   for(int i = 0; i < count; i++)
   {
      CPFP_Pitchfork pf;

      if(!manager.Get(i, pf))
         continue;
      
      if(!pf.Validate())
         continue;

      FileWriteString(file, pf.ID());
      FileWriteInteger(file, (int)pf.Type(), INT_VALUE);
      FileWriteInteger(file, (int)pf.Direction(), INT_VALUE);
      FileWriteInteger(file, pf.Active(), INT_VALUE);
      FileWriteLong(file, (long)pf.TimeA());
      FileWriteDouble(file, pf.PriceA());
      FileWriteLong(file, (long)pf.TimeB());
      FileWriteDouble(file, pf.PriceB());
      FileWriteLong(file, (long)pf.TimeC());
      FileWriteDouble(file, pf.PriceC());
      
      saved++;
   }

   FileClose(file);

   Print("MultiStorage : Saved ", saved, " pitchforks");
   return true;
}

//--------------------------------------------------
bool Load(CPFP_MultiManager &manager)
{
   int file = FileOpen(PFP_MULTI_STORAGE_FILE, FILE_READ | FILE_BIN);

   if(file == INVALID_HANDLE)
   {
      Print("MultiStorage : No saved data found");
      return false;
   }

   manager.Clear();

   // Read and verify version
   int version = FileReadInteger(file, INT_VALUE);
   if(version != 1)
   {
      Print("MultiStorage : Unsupported version ", version);
      FileClose(file);
      return false;
   }

   int total = FileReadInteger(file, INT_VALUE);
   
   if(total <= 0 || total > PFP_MAX_PITCHFORKS)
   {
      Print("MultiStorage : Invalid count ", total);
      FileClose(file);
      return false;
   }

   int loaded = 0;
   for(int i = 0; i < total; i++)
   {
      CPFP_Pitchfork pf;

      string id = FileReadString(file);
      if(id == "")
         continue;
         
      pf.SetID(id);

      ENUM_PFP_TYPE type = (ENUM_PFP_TYPE)FileReadInteger(file, INT_VALUE);
      pf.SetType(type);

      ENUM_PFP_DIRECTION dir = (ENUM_PFP_DIRECTION)FileReadInteger(file, INT_VALUE);
      pf.SetDirection(dir);

      bool active = (bool)FileReadInteger(file, INT_VALUE);
      pf.SetActive(active);

      datetime ta = (datetime)FileReadLong(file);
      double pa = FileReadDouble(file);

      datetime tb = (datetime)FileReadLong(file);
      double pb = FileReadDouble(file);

      datetime tc = (datetime)FileReadLong(file);
      double pc = FileReadDouble(file);

      pf.SetPointA(ta, pa);
      pf.SetPointB(tb, pb);
      pf.SetPointC(tc, pc);

      if(pf.Validate())
      {
         manager.Add(pf);
         loaded++;
      }
   }

   FileClose(file);

   Print("MultiStorage : Loaded ", loaded, " pitchforks");
   return (loaded > 0);
}

//--------------------------------------------------
// Clear all stored data
//--------------------------------------------------
void ClearAll()
{
   string filePath = GetFilePath();
   
   // Delete the file if it exists
   if(FileOpen(PFP_MULTI_STORAGE_FILE, FILE_READ | FILE_BIN) != INVALID_HANDLE || FileIsExist(PFP_MULTI_STORAGE_FILE))
   {
      if(FileDelete(PFP_MULTI_STORAGE_FILE))
      {
         Print("MultiStorage : Cleared all data");
      }
      else
      {
         Print("MultiStorage : Failed to delete file, error = ", GetLastError());
      }
   }
   else
   {
      Print("MultiStorage : No data file to clear");
   }
}

};

#endif